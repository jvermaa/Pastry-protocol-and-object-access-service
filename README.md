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
   erl +P 4000000 -noshell -pa ebin -run project3 main numNodes numRequests -s init stop
   ```
   Example: 1000 peers, and each peer sends 10 requests:
   ```
   erl +P 4000000 -noshell -pa ebin -run project3 main 1000 10 -s init stop
   ```

Note: `pastry_app.erl` compiles first, because the other modules use its behavior. `+P 4000000` increases the process limit, because each peer is one process.

## What is working

## What is the largest network you managed to deal with
