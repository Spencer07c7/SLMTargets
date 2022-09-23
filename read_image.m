
function [image] = read_image(filename)
    
    info = imfinfo(filename);
    
    if ~strcmp(info(1).ColorType,'grayscale')
        image = 0;
        return
    end
    
    BitDepth = info(1).BitDepth;
    
    %% 
    num_images = length(info);
    
    image = zeros(info(1).Height,info(1).Width,num_images);
    
    switch BitDepth
        case 8
            image = uint8(image); 
        case 16
            image = uint16(image);
        case 32
            image = uint32(image);
    end
    
    if num_images > 10000
         parfor i = 1 : num_images
            page = imread(filename, i);
            image(:,:,i) = page;
        end       
    else
        for i = 1 : num_images
            page = imread(filename, i);
            image(:,:,i) = page;
        end
    end
    
end