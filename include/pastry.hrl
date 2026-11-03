%% Pastry parameters. These are the values from the paper.
-define(B, 4).            % bits in one digit. The digit base is 2^B.
-define(ID_BITS, 128).    % bits in a node ID and in a key.
-define(LEAF_SIZE, 16).   % size of the leaf set |L|.
-define(INTERVAL_MS, 1000). % each peer sends 1 request each second.
