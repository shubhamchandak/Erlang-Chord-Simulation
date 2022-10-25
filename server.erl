-module(server).
-compile(export_all).

startServer(NumNodes, NumRequests, M) -> 
    spawn(server, start, [NumNodes, NumRequests, M]).

start(NumNodes, NumRequests, M) -> 
    NodeIds = createRing(NumNodes, M, []),
    [A|_] = NodeIds,
    setFingerTableAndSuccessor(lists:append(NodeIds, [A]), M),
    sendRequest(NodeIds, NumRequests),
    listen(NumNodes*NumRequests, 0, 0).

listen(TotalRequests, NumObjectServed, TotalHopCount) when TotalRequests == NumObjectServed -> io:format("Average Hop Count = ~p ~n", [TotalHopCount/NumObjectServed]), halt(); 

listen(TotalRequests, NumObjectServed, TotalHopCount) -> 
    receive
        {success, Key, HopsCount} -> io:format("response received for Key: ~p with total hops = ~p~n", [Key, HopsCount]), listen(TotalRequests, NumObjectServed+1, TotalHopCount+HopsCount)
    end.

sendRequest(NodeIds, 0) -> io:format("requests sent to all the nodes!!");
sendRequest(NodeIds, NumRequests) -> 
    io:format("sendRequest ~p~n", [NodeIds]),
    requestObject(NodeIds, NumRequests),
    sendRequest(NodeIds, NumRequests-1).

requestObject([A], NumRequests) -> 
    Destination = list_to_atom("n" ++ integer_to_list(A)),
    ObjectId = "O" ++ integer_to_list(NumRequests),
    Destination ! {initialrequest, self(), ObjectId};
    

requestObject([A|B], NumRequests) -> 
    %io:format("ooo ~p~n",[B]),
    %[A|B] = NodeIds,
    Destination = list_to_atom("n" ++ integer_to_list(A)),
    ObjectId = "O" ++ integer_to_list(NumRequests),
    Destination ! {initialrequest, self(), ObjectId},
    requestObject(B, NumRequests).

createRing(0, M, List) -> lists:sort(List);
createRing(NumNodes, M, List) -> 
    Pid = spawn(peer, start, [-1, M, {}]),
    <<B:M, _/binary>> = crypto:hash(sha512, pid_to_list(Pid)),
    register(list_to_atom("n" ++ integer_to_list(B)), Pid),
    createRing(NumNodes-1, M, List ++ [B]).

setFingerTableAndSuccessor(NodeIds, M) -> 
    setFingerTable(NodeIds, length(NodeIds), M, M, maps:new()).

setFingerTable(NodeIds, 1, M, K, FingerTable) -> io:format("FingerTable updated for all nodes!");

setFingerTable(NodeIds, Index, M, 0, FingerTable) -> 
    % io:format("~p ~n", [FingerTable]),
    SelfId = lists:nth(Index, NodeIds),
    Node = list_to_atom("n" ++ integer_to_list(SelfId)),
    Node ! {self(), updateFingerTable, FingerTable, SelfId},
    setFingerTable(NodeIds, Index-1, M, M, FingerTable);

setFingerTable(NodeIds, Index, M, K, FingerTable) -> 
    KthKey = (lists:nth(Index, NodeIds) + pow(2, K-1)) rem pow(2, M),
    Successor = getSuccessorNode(NodeIds, KthKey),
    FingerTable1 = FingerTable#{K => Successor},
    setFingerTable(NodeIds, Index, M, K-1, FingerTable1).

getSuccessorNode([NodeId], Key) -> NodeId;
getSuccessorNode(NodeIds, Key) -> 
    [X|Y] = NodeIds,
    if 
        X >= Key -> X;
        Y < X -> Y;
        true -> getSuccessorNode(Y, Key)
    end.    

pow(_, 0) -> 1;
pow(A, 1) -> A;
pow(A, N) -> A * pow(A, N-1).