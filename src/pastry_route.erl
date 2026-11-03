%% Table 1 of the paper: select the next node for a message with key Key.
-module(pastry_route).

-export([next_hop/4]).

%% Gives deliver, or {forward, {Id, Pid}}.
next_hop(Key, Self, LS, RT) ->
    case pastry_leafset:in_range(Key, LS) of
        true ->
            case pastry_leafset:closest(Key, LS) of     % lines 1-3
                self -> deliver;
                Entry -> {forward, Entry}
            end;
        false ->
            case pastry_rtable:lookup(Key, RT) of       % lines 6-8
                none -> rare_case(Key, Self, LS, RT);
                Entry -> {forward, Entry}
            end
    end.

%% Lines 11-14: select the node T that is nearest to Key,
%% with shl(T, Key) >= shl(Key, Self) and T nearer to Key than Self.
rare_case(Key, Self, LS, RT) ->
    L = pastry_id:shl(Key, Self),
    D = pastry_id:dist(Key, Self),
    Better = [{pastry_id:dist(Key, Id), E}
              || {Id, _} = E <- pastry_leafset:members(LS) ++ pastry_rtable:members(RT),
                 pastry_id:shl(Id, Key) >= L,
                 pastry_id:dist(Id, Key) < D],
    case Better of
        [] -> deliver;
        _ -> {forward, element(2, lists:min(Better))}
    end.
