
clear;
rng(0) ;

run(fullfile(matlabroot, 'toolbox/autonn/setup_autonn.m')) ;  % add AutoNN to the path

dataDir = '/media/pepeu/582D8A263EED4072/DATASETS/Bach10/'

N = 512;
nwin = 1;
nsigs = 2;

dataPath = sprintf('%sautoSyncNN_AUTOTEST_N%d_NW%d.dat',dataDir,N,nwin);

m = memmapfile(dataPath,        ...
'Offset', 0,                ...
'Format', {                    ...
'single',  [N nwin nsigs], 'amat'; ...
'int32', [1 1], 'ref'},  ...
'Writable', true);

id = 1:size(m.Data,1);
trainOpts.train = id(randi(numel(id)-1,numel(id)*0.8,1));
id2 = setdiff(id,trainOpts.train);
trainOpts.val = id2(randi(numel(id2)-1,numel(id)*0.2,1));

prefix = 'autoSyncNN_AUTOTEST_LSTM';

trainOpts.gpus = [1] ;
trainOpts.batchSize = 400 ;
trainOpts.plotDiagnostics = false ;
trainOpts.plotStatistics = true;
trainOpts.numEpochs = 200 ;
trainOpts.learningRate = 1./( 50 + exp( 0.05 * (1:trainOpts.numEpochs) ) ); % [0.01 * ones(1,25), 0.007 * ones(1,100), 0.004 * ones(1,200), 0.002 * ones(1,500)] ;
trainOpts.momentum = 0.8 ;
trainOpts.weightDecay = 0.00 ;
trainOpts.continue = true;                                                                                                                                                                                   
trainOpts.expDir = sprintf('%s/matconvdata/%s_NT%d_NV%d_N%d_NW%d', dataDir, prefix, numel(trainOpts.train), numel(trainOpts.val), N, nwin)


netparams.model = 'lstm' ;
netparams.numUnits = 100 ;
netparams.clipGrad = 10 ;

%%% NETWORK INITIALIZATION
d = 512 ;  % number of hidden units

x = Input('gpu', true) ;  % size = [2, batchSize, N]

switch netparams.model
case 'lstm'
  % initialize the shared parameters for an LSTM with d units
  [W, b] = vl_nnlstm_params(d, 2) ;
  
  % initial state. note that we instantiate zeros() using a dynamic size,
  % size(text,2) (the batch size).
  h = cell(N, 1);
  c = cell(N, 1);
  h{1} = zeros(d, trainOpts.batchSize, 'single');
  c{1} = zeros(d, trainOpts.batchSize, 'single');

  % compute LSTM hidden states for all time steps
  for t = 1 : N - 1
    [h{t+1}, c{t+1}] = vl_nnlstm(x(:,:,t), h{t}, c{t}, W, b, 'clipGrad', netparams.clipGrad) ;
  end
  

case 'rnn'
  Wi = Param('value', 0.1 * randn(d, 2, 'single')) ;  % input weights
  Wh = Param('value', 0.1 * randn(d, d, 'single')) ;         % hidden weights
  bh = Param('value', zeros(d, 1, 'single')) ;               % hidden biases
  
  % initial state
  h = cell(N, 1);
  h{1} = zeros(d, size(text,2), 'single');
  
  % compute RNN hidden states for all time steps
  for t = 1 : N - 1
    h{t+1} = vl_nnsigmoid(Wi * x(:,:,t) + Wh * h{t} + bh) ;
  end

otherwise
  error('Unknown model.') ;
end


% concatenate hidden states along 3rd dimension, ignoring initial state.
% H will have size [d, batchSize, T - 2]
H = cat(3, h{2:end}) ;

% final projection (note same projection is applied at all time steps)
prediction = vl_nnconv(permute(H, [3 4 1 2]), 'size', [1, 1, d, 2]) ; %numChars


% the ground truth "next" char for each of the T-1 input chars
idx = Input('gpu', true)  ;  % as indexes, not one-hot encodings
nextSample = permute(idx(1,:,2:N), [3 1 4 2]) ;

% compute loss and error
loss = vl_nnpdist(prediction, nextSample, 2) ;

% use workspace variables' names as the layers' names, and compile net
Layer.workspaceNames() ;
net = Net(loss) ;

% --------------------------------------------------------------------
%                                                                Train
% --------------------------------------------------------------------

info = autoSyncNN_train(net, m, @getBatch, trainOpts) ;


