function TiffWriter2(image,fname,bitspersamp,bigtiff)

verbose = false;

if bigtiff
    t = Tiff(fname,'w8');
else
    t = Tiff(fname,'w');
end
tagstruct.ImageLength = size(image,1);
tagstruct.ImageWidth = size(image,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;

tagstruct.BitsPerSample = bitspersamp;

if strcmpi(class(image), 'int16')
    tagstruct.SampleFormat = Tiff.SampleFormat.Int;
end

tagstruct.SamplesPerPixel = 1;
tagstruct.RowsPerStrip = 256;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
t.setTag(tagstruct);
t.write(image(:,:,1));
numframes = size(image,3);
divider = 10^(floor(log10(numframes))-1);
tic
for i=2:numframes
    t.writeDirectory();
    t.setTag(tagstruct);
    t.write(image(:,:,i));
    if verbose
        if (round(i/divider)==i/divider)
            fprintf('Frame %d written in %.0f seconds, %2d percent complete, time left=%.0f seconds \n', ...
                i, toc, i/numframes*100, (numframes - i)/(i/toc));
        end
    end
end
t.close();