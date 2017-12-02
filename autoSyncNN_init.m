function net = autoSyncNN_init(netparams)

    %%% NETWORK INITIALIZATION
    d = netparams.numUnits ;  % number of hidden units
    N = netparams.N;
    inputDim = netparams.nsigs;
    outputDim = 1;

    x = Input('gpu', netparams.gpuState) ;  % [dim bsize N]

    % Forward LSTM NETWORK. 
    % initialize the shared parameters for an LSTM with d units
    [W, b] = vl_nnlstm_params(d, inputDim) ;

    h = cell(N, 1);
    c = cell(N, 1);
    h{1} = zeros(d, size(x,2), 'single');
    c{1} = zeros(d, size(x,2), 'single');

    % compute LSTM hidden states for all time steps
    for t = 1:N-1
    [h{t+1}, c{t+1}] = vl_nnlstm(x(:,:,t), h{t}, c{t}, W, b, 'clipGrad', netparams.clipGrad) ;
    end

    % Backward LSTM NETWORK. 
    % size(text,2) =  (the batch size).
    % initialize the shared parameters for an LSTM with d units
    [Wg, bg] = vl_nnlstm_params(d, inputDim) ;

    g = cell(N, 1);
    gb = cell(N, 1);
    g{end} = zeros(d, size(x,2), 'single');
    gb{end} = zeros(d, size(x,2), 'single');

    % compute LSTM hidden states for all time steps
    for t = N:-1:2
        [g{t-1}, gb{t-1}] = vl_nnlstm(x(:,:,t), g{t}, gb{t}, Wg, bg, 'clipGrad', netparams.clipGrad) ;
    end

    % concatenate hidden states along 3rd dimension, ignoring initial state.
    % H and G will have size [d, batchSize, N - 2]
    H = cat(3, h{2:end}) ;
    G = cat(3, g{2:end}) ;
    
    S = cat(1, H, G);

    % final projection (note same projection is applied at all time steps (via batchSize))
    fc1 = vl_nnconv(permute(S, [3 4 1 2]), 'size', [1, 1, 2*d, 2*d]) ; 
    fr1 = 2 * vl_nnsigmoid(2 * fc1) - 1 ;                               % tanh = 2*signmoid(2*x) - 1
    fc2 = vl_nnconv(fr1, 'size', [1, 1, 2*d, d]) ; 
    fr2 = 2 * vl_nnsigmoid(2 * fc2) - 1 ;                               % tanh = 2*signmoid(2*x) - 1
    prediction = vl_nnconv(fr2, 'size', [1, 1, d, outputDim]) ; 

    % the ground truth "next" sample
    idx = Input('gpu', netparams.gpuState)  ;  % [1 bsize N]
    nextSample = permute(idx(1,:,2:N), [3 1 4 2]) ;

    % compute loss and error
    %loss = vl_nnloss(prediction, nextSample, 'loss', 'logistic') ;
    loss = vl_nnpdist(prediction, nextSample, 2);
    %err = mean(loss);
    %sum(sum((prediction - y).^2)) ;

    % use workspace variables' names as the layers' names, and compile net
    Layer.workspaceNames() ;
    net = Net(loss) ;

end

