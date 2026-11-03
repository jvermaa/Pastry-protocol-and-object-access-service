%% One Pastry peer. Each peer is one actor.
-module(pastry_node).

-export([start/4, route/3]).

-record(st, {id, ls, rt, app, app_state, stats}).

%% App is a module with the pastry_app behavior.
%% Stats is the actor that gets the hop count of each delivered message.
start(Index, App, AppState, Stats) ->
    spawn(fun() ->
        Id = pastry_id:new(Index),
        loop(#st{id = Id, ls = pastry_leafset:new(Id), rt = pastry_rtable:new(Id),
                 app = App, app_state = AppState, stats = Stats})
    end).

%% route(msg, key) from section 2.3.
route(Pid, Msg, Key) ->
    Pid ! {route, Msg, Key, 0}.

loop(S) ->
    receive
        {route, Msg, Key, Hops} -> loop(do_route(Msg, Key, Hops, S))
    end.

do_route(Msg, Key, Hops, #st{app = App, app_state = AS} = S) ->
    case pastry_route:next_hop(Key, S#st.id, S#st.ls, S#st.rt) of
        deliver ->
            S#st.stats ! {hops, Hops},
            S#st{app_state = App:deliver(Msg, Key, AS)};
        {forward, {NextId, NextPid}} ->
            %% The app can change Msg or stop it. It cannot select a different node.
            case App:forward(Msg, Key, NextId, AS) of
                {_, null, AS2} ->
                    S#st{app_state = AS2};
                {Msg2, _, AS2} ->
                    NextPid ! {route, Msg2, Key, Hops + 1},
                    S#st{app_state = AS2}
            end
    end.
