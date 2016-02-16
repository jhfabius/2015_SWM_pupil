% EDF2MAT
% Converts .edf to .asc files

% directories
dir_edf    = [pwd filesep 'edf'];  % .edf files (input)
dir_asc    = [pwd filesep 'data']; % .asc files (output)

% all filenames in .edf-directory
alledf = dir(dir_edf);
alledf = alledf( not( [alledf.isdir] ) );

for i_edf = 1:length(alledf)
    % original filenames
    filename    = alledf(i_edf).name;
    
    % set variants of file names
    edffullname = [dir_edf filesep filename];
    ascname     = [filename(1:end-4) '.asc'];
    
    % .edf to .asc
    if ~exist([dir_asc filesep ascname],'file')
        status = system(['edf2asc ' edffullname]);
        movefile([dir_edf filesep ascname], dir_asc);
        fclose('all');
    end   
end
