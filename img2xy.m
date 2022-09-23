function [xy] = img2xy(img)
    %x is row, y is column
    
    [y, x] = find(img > 0);
    xy = [x y];
    
end