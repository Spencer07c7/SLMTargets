function [img] = xy2img(xy)
    img = zeros(512,512);
    xy = round(xy);
    for i = 1:size(xy,1)
        img(xy(i,2),xy(i,1)) = 1;
    end
end