close all; clear all; clc;
%% Charge la BDD
% currentFolder = pwd;
% digitDatasetPath = [currentFolder '\BDD'];
digitDatasetPath = 'BDD';
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');
% inclu les sub folders, les label d�pendent du nom des dossiers de la BDD

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

%% Compte le nombre d'images par cat�gorie
labelCount = countEachLabel(imds)
labelCountSize = size(labelCount, 1);

%% Taille des images
img = readimage(imds,1);
s = size(img)

%% S�paration des images d'entrainement/de test + m�lange de toutes les images
numTrainFiles = floor(min(labelCount.Count)*4/5) % nombre d'images d'entrainement par cat�gorie
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

%% Charger le r�seau pr�-entrain�
net = googlenet
%net = googlenet;
% net.Layers

%% On remplace les couches finales
lgraph = layerGraph(net);
% figure
% plot(lgraph);
numClasses = numel(categories(imds.Labels));
layers = [
%     layersTransfer
    fullyConnectedLayer(numClasses,'WeightLearnRateFactor',200,'BiasLearnRateFactor',200,'Name','loss3-classifier')
    softmaxLayer('Name','prob')
    classificationLayer('Name','output')];

lgraph = removeLayers(lgraph,'loss3-classifier');
lgraph = removeLayers(lgraph,'prob');
lgraph = removeLayers(lgraph,'output');

lgraph = addLayers(lgraph, layers);
lgraph = connectLayers(lgraph,'pool5-drop_7x7_s1','loss3-classifier');

%% Options d'entrainement
options = trainingOptions('sgdm', ...
    'MiniBatchSize',32, ...
    'MaxEpochs',3, ...
    'InitialLearnRate',0.0001, ...
    'ValidationData',imdsValidation, ...
    'ValidationFrequency',50, ...
    'ValidationPatience',Inf, ...
    'Verbose',false, ...
    'LearnRateDropFactor',0.5,... % drop * learnRate
    'LearnRateDropPeriod',1,...  % nb d'�poques � partir dequels le learnrate est mult par le drop factor
    'LearnRateSchedule','piecewise',...
    'Shuffle','every-epoch', ...
    'Plots','training-progress');

% options = trainingOptions('sgdm',...
%       'LearnRateSchedule','piecewise',...
%       'InitialLearnRate',1e-4,...
%       'LearnRateDropFactor',0.9,... % drop * learnRate
%       'LearnRateDropPeriod',1,...  % nb d'�poques � partir dequels le learnrate est mult par le drop factor
%       'MiniBatchSize',30,... % 128 par d�fault
%       'MaxEpochs',2);
  
%% Entrainement!!
net = trainNetwork(imdsTrain,lgraph,options);

%% Mesure la pr�cision
% YPred = classify(net,imdsValidation);
% YValidation = imdsValidation.Labels;

% accuracy = sum(YPred == YValidation)/numel(YValidation)

%% Sauvegarde
netGoogle = net;
save netGoogle

%% Generation d'une fonction
% genFunction(net, 'insectClassificationNet','MatrixOnly','yes');
