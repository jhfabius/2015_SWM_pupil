%% Settings
% Directories
for minimize_directories = 1;

    dir_data      = [fileparts(pwd) filesep 'Data']; % data
    dir_edf       = [dir_data filesep 'edf'];        %  - .edf files
    dir_asc       = [dir_data filesep 'asc'];        %  - .asc files
    dir_eye       = [dir_data filesep 'eye'];        %  - *eye.mat files
    dir_eye_final = [dir_data filesep 'eye_final'];  %  - *_final.mat files
    dir_mat       = [dir_data filesep 'mat'];        %  - .txt files
    dir_params    = [dir_data filesep 'subject'];    %  - .mat files
    
end

triggers             = [ {'start_trial'} {'end_trial'} ];
vars.msg             = [ {'var condition'} {'var backgroundcolor'} {'var intensity'} ...
                         {'var valid'} {'var response'} {'var rt'}];
vars.condition       = {'L','O'};
vars.backgroundcolor = 'numeric';
vars.intensity       = 'numeric';
vars.valid           = 'numeric';
vars.response        = 'numeric';
vars.rt              = 'numeric';

phases               = [ {'adaptation'}, {'sample_stim'}, {'wmdelay'}, {'match_stim'}, {'respwin'} ];
pupilstart           = 'sample_stim';
pupilend             = 'match_stim';
nsampnorm            = 100;


%% EDF2MAT
for minimize_edf2mat = 1;
    % preprocess .edf
    fprintf('Preprocessing .edf\n');
    
    % all filenames in .edf-directory
    alledf = dir(dir_edf);
    alledf = alledf( not( [alledf.isdir] ) );
    
    for i_edf = 1:length(alledf)
        
        % original filenames
        filename    = alledf(i_edf).name;
        
        % set variants of file names
        edffullname = [dir_edf filesep filename];
        ascname     = [filename(1:end-4) '.asc'];
        eyename     = [filename(1:end-4) '_eye.mat'];
        
        % .edf to .asc
        if ~exist([dir_asc filesep ascname],'file')
            status = system(['edf2asc ' edffullname]);
            movefile([dir_edf filesep ascname], dir_asc);
            fclose('all');
        end
        
        %.asc to .mat
        if ~exist([dir_eye filesep eyename],'file')
            fprintf('Extracting saccade data from: %s\n', filename);
            eyedata = asc2mat_pupil([dir_asc filesep ascname], triggers, vars, phases, pupilstart, pupilend, nsampnorm);
            save([dir_eye filesep eyename],'eyedata');
        end
        
    end
end