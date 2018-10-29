close all; clear all; clc;
%% Charge la BDD
% currentFolder = pwd;
% digitDatasetPath = [currentFolder '\BDD'];
digitDatasetPath = 'BDD';
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');
% inclu les sub folders, les label dépendent du nom des dossiers de la BDD

%% Resize toutes les images en resize * resize
% resize = 256
% imds.ReadSize = numpartitions(imds);
% imds.ReadFcn = @(loc)imresize(imread(loc),[220,220]);

%% Affiche quelques images
% figure;
% perm = randperm(numpartitions(imds),20);
% for i = 1:20
%     subplot(4,5,i);
%     imshow(imds.Files{perm(i)});
% end

%% Compte le nombre d'images par catégorie
labelCount = countEachLabel(imds)
labelCountSize = size(labelCount, 1);

%% Taille des images
img = readimage(imds,1);
s = size(img)

%% Séparation des images d'entrainement/de test + mélange de toutes les images
numTrainFiles = floor(min(labelCount.Count)*4/5) % nombre d'images d'entrainement par catégorie
[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,'randomize');
[imdsValidation,~] = splitEachLabel(imdsValidation,floor(min(labelCount.Count)*1/5),'randomize');

%% Augmente le nombre d'images avec des transformations
imageAugmenter = imageDataAugmenter( ...
    'RandXReflection',true,...
    'RandYReflection',true,...
    'RandRotation',[0,360])
%     'RandXScale',[1 2],...
%     'RandYScale',[1 2])
%     'RandXTranslation',[-30 30], ...
%     'RandYTranslation',[-30 30])
    
imdsTrain = augmentedImageDatastore([s(1) s(2) 3],imdsTrain, 'DataAugmentation',imageAugmenter);

%% Charger le réseau pré-entrainé
net = vgg16
%net = googlenet;
net.Layers

%% On remplace les couches finales
layersTransfer = net.Layers(1:end-3);
numClasses = numel(categories(imds.Labels));
layers = [
    layersTransfer
    fullyConnectedLayer(numClasses,'WeightLearnRateFactor',20,'BiasLearnRateFactor',20)
    softmaxLayer
    classificationLayer];

%% Options d'entrainement
options = trainingOptions('sgdm', ...
    'MiniBatchSize',32, ...
    'MaxEpochs',1, ...
    'InitialLearnRate',0.00012, ...
    'ValidationData',imdsValidation, ...
    'ValidationFrequency',116, ...
    'ValidationPatience',Inf, ...
    'Verbose',false, ...
    'LearnRateDropFactor',0.9,... % drop * learnRate
    'LearnRateDropPeriod',1,...  % nb d'époques à partir dequels le learnrate est mult par le drop factor
    'LearnRateSchedule','piecewise',...
    'Shuffle','every-epoch', ...
    'Plots','training-progress');

% options = trainingOptions('sgdm',...
%       'LearnRateSchedule','piecewise',...
%       'InitialLearnRate',1e-4,...
%       'LearnRateDropFactor',0.9,... % drop * learnRate
%       'LearnRateDropPeriod',1,...  % nb d'époques à partir dequels le learnrate est mult par le drop factor
%       'MiniBatchSize',30,... % 128 par défault
%       'MaxEpochs',2);
  
%% Entrainement!!
net = trainNetwork(imdsTrain,layers,options);

%% Mesure la précision
% YPred = classify(net,imdsValidation);
% YValidation = imdsValidation.Labels;

% accuracy = sum(YPred == YValidation)/numel(YValidation)

%% Sauvegarde
netVgg16 = net;
save netVgg16

%% Generation d'une fonction
% genFunction(net, 'insectClassificationNet','MatrixOnly','yes');
