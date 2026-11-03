%% Calculations on node IDs and keys.

-module(pastry_id).

-include("pastry.hrl").

-export([new/1, digit/2, shl/2, dist/2]).

-define(NUM_DIGITS, (?ID_BITS div ?B)).
-define(RING, (1 bsl ?ID_BITS)).

%% The md5 hash gives IDs with a uniform distribution, as the paper tells.
new(Index) ->
    <<Id:?ID_BITS, _/bitstring>> = crypto:hash(md5, integer_to_binary(Index)),
    Id.

%% The digit of Id at position Row.
digit(Id, Row) ->
    (Id bsr (?ID_BITS - (Row + 1) * ?B)) band ((1 bsl ?B) - 1).

%% shl(A, B): the length of the prefix that A and B share, in digits.
shl(A, B) ->
    shl(A, B, 0).

shl(_A, _B, ?NUM_DIGITS) ->
    ?NUM_DIGITS;
shl(A, B, Row) ->
    case digit(A, Row) =:= digit(B, Row) of
        true -> shl(A, B, Row + 1);
        false -> Row
    end.

%% The distance between A and B on the ID ring.
dist(A, B) ->
    D = abs(A - B),
    min(D, ?RING - D).
