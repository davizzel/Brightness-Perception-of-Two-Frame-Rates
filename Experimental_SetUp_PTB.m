%% Experimental Set-Up for Comparing the Brightness Perception of Two Different Frame Rates


%% Display test sequences in UHD resolution in
%% maximum frame rate of monitor.

%% David Kovacs 2022.11.17

% Script enters folder with subfolders containing
% the image sequences in form of tiff-files.
% Order for opening the subfolders is randomized
% for each experimental run.
% Textures are displayed via a loop that runs until key is
% pressed or aborts after 60 secs.
% 5 test-sequences are shown before the actual
% trial begins.

% Script was developed and tested on following
% set-up: Windows 10 (Version 10.0), MATLAB
% (R2021A, Update 6, 9.10.0.1851785), Psychtoolbox
% (Version 3.0.18 - Build date: May 18 2022),
% NVIDIA GeForce RTX 3070

%%
% Clear workspace and close screens
sca; % close all screens
clear all; % clear all variables
clc; % clear command window


disp('============================ Luminance perception of MPF ==============================================')
disp('== Experiment to evaluate the brightness perception of motion picture frames ==');
fprintf('\n');

%% Input experimental parameters
subjectsname = input('Initials of the first and last name (internal use only!): ','s'); % input initials of subject
subjectsage = input('Age of subject: ','s'); % input subject's age
subjectsgender = input('To which gender identity does the subject identify most?: ', 's'); % input gender identity of subject
visual_aid = input('Does the subject wear a visual aid?? ' , 's'); % input if subject wears visual aid and which type
visual_disabilities = input('Does the subject suffer from any form of visual impairment (e.g. color blindness)?  ' , 's'); % input if subject has visual impairment
expert_viewer = input('Is the subject an expert viewer? ' , 's'); % input if subject is expert viewer
DateOfExperiment = date; % current date of experiment
fname = [subjectsname '_' subjectsage '_' num2str(DateOfExperiment)]; % filename for saving results



%% ---------------------- START OF EXPERIMENTAL RUN ----------------------
input('To start the experiment press a button >>>', 's'); % print to commmand window



