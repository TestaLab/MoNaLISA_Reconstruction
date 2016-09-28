function [] = combine_camera_frames(B)
% Combines the camera frames of the parallelized RESOLFT microscope used in
% the publication: 'Nanoscopy with more than a hundred thousand
% "doughnuts"' by Andriy Chmyrov et al., to appear in Nature Methods, 2013

%% file names
% input_camera_frames = 'rawstack1_p.tif';
% input_camera_darkframe = 'darkframe.tif';
% output_filename = 'recontructed.tif';

%% some physical parameters of the setup
camera_pixel_length = 0.0615;   % camera pixel length [�m] in sample space
scanning_period = 0.3125;        % scanning period [�m] in sample space
pattern_period = 0.3125;         % Expected period of pattern in um
activation_size = 0.050;
diff_limit = 0.250; %um
% Calculation of number of scanning steps comes from the step size
% calculation when creating the simulated data.
number_scanning_steps = 20;     % number of scanning steps (NOT SPOTS) in one direction
    % total number of camera frames is (number_scanning_steps)^2
recon_pixel_length = 0.02;            % pixel length [�m] of interpolated and combined frames
pinhole_um = 0.150;

%% load camera frames and subtract background frame and correct for photobleaching

%%Ask if user wants to load new data or use same as last time
answ = questdlg('Load new data?', 'Load data', 'Yes','No', 'Yes');
switch answ
    case 'Yes'
        [LoadDataFileName,LoadDataPathName] = uigetfile({'*.*'}, 'Load data file');
        input_camera_frames = strcat(LoadDataPathName, LoadDataFileName);
        [LoadFileName,LoadPathName] = uigetfile({'*.*'}, 'Load widefield file');
        input_widefield_frames = strcat(LoadPathName, LoadFileName);
