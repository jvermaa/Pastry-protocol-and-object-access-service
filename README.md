# Pastry-protocol-and-object-access-service

## Team Members:
- Jatin Verma: jverma@ufl.edu
- Rohan Vudavagandla: vudavagandla.ro@ufl.edu

## How to compile and start the program
You must have Erlang/OTP installed. Do these commands in the root folder of the project.

1. Compile the modules:
   ```
   mkdir -p ebin
   erlc -I include -pa ebin -o ebin src/pastry_app.erl src/*.erl
   ```
2. Start the program. Replace `numNodes` and `numRequests` with numbers:
   ```
   ./project3 numNodes numRequests
   ```
   Example: 1000 peers, and each peer sends 10 requests:
   ```
   ./project3 1000 10
   ```

Note: `pastry_app.erl` compiles first, because the other modules use its behavior. The `project3` script starts Erlang with `+P 4000000`. This increases the process limit, because each peer is one process.

## What is working
All items in the problem definition work:

- **One actor for each peer.** Each peer is one Erlang process (`pastry_node`). The peers send messages to each other. They share no memory.
- **Network join (section 2.4 of the paper).** The program adds the peers to the network one at a time. Each new node X sends a join message with key X through a random peer that is already in the network. Each node on the path adds its routing table rows to the message. The last node Z adds its leaf set and sends all entries to X. Then X tells all nodes in its tables about its arrival.
- **Routing (Table 1 of the paper).** Each message goes to the node with the ID that is numerically nearest to the key. Node IDs and keys have 128 bits, b = 4 and |L| = 16.
- **Pastry API (section 2.3).** `pastryInit` is `pastry_node:join/2`, and `route(msg, key)` is `pastry_node:route/3`. The application supplies `deliver/3`, `forward/4` and `new_leafs/2` (the `pastry_app` behavior).
- **Object access service (`kv_app`).** The service keeps one string for each key. Odd requests put a string with a new random key. Even requests get the string that the previous request put.
- **Requests and output.** Each peer sends 1 request each second. When all peers complete `numRequests` requests, the program shows the average number of hops and stops.

The average number of hops is approximately log16(numNodes). The paper gives this value as the expected number of hops:

| numNodes | numRequests | Average hops | log16(numNodes) |
|---|---|---|---|
| 10 | 4 | 0.750 | 0.83 |
| 1,000 | 5 | 2.508 | 2.49 |
| 10,000 | 3 | 3.279 | 3.32 |
| 100,000 | 2 | 4.075 | 4.15 |
| 200,000 | 2 | 4.366 | 4.40 |

We did not implement the neighborhood set M, because the paper uses it only for locality. Locality needs a proximity metric, but all peers are on one computer. Thus the rare case of Table 1 uses only the leaf set L and the routing table R.

## What is the largest network you managed to deal with
**200,000 nodes.** Each node sent 2 requests (400,000 messages). The average was 4.366 hops. The run time was 134 seconds, and the program used 12.4 GB of memory. The computer has 32 GB of RAM and 10 CPU cores. The limit is the memory. For a network of 500,000 nodes, it is necessary to have more RAM than this computer has.
