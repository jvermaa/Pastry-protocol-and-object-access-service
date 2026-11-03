%% Entry point of the program.
%% Usage: project3 numNodes numRequests
-module(project3).

-export([main/1]).

main([NodesStr, RequestsStr]) ->
    NumNodes = list_to_integer(NodesStr),
    NumRequests = list_to_integer(RequestsStr),
    io:format("Nodes: ~p  Requests/node: ~p~n", [NumNodes, NumRequests]);
main(_) ->
    io:format("Usage: project3 numNodes numRequests~n"),
    halt(1).
