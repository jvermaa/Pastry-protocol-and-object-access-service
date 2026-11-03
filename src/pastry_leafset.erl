%% The leaf set L: the |L|/2 nearest nodes with smaller IDs and
%% the |L|/2 nearest nodes with larger IDs, on the ID ring.
-module(pastry_leafset).

-include("pastry.hrl").

-export([new/1, add/2, members/1, in_range/2, closest/2]).

-define(HALF, (?LEAF_SIZE div 2)).
-define(RING, (1 bsl ?ID_BITS)).

%% {Self, Smaller, Larger}. Smaller and Larger hold {Id, Pid}, nearest first.
new(Self) ->
    {Self, [], []}.

add({Self, _}, {Self, _, _} = LS) ->
    {false, LS};
add({Id, _} = Entry, {Self, Smaller, Larger} = LS) ->
    case lists:keymember(Id, 1, Smaller ++ Larger) of
        true ->
            {false, LS};
        false ->
            case cw(Self, Id) < ?RING div 2 of
                true ->
                    New = insert(Entry, Larger, fun(X) -> cw(Self, X) end),
                    {lists:keymember(Id, 1, New), {Self, Smaller, New}};
                false ->
                    New = insert(Entry, Smaller, fun(X) -> cw(X, Self) end),
                    {lists:keymember(Id, 1, New), {Self, New, Larger}}
            end
    end.

members({_Self, Smaller, Larger}) ->
    Smaller ++ Larger.


in_range(Key, {Self, Smaller, Larger}) ->
    cw(Self, Key) =< limit(Larger, fun(X) -> cw(Self, X) end)
        orelse cw(Key, Self) =< limit(Smaller, fun(X) -> cw(X, Self) end).


closest(Key, {Self, _, _} = LS) ->
    Candidates = [{pastry_id:dist(Key, Self), self}
                  | [{pastry_id:dist(Key, Id), E} || {Id, _} = E <- members(LS)]],
    {_, Best} = lists:min(Candidates),
    Best.

cw(A, B) ->
    (B - A + ?RING) rem ?RING.

insert({Id, _} = Entry, List, Dist) ->
    Sorted = lists:sort([{Dist(Id), Entry} | [{Dist(I), E} || {I, _} = E <- List]]),
    lists:sublist([E || {_, E} <- Sorted], ?HALF).

limit(List, _Dist) when length(List) < ?HALF ->
    ?RING div 2;
limit(List, Dist) ->
    {Id, _} = lists:last(List),
    Dist(Id).
