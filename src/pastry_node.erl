%% One Pastry peer. Each peer is one actor.
-module(pastry_node).

-export([start/4, join/2, route/3]).

-record(st, {id, ls, rt, app, app_state, stats}).

%% App is a module with the pastry_app behavior.
%% Stats is the actor that gets the hop count of each delivered message.
start(Index, App, AppState, Stats) ->
    spawn(fun() ->
        Id = pastry_id:new(Index),
        loop(#st{id = Id, ls = pastry_leafset:new(Id), rt = pastry_rtable:new(Id),
                 app = App, app_state = AppState, stats = Stats})
    end).

join(Pid, Bootstrap) ->
    Pid ! {join_network, Bootstrap, self()},
    receive {joined, Pid, Id} -> Id end.

%% route(msg, key) from section 2.3.
route(Pid, Msg, Key) ->
    Pid ! {route, Msg, Key, 0}.

loop(S) ->
    receive
        {route, Msg, Key, Hops} ->
            loop(do_route(Msg, Key, Hops, S));
        {join_network, Bootstrap, Caller} ->
            S2 = do_join(Bootstrap, S),
            Caller ! {joined, self(), S2#st.id},
            loop(S2);
        {join, X, Entries} ->
            route_join(X, Entries, S),
            loop(S);
        {announce, {_, XPid} = X} ->
            XPid ! announce_ack,
            loop(add_node(X, S));
        AppMsg ->
            loop(S#st{app_state = (S#st.app):handle(AppMsg, S#st.app_state)})
    end.


do_join(none, S) ->
    S;
do_join(Bootstrap, #st{id = Id} = S) ->
    Bootstrap ! {join, {Id, self()}, []},
    Entries = receive {join_reply, E} -> E end,
    S2 = lists:foldl(fun add_node/2, S, Entries),
    Known = lists:usort(pastry_leafset:members(S2#st.ls) ++ pastry_rtable:members(S2#st.rt)),
    [Pid ! {announce, {Id, self()}} || {_, Pid} <- Known],
    [receive announce_ack -> ok end || _ <- Known],
    S2.

route_join({XId, XPid} = X, Entries, #st{id = Id} = S) ->
    Mine = [{Id, self()} | pastry_rtable:rows(pastry_id:shl(Id, XId), S#st.rt)] ++ Entries,
    case pastry_route:next_hop(XId, Id, S#st.ls, S#st.rt) of
        deliver -> XPid ! {join_reply, pastry_leafset:members(S#st.ls) ++ Mine};
        {forward, {_, Next}} -> Next ! {join, X, Mine}
    end.

add_node(Entry, #st{app = App} = S) ->
    RT = pastry_rtable:add(Entry, S#st.rt),
    case pastry_leafset:add(Entry, S#st.ls) of
        {true, LS} ->
            AS = App:new_leafs(pastry_leafset:members(LS), S#st.app_state),
            S#st{ls = LS, rt = RT, app_state = AS};
        {false, _} ->
            S#st{rt = RT}
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
