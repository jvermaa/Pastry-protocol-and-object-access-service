%% The object access service: each key has one string.

-module(kv_app).

-behaviour(pastry_app).

-export([new/0, put/4, get/3]).
-export([deliver/3, forward/4, new_leafs/2]).

%% The initial app state of a node.
new() ->
    #{store => #{}}.

put(Node, Key, Value, ReplyTo) ->
    pastry_node:route(Node, {put, Value, ReplyTo}, Key).

get(Node, Key, ReplyTo) ->
    pastry_node:route(Node, {get, ReplyTo}, Key).

deliver({put, Value, ReplyTo}, Key, #{store := Store} = S) ->
    ReplyTo ! {put_ok, Key},
    S#{store := Store#{Key => Value}};
deliver({get, ReplyTo}, Key, #{store := Store} = S) ->
    ReplyTo ! {get_result, Key, maps:find(Key, Store)},
    S.

forward(Msg, _Key, NextId, S) ->
    {Msg, NextId, S}.

new_leafs(_LeafSet, S) ->
    S.
