## Project 1 - Gossip Algorithm

#### Group Members:

* Shubham Chandak
* Arman Singhal

- - -


## How to run the program?

**Step 1:** Open terminal. Change your directory to the one containing files server.erl and peer.erl
   &nbsp;
**Step 2:** Compile server.erl and peer.erl using the command,
```erlang
c(server).
```
A message saying, {ok, server} will confirm the successfull compilation.
   &nbsp; 
**Step 3:** Compile peer.erl using the command,
```erlang
c(peer).
```
A message saying, {ok, peer} will confirm the successfull compilation.
   &nbsp;
**Step 4:** We will now spawn a new process using the following command.

```erlang
server:startServer([NumOfNodes], [NumOfRequestPerNode], [M])

Eg: server:startServer(100, 10, 32)
```

**Expected Results:** Average number of hops are printed for the simulation 

**Actual Results:**

For NumOfNodes = 100, NumOfMessagePerNode = 10 and M = 32  ->  Average Hop Count = 5.156

For NumOfNodes = 15, NumOfMessagePerNode = 10 and M = 16  ->  Average Hop Count = 3.75

For NumOfNodes = 30, NumOfMessagePerNode = 10 and M = 16  ->  Average Hop Count = 4.61

As we see above the average hop count is roughly around (log base 2 of M) thus maching therotical boundaries.

