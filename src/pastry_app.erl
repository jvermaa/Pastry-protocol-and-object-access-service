%% The API that an application on Pastry must supply (section 2.3).
-module(pastry_app).

%% Pastry calls deliver when this node is the nearest node to Key.
-callback deliver(Msg :: term(), Key :: integer(), State :: term()) -> term().

%% Pastry calls forward before it sends Msg to NextId.
%% Give null as NextId to stop the message at this node.
-callback forward(Msg :: term(), Key :: integer(), NextId :: integer(), State :: term()) ->
    {term(), integer() | null, term()}.

%% Pastry calls new_leafs when the leaf set of this node changes.
-callback new_leafs(LeafSet :: [{integer(), pid()}], State :: term()) -> term().
