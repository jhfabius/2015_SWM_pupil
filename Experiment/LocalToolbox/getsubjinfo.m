function [practice, sessionnumber, initials, condition] = getsubjinfo( dir_subjinfo, dir_data, conditionnames)
% getsubjinfo
% Function to gather subject information and select which condition to run
% Input
%   - dir_subjinfo:   string, specifying where to save subject info
%   - dir_data:       string, specifying where to look for existing  
%                     datafiles of this subject
%   - conditionnames: cell, with strings containing the available
%                     conditions
%
% Output
%   - practice:       logical, true when practicing, false otherwise
%   - sessionnumber:  integer, sessionnumber of participant
%   - initials:       string with subject initials (or 'practice' when
%                     practicing)
%   - condition:      string, name of condition to run

% Condition menu
condition     = questdlg( 'Which condition do you want to run?', ...
                          'Conditions menu',conditionnames{:},conditionnames{1} );
icondition    = ismember(conditionnames,condition);

% Subject initials
prompt1       = {'Initials (2 letters)'};
initials      = inputdlg(prompt1,'Subject',1,{'practice'});

if ~ischar(initials{:}) || ( ~strcmp(initials{:},'practice') && length(initials{:})~=2 )
    error('Wrong input for subject initials (should be 2 letters)')
end

initials      = upper(char(initials));
subj.initials = initials;
subj.filename = [upper(subj.initials) '_info'];
subj.session  = zeros( 1, length(conditionnames) );


% Check if this is a practice session
if strcmp(subj.initials,'PRACTICE')
    practice      = true;
    sessionnumber = 1;

else
    
    % Check if subject participated before
    existingfile = ls( [ dir_data filesep '*' initials '_' condition(1) '*' ] );
    
    if ~isempty( existingfile );
        tmpchoice = questdlg(sprintf(['Files already exist for ' upper(subj.initials) ...
                                      '\nContinue where you left off last time?']),...
                                      'Existing files', 'Continue', 'Cancel', 'Continue');
        
        switch tmpchoice;
            case 'Continue';
                
                try
                    load([dir_subjinfo filesep subj.filename]);
                catch
                    error( sprintf( ['No prior subject information exists.\n' ...
                                     'Yet there are datafiles with the entered initials, to be found in: %s.\n'], ...
                                     dir_data ) );
                end
                
                % update session number
                subj.session( icondition ) = subj.session( icondition ) + 1;

            case 'Cancel';
                error('Experiment aborted by user');
        end
        
    else % first time participation in this condition
        if ~exist([dir_subjinfo filesep subj.filename '.mat'],'file');
            prompt2 = {'Age','Sex (f = 0 | m = 1)'};
            answers = inputdlg(prompt2,'Subject',1,{'99','0'});
            subj.age                   = str2double(answers{1});
            subj.sex                   = str2double(answers{2});
            subj.session( icondition ) = 1;
        else
            try
                load([dir_subjinfo filesep subj.filename]);
            catch
                error( sprintf( ['No prior subject information exists.\n' ...
                    'Yet there are datafiles with the entered initials, to be found in: %s.\n'], ...
                    dir_data ) );
            end
            
            % update session number
            subj.session( icondition ) = subj.session( icondition ) + 1;
        end
    end
    
    % set output variables
    practice      = false;
    sessionnumber = subj.session( icondition );
    
    % save all subject info
    save([dir_subjinfo filesep subj.filename],'subj');
    
end


end