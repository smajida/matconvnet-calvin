 function e2s2_wrapper_PascalContext()
% e2s2_wrapper_PascalContext()
%
% A wrapper for Fast-RCNN with Matconvnet that allows to train and test a network.
%
% Copyright by Holger Caesar, 2015

% Settings
global glFeaturesFolder;
projectName = 'WeaklySupervisedLearning';
run = 1;
exp = 1;
netName = 'VGG16';
dataset = PascalContextDataset();
gpus = 1;
roiPool.use = true;
roiPool.freeform.use = true;
roiPool.freeform.combineFgBox = true;
roiPool.freeform.shareWeights = true;
regionToPixel.use = true;
randSeed = 42;
logFile = 'log.txt';
batchSize = 10;
numEpochs = 10;
learningRate = repmat(1e-3, [1, numEpochs]);
segments.minSize = 400;
segments.switchColorTypesEpoch = true;
segments.switchColorTypesBatch = true;
segments.colorTypes = {'Rgb', 'Hsv', 'Lab'};
segments.colorTypeIdx = 1;
fastRcnnParams = false;
invFreqWeights = false;

% Initialize random number generator seed
if ~isempty(randSeed);
    rng(randSeed);
    if ~isempty(gpus),
        randStream = parallel.gpu.RandStream('CombRecursive', 'Seed', randSeed);
        parallel.gpu.RandStream.setGlobalStream(randStream);
    end;
end;
% Create paths
if strcmp(netName, 'AlexNet'),
    netFileName = 'imagenet-caffe-alex_beta16';
elseif strcmp(netName, 'VGG16'),
    netFileName = 'imagenet-vgg-verydeep-16_beta16';
else
    error('Error: Unknown netName!');
end;
outputFolderName = sprintf('%s_e2s2_run%d_exp%d', dataset.name, run, exp);
segmentFolder = fullfile(glFeaturesFolder, projectName, dataset.name, 'segmentations');
netPath = fullfile(glFeaturesFolder, 'CNN-Models', 'matconvnet', [netFileName, '.mat']);
outputFolder = fullfile(glFeaturesFolder, 'CNN-Models', 'E2S2', dataset.name, sprintf('Run%d', run), outputFolderName);

% Create outputFolder
if ~exist(outputFolder, 'dir'),
    mkdir(outputFolder);
end;

% Start logging
if ~isempty(logFile),
    diary(fullfile(outputFolder, logFile));
end;

% Get images
imageListTrn = dataset.getImageListTrn(true);
imageListTst = dataset.getImageListTst(true);

% Store in imdb
imdb = ImdbE2S2(dataset, segmentFolder);
imdb.data.train = imageListTrn;
imdb.data.val   = imageListTst; % val is always the same as test
imdb.data.test  = imageListTst;
imdb.batchOpts.segments = structOverwriteFields(imdb.batchOpts.segments, segments);
imdb.updateSegmentNames();

% Create nnOpts
nnOpts = struct();
nnOpts.expDir = outputFolder;
nnOpts.numEpochs = numEpochs;
nnOpts.batchSize = batchSize;
nnOpts.numSubBatches = batchSize; % Always the same as batchSize!
nnOpts.gpus = gpus;
nnOpts.continue = CalvinNN.findLastCheckpoint(outputFolder) > 0;
nnOpts.learningRate = learningRate;
nnOpts.misc.roiPool = roiPool;
nnOpts.misc.regionToPixel = regionToPixel;
nnOpts.misc.invFreqWeights = invFreqWeights;
nnOpts.bboxRegress = false;
nnOpts.fastRcnnParams = fastRcnnParams;

% Save the current options
netOptsPath = fullfile(outputFolder, 'net-opts.mat');
save(netOptsPath, 'nnOpts', 'imdb', '-v6');

% Create network
nnClass = E2S2NN(netPath, imdb, nnOpts);

% Train the network
nnClass.train();

% Test the network
stats = nnClass.test();
disp(stats);