%% The object access service: each key has one string.

-module(kv_app).

-behaviour(pastry_app).

-export([new/0, put/4, get/3]).
-export([deliver/3, forward/4, new_leafs/2, handle/2]).

-include("pastry.hrl").

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

%% Each peer sends one request each ?INTERVAL_MS.
%% Odd requests put a string with a new random key.
%% Even requests get the key of the previous put.
handle({start_requests, N}, S) ->
    erlang:send_after(?INTERVAL_MS, self(), tick),
    S#{left => N, count => 0};
handle(tick, #{left := Left, count := Count} = S) ->
    K = Count + 1,
    case Left > 1 of
        true -> erlang:send_after(?INTERVAL_MS, self(), tick);
        false -> ok
    end,
    S2 = S#{left := Left - 1, count := K},
    case K rem 2 of
        1 ->
            Key = rand:uniform(1 bsl ?ID_BITS) - 1,
            Value = lists:flatten(io_lib:format("request ~p from ~p", [K, self()])),
            put(self(), Key, Value, self()),
            S2#{last_key => Key};
        0 ->
            get(self(), maps:get(last_key, S), self()),
            S2
    end;
handle({put_ok, _Key}, S) ->
    S;
handle({get_result, _Key, _Result}, S) ->
    S.
