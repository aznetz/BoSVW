% DeepLabV3plus network for the segmentation
% Joonsang Lee, July 2020
% script_subImage.m to get imases and labels
%% Path
path_data = '/data/jslee/pathology/jeff/DL_136/subImages';
path_DL_model = '/data/jslee/pathology/jeff/DL_136/DL_model'; % v6 136 images

% then load image and label to get imds and pxds: use these as testdata to
% evaluage. 1 create TempDir 
TempDir = fullfile(path_data, 'TempDir');
mkdir(TempDir)

%% Build
imageSize = [256 256 3];
numClasses = 6;
network = 'resnet18'; % 'inceptionresnetv2'
lgraph = deeplabv3plusLayers(imageSize, numClasses, network, 'DownsamplingFactor', 8);

%% analyze Network
analyzeNetwork(lgraph)

%% load image data
% use script_subImage.m
imgDir = fullfile(path_data, 'images');
imds = imageDatastore(imgDir);

%% load label 
labelDir = fullfile(path_data, 'labels');
classes = ["open_glomeruli" "arterioles" "GS_glomeruli" "interstitium" "tubules" "misc"];
pixelLabelID = [1 2 3 4 5 6]; % [255 0]
pxds = pixelLabelDatastore(labelDir,classes,pixelLabelID);

%% Dataset Statistics
tbl = countEachLabel(pxds);

frequency = tbl.PixelCount/sum(tbl.PixelCount);

bar(1:numel(classes),frequency)
xticks(1:numel(classes)) 
class_name = ["open glomeruli", "arterioles","GS glomeruli", "interstitium","tubules", "mics"];
xticklabels(class_name)
xtickangle(45)
ylabel('Frequency')
set(gcf, 'color', 'w')

%% Balance classes
% imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
% classWeights = median(imageFreq) ./ imageFreq;
% 
% pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
% lgraph = replaceLayer(lgraph,"classification",pxLayer);

%% Prepare Training, Validation, and Test Sets
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionInterstitiumData(imds,pxds,classes,pixelLabelID);

numTrainingImages = numel(imdsTrain.Files);
numValImages = numel(imdsVal.Files);
numTestingImages = numel(imdsTest.Files);
fprintf('\nnum Training Images = %d\n', numTrainingImages)
fprintf('num Validate Images = %d\n', numValImages)
fprintf('num Testing Images = %d\n', numTestingImages)

%% Define validation data
pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal);

%% training options
TempDir = fullfile(path_data, 'TempDir');
mkdir(TempDir)
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'ValidationData',pximdsVal,...
    'MaxEpochs',30, ...  
    'MiniBatchSize',6, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', TempDir, ...
    'VerboseFrequency',2,...
    'Plots', 'training-progress');

%% Data Augmentation
% augmenter = imageDataAugmenter('RandXReflection',true, ...
%      'RandRotation', [-30,30], ...
%      'RandXTranslation', [-10, 10], ...
%      'RandYTranslation', [-10, 10]);


augmenter = imageDataAugmenter('RandXReflection',true,...
    'RandRotation', [-45,45], ...
    'RandScale',[0.7 1.5], ...
    'RandXShear',[-10 10], ...
    'RandYShear',[-10 10], ...
    'RandXTranslation', [-20, 20], ...
    'RandYTranslation', [-20, 20]);
%pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain, 'OutputSize', (256,256,5),'DataAugmentation',augmenter);

pximds = pixelLabelImageDatastore(imdsTrain,pxdsTrain, 'DataAugmentation',augmenter);

%% train the network
[net, info] = trainNetwork(pximds, lgraph, options);

%% test the model
I = readimage(imdsTest,111);
C = semanticseg(I, net);

B1 = labeloverlay(I,C,'Transparency',0.3);
B2 = labeloverlay(I,C,'Transparency',0.9);
figure, imshowpair(B1, B2, 'montage')

%% evaluate Trained Network
pxdsResults = semanticseg(imdsTest, net, 'MiniBatchSize', 8, 'WriteLocation', TempDir, 'Verbose', false);
metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest, 'Verbose', false);
metrics.DataSetMetrics
metrics.ClassMetrics