%         [LoadFileName,LoadPathName] = uigetfile({'*.*'}, 'Load darkframe');
%         input_camera_darkframe = strcat(LoadPathName, LoadFileName);  
        
        if (LoadDataFileName(1) ~= 0) && (LoadFileName(1) ~= 0)
            savepaths = {input_camera_frames, input_widefield_frames}
            save('last_data', 'savepaths');
        end
        
    case 'No'
        load('last_data')
        input_camera_frames = savepaths{1};
        input_widefield_frames = savepaths{2};
        [waste invPATH] = strtok(fliplr(input_camera_frames), '\');
        [invNAME waste] = strtok(fliplr(input_camera_frames), '\');
        PATH = fliplr(invPATH);
        NAME = fliplr(invNAME);
        LoadDataPathName = PATH;
        LoadDataFileName = NAME;
        
end
savename = strsplit(LoadDataFileName,'.');
savename = savename{1};
input_camera_darkframe = 'Darkframe_fullchip.mat';

steps = inputdlg('Input nr of scanning steps (not spots):');
number_scanning_steps = str2double(steps{1});

% derived parameters
shift_per_step = scanning_period / number_scanning_steps / camera_pixel_length;
    % shift per scanning step [camera pixels]
recon_px_per_camera_px = recon_pixel_length / camera_pixel_length;
    % length of pixel of combined frames in camera pixels
diff_lim_px = diff_limit / camera_pixel_length;

%% determine off switching pattern frequencies and offsets
answ_pat = questdlg('Use automatic or manual pattern detection?', 'Pattern selection', 'Automatic', 'Manual', 'Manual');

switch answ_pat
    case 'Automatic'
        disp('Identifying pattern...')
        pattern = switching_pattern_identification_160927(data, pattern_period / camera_pixel_length, true)
    case 'Manual'
        answ_pat = questdlg('Load seperate pattern file?', 'Pattern selection', 'Seperate', 'Use raw data', 'Seperate');
        switch answ_pat
            case 'Seperate'
                [LoadPatternFileName,LoadPatternPathName] = uigetfile({'*.*'}, 'Load pattern file');
                input_pattern_frames = strcat(LoadPatternPathName, LoadPatternFileName);
                [data widefield pattern_images] = import_data_and_pattern(input_camera_frames, input_widefield_frames, input_camera_darkframe, input_pattern_frames, true);
                pattern = switching_pattern_identification_manual(data, pattern_period / camera_pixel_length, pattern_images);                
            case 'Use raw data'
                [data widefield] = import_data(input_camera_frames, input_widefield_frames, input_camera_darkframe, true);
                pattern = switching_pattern_identification_manual(data, pattern_period / camera_pixel_length, []);                

        end
end
        
        % pattern = [3 0 3 0]
% pattern = [9.6571 0.8072 9.6568 0.8077]
disp(pattern)
% data = bleaching_correction_STHLM(data);

%% Enhance the widefield for fairer comparison
enhancedWF = WF_enhance(widefield);

%%
signalgot = 0;
signalsthlm = 0;

%% combination of camera images
% Check if bases and G matrix already exists
try
    size(B);
catch
    B = [];
end
disp('Extracting signal...')
%%
% [centralgot, peripheralgot] = signal_extraction(data, pattern, recon_px_per_camera_px, shift_per_step, pinhole_um / camera_pixel_length);
% signalgot = max(centralgot - 0.8 * peripheralgot, 0);
% % immax = max(signalgot(:));
% % immin = min(signalgot(:));
% % imstd = std(signalgot(:));
% % snr = 10*log10((immax-immin)/imstd);
% % Plot
% figure('name', sprintf('Activation size (nm): %.1f \n Pinhole size (nm): %.1f', 1000*activation_size, 1000*pinhole_um))
% subplot(1,2,1)
% imshow(enhancedWF,[])
% subplot(1,2,2)
% imshow(signalgot,[])
% colormap('hot')
% title('G�ttingen algorithm')




%%STHLM versions
% [centralLS peripheralLS B] = signal_extraction_LS_Back(data, pattern, B, diff_lim_px, recon_px_per_camera_px, shift_per_step, pinhole_um / camera_pixel_length, activation_size/camera_pixel_length);
% signalLS = max(centralLS - 0.8 * peripheralLS, 0);
% subplot(1,3,3)
% imshow(signalLS,[])
% title('Least squares algorithm')
% 
[centralsthlm, peripheralsthlm] = signal_extraction_STHLM(data, pattern, recon_px_per_camera_px, shift_per_step, pinhole_um / camera_pixel_length, activation_size/camera_pixel_length);
signalsthlm = max(centralsthlm - 0.8 * peripheralsthlm, 0);

% immax = max(signalsthlm(:));
% immin = min(signalsthlm(:));
% imstd = std(signalsthlm(:));
% snr = 10*log10((immax-immin)/imstd);
% % Plot
figure('name', sprintf('Activation size (nm): %.1f \n Pinhole size (nm): %.1f', 1000*activation_size, 1000*pinhole_um))
subplot(1,2,1)
imshow(widefield,[])
subplot(1,2,2)
imshow(signalsthlm,[])
colormap('hot')
title('Stockholm algorithm')





% saving again
% save(output_filename, 'signal', 'pixel_length');
% disp('Saving output...')
% output_filename = inputdlg('Save data?','Save', 1, {'Input file name!'})

pause
answ = questdlg('Save image?','Yes','No');
switch answ
    case 'Yes'
        dname = uigetdir(LoadDataPathName);
        fname = inputdlg('Chose name', 'Name',1,{savename});
        fname = fname{1};
        savepath = strcat(dname, '\', fname, sprintf('_Reconstruction_pin_%.0fnm_act_%.0fnm', 1000*pinhole_um, 1000*activation_size));
        disp(strcat('Saving in :', savename))
        savepath_check = savepath;
        new_ver = 2;
        while exist(savepath_check) == 7
            savepath_check = strcat(savepath, '_', num2str(new_ver))
            new_ver = new_ver + 1;
        end
        savepath = savepath_check;
        mkdir(savepath)
%         output = signalgot - min(signalgot(:));
%         output = signalgot/max(signalgot(:));
%         imwrite(output, strcat(savepath, '\', fname, '_Reconstructed_Gott', '.tif'))
        output = signalsthlm - min(signalsthlm(:));
        output = signalsthlm/max(signalsthlm(:));
        imwrite(output, strcat(savepath, '\', fname, '_Reconstructed_Sthlm', '.tif'))
%         output = signalLS - min(signalLS(:));
%         output = signalLS/max(signalLS(:));
%         imwrite(output, strcat(savepath, '\', fname, '_Reconstructed_LS', '.tif'))
        widefield = widefield - min(widefield(:));
        widefield = widefield/max(widefield(:));
        imwrite(widefield, strcat(savepath, '\', fname, '_WF', '.tif'))
        enhancedWF = enhancedWF - min(enhancedWF(:));
        enhancedWF = enhancedWF/max(enhancedWF(:));
        imwrite(enhancedWF, strcat(savepath, '\', fname, '_ENH_WF', '.tif'))
end
reconstructed = signalgot;
end