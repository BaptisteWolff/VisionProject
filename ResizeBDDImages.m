clear all; close all; clc;
'start'

%% Ce script resize les images de la bdd en resize * resize
resize = 224;
digitDatasetPath = 'BDD';
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');
% inclu les sub folders, les label dépendent du nom des dossiers de la BDD


%% crop
crop = 1 %
cropSize = floor(resize/16);

%% Resize
imds.ReadSize = numpartitions(imds);
if crop == 1
    imds.ReadFcn = @(loc)imresize(imread(loc),[resize+cropSize,resize]);
else
    imds.ReadFcn = @(loc)imresize(imread(loc),[resize,resize]);
end

%% check random
% figure(1);
% img = readimage(imds,5); imshow(img); size(img)
% figure(2);
% img = readimage(imds,222); imshow(img); size(img)



%% save
files = imds.Files;
for i = 1:numpartitions(imds)
    image = readimage(imds,i);
    s = size(image,3);
    if s~=3
       files{i}
       image(:,:,2) = image(:,:,1);
       image(:,:,3) = image(:,:,1);
    end
    if crop == 1
       image = image(1:resize,:,:); 
    end
    imwrite(image,files{i});
end
'end'
