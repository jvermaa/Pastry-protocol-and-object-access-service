%% Collects the hop count of each delivered message.
%% After Total messages, it sends {done, Total, AverageHops} to Parent.
-module(stats).

-export([start/2]).

start(Total, Parent) ->
    spawn(fun() -> loop(Total, 0, 0, Parent) end).

loop(Total, Total, Sum, Parent) ->
    Parent ! {done, Total, Sum / max(Total, 1)};
loop(Total, Count, Sum, Parent) ->
    receive
        {hops, Hops} -> loop(Total, Count + 1, Sum + Hops, Parent)
    end.
