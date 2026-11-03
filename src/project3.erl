%% Entry point of the program.
%% Usage: project3 numNodes numRequests
-module(project3).

-export([main/1, start_network/4]).

main([NodesStr, RequestsStr]) ->
    NumNodes = list_to_integer(NodesStr),
    NumRequests = list_to_integer(RequestsStr),
    Stats = stats:start(NumNodes * NumRequests, self()),
    Nodes = start_network(NumNodes, kv_app, kv_app:new(), Stats),
    [Pid ! {start_requests, NumRequests} || {_, Pid} <- Nodes],
    receive
        {done, Total, AvgHops} ->
            io:format("Nodes: ~p  Requests/node: ~p  Messages delivered: ~p~n",
                      [NumNodes, NumRequests, Total]),
            io:format("Average number of hops: ~.3f~n", [AvgHops])
    end;
main(_) ->
    io:format("Usage: project3 numNodes numRequests~n"),
    halt(1).

%% Start N peers. Then join them one at a time, each through a random peer
%% that has already joined. The result is a list of {Id, Pid}.
start_network(N, App, AppState, Stats) ->
    Pids = [pastry_node:start(I, App, AppState, Stats) || I <- lists:seq(1, N)],
    {Nodes, _} = lists:foldl(
        fun(Pid, {Acc, Joined}) ->
            Bootstrap = case map_size(Joined) of
                0 -> none;
                K -> maps:get(rand:uniform(K), Joined)
            end,
            Id = pastry_node:join(Pid, Bootstrap),
            {[{Id, Pid} | Acc], Joined#{map_size(Joined) + 1 => Pid}}
        end, {[], #{}}, Pids),
    lists:reverse(Nodes).