try
   
    % call defaults
    PsychDefaultSetup(1) % Execute the AssertOpenGl command & KbName('unifyKeyNames')
    Screen('Preference', 'VBLTimestampingMode', 2);  % Beamposition will be used (cross-check with kernel-level/CoreVideo timestamps).
                                                     % Noisy stamps in case of failure of beamposition mode.
    
    ScreenTest(); % test hardware/software configuration
    VBLSyncTest(); % test syncing of PTB to the VBL
    PerceptualVBLSyncTest(); % test syncing of Screen('Flip')
    
    %% Setup screens
    getScreens = Screen('Screens'); % Gets screens, 0=primary, 1=external
    chosenScreen = 0; % use internal monitor
    rect = []; % full screen
    
    %% Setup keyboard
    KbName('UnifyKeyNames');
    
    % Specify key names of interest for the study: left-arrow (left patch is perceived as brighter), 
    % right-arrow (right patch is perceived as brighter), up-arrow ||
    % down-arrow (perceived as equally bright)
    activeKeys = [KbName('LeftArrow') KbName('RightArrow') KbName('DownArrow') KbName('UpArrow') KbName('Return') KbName('space')];
    
    % restrict the keys for keyboard input to the keys defined in
    % activeKeys
    RestrictKeysForKbCheck(activeKeys);
    
    % suppress displaying key-output in the command line for keypresses
    ListenChar(2);

    
    %% Screen informations
    % Get luminance values
    white = WhiteIndex(chosenScreen); %255
    black = BlackIndex(chosenScreen); %0
    grey = white/2;
    
    % Open a PTB screen
    [w, scr_rect] = PsychImaging('OpenWindow', chosenScreen, grey, rect); % scr_rect gives size of the screen
    HideCursor(); % hide the cursor
    [centerX, centerY] = RectCenter(scr_rect); % get center coordinates of screen
   
    % Get flip and refresh rate
    ifi = Screen('GetFlipInterval', w); % get interframe interval of screen (minimum time between two successive frames) in sec
    fps = FrameRate(w); % check refresh rate of screen
    
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
%% START OF TEST RUN
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
    % display start of test run
    grey_img_test_start = uint8(ones(2160, 3840, 3).*0.18.*255); % generate grey background image
    test_start_info_tex = Screen('MakeTexture', w, grey_img_test_start); % convert the image into texture
    Screen('Textsize', w, 70); % set text size 
    Screen('DrawTexture', w, test_start_info_tex, [], [centerX-1920 centerY-1080  centerX+1920 centerY+1080], 0); % draw texture
    DrawFormattedText(w, 'Test run with 5 sequences. Press key to start test run.' , 'center', 'center', [255, 255, 255]); % info text
    Screen('Flip', w); % flip texture to output monitor
    KbWait; % wait for keyboard input
    Screen('Close',test_start_info_tex); % close texture
     
    % Get current path and subfolders for test-run
    folderPath_test = 'C:\Users\student\Documents\DavidKovacs\Masterarbeit_HFR_luminance\Experiment_test_run\';
    subfolders_test = dir(fullfile(folderPath_test)); % list of subfolders
    subfolders_test = subfolders_test(~ismember({subfolders_test.name},{'.','..'})); % delete dots in folder list
    
    
    shuffle_index_test = 1:length(subfolders_test);
    shuffled_index_test = Shuffle(shuffle_index_test); % shuffle folder index
    for d = shuffled_index_test % iterate over shuffled indices
        
        current_path_test = [folderPath_test subfolders_test(d).name '\']; % generate current path in this iteration
        %%-----------------------SET DATATYPE OF FRAMES----------------------------------------
        getImage_test = dir(fullfile(current_path_test, '*.tiff')); % list of of all tiff-files in the folder

        choseImage_test = 1:length(getImage_test); % number of images
        
        imageTex_test = {}; % create/reset variable to store image textures
        
        for e = choseImage_test 
            chosenImage_test = getImage_test(e).name; % get the name of the current image
            imagePath_test = [current_path_test  chosenImage_test]; % get the full path for the current image
            imageTex_test{e} = Screen('MakeTexture', w, imread(imagePath_test));% convert the image into texture
        end

        %% Setup img size and placement on display
        % Orientation: top-left-x to top-left-y to bottom-right-x to
        % bottom-right-y
        img_size_test = size(imread(imagePath_test)); % get image dimensions of last converted image to texture
        imageLength_test = img_size_test(2); % set image length
        imageHeight_test = img_size_test(1); % set image height
        
        imageDims_test = [centerX-imageLength_test/2 centerY-imageHeight_test/2  centerX+imageLength_test/2 centerY+imageHeight_test/2]; % display image in the center of full screen 
        %% Setup timing and interaction variables
      
        % Time stamp at the beginning of the displaying to evaluate how long it took until key is pressed  
        startTime_test = GetSecs;
    
        % Flag for backup that terminates loop if no key was pressed after
        % 30sec
        timeout_test = false;
        t2wait_test = 60; % time to wait until abortion
    
        %% Draw images
        while ~timeout_test 
            % check if key pressed specified in activeKeys
            [keyIsDown, keyTime, keyCode] = KbCheck;
        
            % iterate over chosenImages
            for f = choseImage_test
            Screen('DrawTexture', w, imageTex_test{f}, [], imageDims_test, 0);
            Screen('Flip', w);  
            end
        
            % if key is pressed break the while loop
            if(keyIsDown), break; end
        
            % backup if no key is pressed, abort
            % displaying after e.g. 60 sec
            if((keyTime - startTime_test) > t2wait_test), timeout_test = true; end 
        end


    
        % reset the keyboard input checking for all keys
        RestrictKeysForKbCheck;
    
        % re-enable displaying key-output in the command line for keypresses
        % !!! IN CASE OF CODE CRASH BEFORE THIS POINT: CTRL-C reenables keyboard input !!! 
        ListenChar(1)

        %% Display end info of current stimulus and wait for keyboard press 

        grey_img_test = uint8(ones(2160, 3840, 3).*0.18.*255); % generate grey background image 
        cylcus_end_info_tex_test = Screen('MakeTexture', w, grey_img_test); % convert the image into texture
        Screen('Textsize', w, 50); % set text size
        Screen('DrawTexture', w, cylcus_end_info_tex_test, [], [centerX-1920 centerY-1080  centerX+1920 centerY+1080], 0);
        DrawFormattedText(w, 'End of current sequence. Please wait for next sequence.' , 'center', 'center', [255, 255, 255]);
        Screen('Flip', w);
        WaitSecs(5); % wait for 5 sec before showing next sequence

        
        % Close all textures of current presentation
        for g = 1:length(imageTex_test)
            Screen('Close', imageTex_test{g});
        end
        Screen('Close',cylcus_end_info_tex_test);
        
    end
    % display end of test run
     grey_img_test_end = uint8(ones(2160, 3840, 3).*0.18.*255); % generate grey background image 
     test_end_info_tex = Screen('MakeTexture', w, grey_img_test_end); % convert the image into texture
     Screen('Textsize', w, 70);
     Screen('DrawTexture', w, test_end_info_tex, [], [centerX-1920 centerY-1080  centerX+1920 centerY+1080], 0);
     DrawFormattedText(w, 'End of test run. Press key to start experimental run.' , 'center', 'center', [255, 255, 255]);
     Screen('Flip', w);
     KbWait;
     Screen('Close',test_end_info_tex);
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
%% START OF EXPERIMENT
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

%% Enter path with subfolders
    
    % Get current path and subfolders
    folderPath = 'C:\Users\student\Documents\DavidKovacs\Masterarbeit_HFR_luminance\Experiment_selection\';
    subfolders = dir(fullfile(folderPath)); % list of subfolders
    subfolders=subfolders(~ismember({subfolders.name},{'.','..'})); % delete dots in folder list
    
    
    shuffle_index = 1:length(subfolders);
    shuffled_index = Shuffle(shuffle_index); % shuffle folder index
    
    % initialize result table
    sz = [length(subfolders), 4 ];
    varTypes = {'string', 'string', 'double', 'logical'};
    varNames = {'Sequence Name', 'Key Name' , 'Key Time', 'Timed out'};
    results = table('Size', sz, 'VariableTypes',varTypes,'VariableNames',varNames);
    rowIndex = 1; % index for current row to fill in results
  
    current_iteration = 1; % variable that tracks current iteration to save temporary file every 10 iterations

    for ii = shuffled_index % iterate over shuffled indices
        
        current_path = [folderPath subfolders(ii).name '\']; % generate current path in this iteration
        current_sequence_name = subfolders(ii).name; % save current folder-name as variable
        
        results(rowIndex,1) = {current_sequence_name}; % save current sequence name to table row
       
        %%-----------------------SET DATATYPE OF FRAMES---------------------------------------
        getImage = dir(fullfile(current_path, '*.tiff')); % list of ns of all tiff-files in the folder

        choseImage = 1:length(getImage); % number of images
        
        imageTex = {}; % create/reset variable to store image textures
        
        for l = choseImage 
            chosenImage = getImage(l).name; % get the name of the current image
            imagePath = [current_path  chosenImage]; % get the full path for the current image
            imageTex{l} = Screen('MakeTexture', w, imread(imagePath));% convert the image into texture
        end

        %% Setup img size and placement on display
        % Orientation: top-left-x to top-left-y to bottom-right-x to
        % bottom-right-y
        img_size = size(imread(imagePath)); % get image dimensions of last converted image to texture
        imageLength = img_size(2); % set image length
        imageHeight = img_size(1); % set image height
        
        imageDims = [centerX-imageLength/2 centerY-imageHeight/2  centerX+imageLength/2 centerY+imageHeight/2]; % display image in the center of full screen 
        %% Setup timing and interaction variables
      
        % Time stamp at the beginning of the displaying to evaluate how long it took until key is pressed  
        startTime = GetSecs;
    
        % Flag for backup that terminates loop if no key was pressed after
        % e.g. 60sec
        timeout = false;
        t2wait = 60; % time to wait until abortion
    
        % Variables that save the reaction time, keyCode and keyName of
        % response
        resp.ReacT = NaN; 
        resp.keyCode = []; 
        resp.keyName = [];
      
        %% Draw images
        while ~timeout
            % check if key pressed specified in activeKeys
            [keyIsDown, keyTime, keyCode] = KbCheck;
        
            % iterate over chosenImages
            for j = choseImage
            Screen('DrawTexture', w, imageTex{j}, [], imageDims, 0);
            Screen('Flip', w);
            end
        
            % if key is pressed break the while loop
            if(keyIsDown), break; end
        
            % backup if no key is pressed, abort displaying after e.g. 60sec
            if((keyTime - startTime) > t2wait), timeout = true; end 
        end

        % Store interaction values if key was pressed
        if(~timeout)
            resp.ReacT = keyTime - startTime;
            resp.keyCode = keyCode;
            resp.keyName = KbName(resp.keyCode);
        end
    
        % reset the keyboard input checking for all keys
        RestrictKeysForKbCheck;
    
        % re-enable displaying key-output in the command line for keypresses
        % !!! IN CASE OF CODE CRASH BEFORE THIS POINT: CTRL-C reenables keyboard input !!! 
        ListenChar(1)
        
        % Save response values
        results(rowIndex, 2) = {resp.keyName}; % save name of pressed key to table
        results(rowIndex, 3)= {resp.ReacT}; % save the reaction time to table
        results(rowIndex, 4) = {timeout}; % save if timed out 
        
        rowIndex = rowIndex +1; % update rowIndex to next row
        %% Display end info of current stimulus and wait for keyboard press 
        grey_img = uint8(ones(2160, 3840, 3).*0.18.*255); % generate grey background image
        cylcus_end_info_tex = Screen('MakeTexture', w, grey_img); % convert the image into texture
        Screen('Textsize', w, 70); % set text size
        Screen('DrawTexture', w, cylcus_end_info_tex, [], [centerX-1920 centerY-1080  centerX+1920 centerY+1080], 0);
        DrawFormattedText(w, 'End of current sequence. Please wait for next sequence.' , 'center', 'center', [255, 255, 255]);
        Screen('Flip', w);
        WaitSecs(5); % wait 5 sec before showing next sequence
        
        
        % Close all textures of current presentation
        for k = 1:length(imageTex)
            Screen('Close', imageTex{k});
        end
        Screen('Close',cylcus_end_info_tex);
        
        % Save temporary result in every 10th iteration
        if ~mod(current_iteration, 10)
           tmp_fname = ['temp_result_' subjectsname '_' subjectsage '_' num2str(GetSecs) '.mat']; % 
           tmp_data_path = ['./data/temp_data/' tmp_fname '.mat'];
           save(tmp_data_path, 'subjectsname', 'subjectsage', 'subjectsgender', ... 
                           'visual_aid', 'visual_disabilities',  'expert_viewer', 'DateOfExperiment', 'results');
        
        end
        
        current_iteration = current_iteration+1; 
    end
    ShowCursor; %show cursor
    %% Save experiment parameters

    sca; % close all screens   
    disp('============================ Additional data regarding HFR experience ==============================================')

    hfr_experience = input('Has the subject had any experience with HFR? ','s'); % input HFR experience
    hfr_type = input('Type of consumed HFR (film, gaming, ...) ','s'); % input HFR type
    
    
    
    result_data_path = ['./data/' fname '.mat']; % path for storing results
    save(result_data_path, 'subjectsname', 'subjectsage', 'subjectsgender', ... 
                'visual_aid', 'visual_disabilities', 'expert_viewer', 'DateOfExperiment', 'results', 'hfr_experience', 'hfr_type'); % save experimental data as .mat
            
    disp('============================ End of experiment ============================');
catch
    
    
end
