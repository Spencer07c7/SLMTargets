function [phase_mask, transformed_img] = phasemask_3D(target_img, varargin)

    p = inputParser;
    p.addParameter('Transform', 'no');
    p.addParameter('AdjustWeights', 'no');
    p.addParameter('ZRange', [-25 25]);
    p.addParameter('SinglePlaneZ',0); 
    parse(p, varargin{:}); 
    
    % Load user settings
    settings = ReadYaml('settings.yml');
    
    num_img_dimensions = numel(size(target_img));
    
    if num_img_dimensions == 3
        %z calculations
        z_distance = sqrt( (p.Results.ZRange(1) - p.Results.ZRange(2))^2 );
        z_spacing = z_distance / (size(target_img,3)-1);
        z_plane_positions = p.Results.ZRange(1):z_spacing:p.Results.ZRange(2);
    
        %get x y z target points
        [y, x, z_index] = ind2sub(size(target_img),find(target_img));
        focal_plane = find( z_plane_positions == 0 );
        z = (z_index - focal_plane ) * z_spacing;
        
    elseif num_img_dimensions == 2 %ignore z range and use SinglePlaneZ - default is 0
        xy = img2xy(target_img);
        x = xy(:,1);
        y = xy(:,2);
        z_index = ones(length(x),1);
        z = z_index*p.Results.SinglePlaneZ;
        
    else
        disp('error: cannot use image with these dimensions')
        return
        
    end
    
    z = z - settings.SLM_Offset_Z;
    
    %do transform
    if strcmp(p.Results.Transform,'3D')
        load(settings.TransformFile3D)
        [xyz] = applyAffineTransform3D_Interpolation([x y z], T);
        x = xyz(:,1);
        y = xyz(:,2);
        z = xyz(:,3);
        
    elseif strcmp(p.Results.Transform,'no')
        %do nothing
    end
    
    
    %generate transformed image
    transformed_img = zeros(size(target_img));
    for  i = 1:size(transformed_img,3)
        within_plane_indices = (z_index == i);
        [img] = xy2img([x(within_plane_indices) y(within_plane_indices)]);
        transformed_img(:,:,i) = img;
    end
        
    I = ones(size(x)); %intensity
    
    % Weight the target pixel intensity by distance from zero order
    if strcmp(p.Results.AdjustWeights,'yes')
        load(settings.WeightingFile)
        
        distances = pairwiseDistance([x y], [256 256]);
        
        % estimate intensites of spots based on calibration data
        estimatedIntensity = polyval(W.p, distances);
        MAX = polyval(W.p, 0);
        normEstimatedIntensity = estimatedIntensity / MAX;
        
        % compute weights from estimated intensites
        weights = (1 ./ normEstimatedIntensity);  % subtract to ensure linear correction. division does not.
        
        % apply weights
        I_weighted = I .* weights;
        
        if any(I_weighted<=0)
            disp('ERROR: Some spot weights <= 0')
            I_weighted(I_weighted<=0) = min(I_weighted(I_weighted>0));
        end
        
        % save weights
        I = I_weighted;
        
    end
    
    
    % Load HOTlab DLL
    HologramLibraryName = 'GenerateHologramCUDA';
    if ~libisloaded(HologramLibraryName)
        loadlibrary([HologramLibraryName '.dll'])
    end

    % Start CUDA
    deviceId    = 0;
    LUT         = [];
    cuda_error1 = calllib(HologramLibraryName,'startCUDA', zeros(512, 512), deviceId);
    
    % Generate Hologram parameters
    h_test         = [];
    h_pSLM         = zeros(512, 512);
    x              = round(x - 256);  % subtract 256 because centre of image is 0,0 (not 256,256)
    y              = round(y - 256);  % subtract 256 because centre of image is 0,0 (not 256,256)
    z              = z;
    intensities    = I;  
    N_spots        = length(x);
    N_iterations   = 100;
    h_obtainedAmps = [];
    method = 1;

    % 0: Complex addition of "Lenses and Prisms", no optimization (3D)
    % 1: Weighted Gerchberg-Saxton algorithm using Fresnel propagation (3D)
    % 2: Weighted Gerchberg-Saxton algorithm using fast fourier transforms (2D)

    % Apply corrections
    % [cuda_error, h_AberrationCorr, h_LUTPolCoeff, h_LUT_uc] = calllib(LibraryName, 'Corrections',...
    %     UseAberrationCorr, h_AberrationCorr, UseLUTPol, PolOrder, h_LUTPolCoeff, saveAmplitudes, alpha, DCborderWidth, UseLUT, h_LUT_uc);

    % Generate Hologram
    [cuda_error2,~,h_pSLM,~,~,~,~,h_obtainedAmps] = calllib(HologramLibraryName,'GenerateHologram',...
        h_test, h_pSLM, x, y, z, intensities, N_spots, N_iterations, h_obtainedAmps, method);

    phase_mask = uint8(h_pSLM / 256); %8-bit SLM

    % Stop CUDA
    cuda_error3 = calllib(HologramLibraryName,'stopCUDA');
    unloadlibrary(HologramLibraryName);  % unload dll
    
    
end


