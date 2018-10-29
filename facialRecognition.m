function [className] = facialRecognition(imagePath, net)
%insectClassification : Classifie une image et retourne le nom de la classe
%   Detailed explanation goes here

%load image
imds = imageDatastore(imagePath);

% resize image
resize = 224;
imds.ReadFcn = @(loc)imresize(imread(loc),[resize,resize]);

class = classify(net,imds);
className = cellstr(class(1));
end

