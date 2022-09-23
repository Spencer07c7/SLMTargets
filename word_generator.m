 close all force
%% options
word = {'GitHub'};
font = 'Minecraftia';
fontSize = 8;
scaleFactor = 7;

%% generate images for ASCII character set (32 to 127):
characters = char(32:126);
characterImgs = [];
for i = 1:numel(characters)
    c = characters(i);
    characterImgs(i,:,:) = rgb2gray(insertText(zeros(14, 8, 1), [5 7], c, ...
        'Font', font, ...
        'FontSize', fontSize,...
        'AnchorPoint', 'Center', ...
        'TextColor', [1 1 1], ...
        'BoxOpacity', 0)) > 0.5;
end

%%  Build word image from individual characters
wordImg = [];
for w = 1:numel(word)
indices = unicode2native(word{w}) - 31;
temp = [];
    for i = 1:numel(indices)
        temp = [temp squeeze(characterImgs(indices(i),:,:))];
    end
    wordImg{w} = temp;
end

longestLine = max(cellfun('size', wordImg, 2));
lineHeight = size(characterImgs,2);
wholeImg = zeros(lineHeight*numel(wordImg), longestLine);
for i = 1:numel(wordImg)
    thisLine = wordImg{i};
    yidx = (i-1)*lineHeight + 1;
    wholeImg(yidx:yidx+lineHeight-1, 1:size(thisLine,2)) = thisLine;
end

[y,x] = find(wholeImg);

%% Scale and plonk word image into middle of 512x512 image
img = zeros(512,512);
xt = round(scaleFactor*x - mean(scaleFactor*[min(x) max(x)]));
yt = round(scaleFactor*y - mean(scaleFactor*[min(y) max(y)]))-25;
for i = 1:numel(x)
    img(256 + yt(i), 256 + xt(i)) = 1;
end   
imwrite(uint8(img),'GitHub_targets.tif')
imshow(img)
%% 

[phase_mask, transformed_img] = phasemask_3D(img,'Transform','3D','AdjustWeights','yes','SinglePlaneZ',0);

imwrite(uint8(phase_mask),['GitHub_phasemask.tif']);
