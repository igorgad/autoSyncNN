
clear;
rng(0) ;

run(fullfile(matlabroot, 'toolbox/autonn/setup_autonn.m')) ;  % add AutoNN to the path

opts.netparams.N = 128;
opts.netparams.nsigs = 2;
opts.netparams.model = 'lstm' ;
opts.netparams.numUnits = 96 ;
opts.netparams.clipGrad = 10 ;
opts.netparams.maxDelay = 64;

opts.db.dataDir = '/media/pepeu/582D8A263EED4072/DATASETS/Bach10/';
opts.db.dataPath = sprintf('%sautoSyncNN_REFTEST_MD%d_NS%d_N%d.dat',opts.db.dataDir,opts.netparams.maxDelay,opts.netparams.nsigs,opts.netparams.N);

opts.db.m = memmapfile(opts.db.dataPath,        ...
'Offset', 0,                ...
'Format', {                    ...
'single',  [opts.netparams.N opts.netparams.nsigs], 'amat'; ...
'single',  [opts.netparams.N 1], 'rmat'; ...
'int32', [1 1], 'ref'},  ...
'Writable', true);

opts.db.id = 1:size(opts.db.m.Data,1);
opts.trainOpts.train = opts.db.id(randi(numel(opts.db.id)-1,floor(numel(opts.db.id)*0.8 / 5),1));
opts.db.id2 = setdiff(opts.db.id,opts.trainOpts.train);
opts.trainOpts.val = opts.db.id2(randi(numel(opts.db.id2)-1,floor(numel(opts.db.id)*0.2 / 5),1));

prefix = 'autoSyncNN_REFTEST_BI-LSTM2';

opts.trainOpts.gpus = [1] ; opts.netparams.gpuState = true;
opts.trainOpts.batchSize = 1440 ;
opts.trainOpts.plotOutputs = true ;
opts.trainOpts.plotDiagnostics = false ;
opts.trainOpts.plotStatistics = true;
opts.trainOpts.numEpochs = 400 ;
opts.trainOpts.learningRate = 0.0005; %1./( 50 + exp( 0.05 * (1:opts.trainOpts.numEpochs) ) );
opts.trainOpts.momentum = 0.8 ;
opts.trainOpts.weightDecay = 0.00 ;
opts.trainOpts.continue = true;                                                                                                                                                                                   
opts.trainOpts.stats = {'loss'};
opts.trainOpts.solver = @adam;        % Use ADAM solver instead of SGD
opts.trainOpts.nesterovUpdate = true; % Turn ADAM into NADAM
opts.trainOpts.expDir = sprintf('%s/matconvdata/%s_NT%d_NV%d_NHU%d_NS%d_N%d', opts.db.dataDir, prefix, numel(opts.trainOpts.train), numel(opts.trainOpts.val), opts.netparams.numUnits, opts.netparams.nsigs, opts.netparams.N);

opts.db
opts.netparams
opts.trainOpts

mkdir(opts.trainOpts.expDir);
struct2file(opts,[opts.trainOpts.expDir, '/runparams.txt']);

% INITIALIZE NETWORK
net = autoSyncNN_init(opts.netparams);
% TRAIN
info = autoSyncNN_train(net, opts.db.m, @getBatch, opts.trainOpts) ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function struct2file (str, filename)
    fileId = fopen(filename,'w+');
    fprintStruct(str,1,fileId);
end

function fprintStruct(str, i, fileId)
    LogicalStr = {'false', 'true'};
    varlist = fieldnames(str);
    for v = 1:size(varlist,1)
        if isa(str.(varlist{v}),'struct')
            fprintStruct(str.(varlist{v}), i + 1, fileId);
        else
            if isa(str.(varlist{v}), 'char') 
                fprintf (fileId,'%s\t\t%s\n', varlist{v}, str.(varlist{v}));
            end
            if isa(str.(varlist{v}), 'logical') 
                fprintf (fileId,'%s\t\t%s\n', varlist{v}, LogicalStr{str.(varlist{v}) + 1});
            end
            if isa(str.(varlist{v}), 'function_handle') 
                fprintf (fileId,'%s\t\t%s\n', varlist{v}, func2str(str.(varlist{v})));
            end
            if isa(str.(varlist{v}), 'numeric') && numel(str.(varlist{v})) <= 1
                fprintf (fileId,'%s\t\t%d\n', varlist{v}, str.(varlist{v}));
            end
            if isa(str.(varlist{v}), 'numeric') && numel(str.(varlist{v})) > 1
                fprintf (fileId,'%s\t\t%s\n', varlist{v}, num2str(size(str.(varlist{v}))) );
            end
            
        end
    end
end
