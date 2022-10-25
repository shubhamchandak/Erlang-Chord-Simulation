-module(peer).
-compile(export_all).

start(SelfId, M, FingerTable) -> 
    receive
        {initialrequest, From, ObjectId} -> requestObject(From, SelfId, ObjectId, M, FingerTable);
        {request, From, Through, Key, HopsCount} -> requestObject(From, SelfId, Key, M, FingerTable, HopsCount);
        {From, updateFingerTable, FingerTable1, SelfId1} -> start(SelfId1, M, FingerTable1);
        {getObject, From, Key, HopsCount} -> From ! {success, Key, HopsCount}
    end,
    start(SelfId, M, FingerTable).

requestObject(From, SelfId, ObjectId, M, FingerTable) ->
    <<ObjectIdKey:M, _/binary>> = crypto:hash(sha512, ObjectId),
    requestObject(From, SelfId, ObjectIdKey, M, FingerTable, 1).

requestObject(From, SelfId, Key, M, FingerTable, HopsCount) -> 
    if 
        Key == SelfId -> SelfId ! {getObject, From, Key, HopsCount};
        true -> processRequest(From, SelfId, Key, M, FingerTable, HopsCount)
    end.

processRequest(From, SelfId, Key, M, FingerTable, HopsCount) -> 
    MaxVal = pow(2, M),
    Diff = (SelfId+MaxVal - Key) rem MaxVal,
    Predecessor = getPredecessorNode(Key, 1, FingerTable, M, Diff, SelfId),
    NextNode = maps:get(1, FingerTable),
    NextNodeKey = list_to_atom("n" ++ integer_to_list(NextNode)),
    PredecessorKey = list_to_atom("n" ++ integer_to_list(Predecessor)),
    if
        Predecessor == SelfId -> NextNodeKey ! {getObject, From, Key, HopsCount+1};
        true -> PredecessorKey ! {request, From, SelfId, Key, HopsCount+1}
    end.

getPredecessorNode(Key, Index, FingerTable, M, PrevDiff, Destination) when Index == M+1 -> Destination;
getPredecessorNode(Key, Index, FingerTable, M, PrevDiff, Destination) ->
    Node = maps:get(Index, FingerTable),
    MaxVal = pow(2, M),
    Diff = (Node+MaxVal - Key) rem MaxVal,
    if
        Diff > PrevDiff -> getPredecessorNode(Key, Index+1, FingerTable, M, Diff, Node);
        true -> getPredecessorNode(Key, Index+1, FingerTable, M, PrevDiff, Destination)
    end.

pow(_, 0) -> 1;
pow(A, 1) -> A;
pow(A, N) -> A * pow(A, N-1).