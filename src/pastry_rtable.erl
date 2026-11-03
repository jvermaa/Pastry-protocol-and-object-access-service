%% The routing table R. Row l holds nodes that share l digits with Self.
%% The column is the next digit of the node ID.
-module(pastry_rtable).

-export([new/1, add/2, lookup/2, rows/2, members/1]).

new(Self) ->
    {Self, #{}}.

%% If the cell already has a node, keep that node.
add({Self, _}, {Self, _} = RT) ->
    RT;
add({Id, _} = Entry, {Self, Map}) ->
    Row = pastry_id:shl(Self, Id),
    Cell = {Row, pastry_id:digit(Id, Row)},
    {Self, maps:merge(#{Cell => Entry}, Map)}.

%% Table 1, line 7: the entry R[l][D_l] for Key, or none.
lookup(Key, {Self, Map}) ->
    Row = pastry_id:shl(Self, Key),
    maps:get({Row, pastry_id:digit(Key, Row)}, Map, none).

%% The nodes in rows 0 to MaxRow. The join procedure sends these rows.
rows(MaxRow, {_Self, Map}) ->
    [E || {{Row, _Col}, E} <- maps:to_list(Map), Row =< MaxRow].

members({_Self, Map}) ->
    maps:values(Map).
