function out = asc2mat_pupil(filename, triggers, vars, phases, pupilstart, pupilend, nsampnorm)

% input: 
%     filename: ascii eyelink output
%     triggers: cell array with the first two strings: start & end trial triggers
%               further triggers are added subsequently;
% output:
%     structure 'out' with fields:
%           saccadeDataFrame: trials x saccades x saccades information  
%           triggers: trials x triggers onset times
%           triggersName: trials x trigger name excluding start and end triggers
% EXAMPLE CALL:
% filename = '11.asc';
% triggers = [{'startTrial'} {'endTrial'} {'reqSaccade'} {'line'}];
% out = analysisEyeMovements(filename,triggers);
startTrialLine = triggers{1};
endTrialLine   = triggers{2};

varnames = fieldnames(vars);
nvars    = size( varnames, 1 ) - 1;

fid     = fopen(filename);
trialID = 0;
while 1
    
    % read next line
    tline = fgetl(fid);
    if ~ischar(tline), break
    end

    % if line indicates trialstart
    if ~isempty(strfind(tline,startTrialLine))
            
        % read next line
        cellstr = textscan(tline,'%s %n %s %n %n %s');
        
        % set trial ID
        trialID  = trialID + 1;
        trialnum = cellstr{4};
        
        % save trialnumber and start-time of trial
        out.info(trialID,:)   = [ trialnum zeros(1,nvars) ];
        out.tphase(trialID,1) = trialnum;
        out.tphase(trialID,2) = cellstr{2};
        
        % reset temporary pupil and time variables
        p      = [];
        t      = [];
        tstart = [];
        tend   = [];
        
        while isempty(strfind(tline,endTrialLine))
            
            % read next line
            tline = fgetl(fid);
            
            if ~isempty(strfind(tline,'var')) || ...
               ~isempty(strfind(tline,'start_phase')) || ...
               ~isempty(strfind(tline,'end_phase'))
                
                % get values of variables
                cellstr = textscan(tline,'%s %n %s %s %s');
                
                % check for variables
                if isfield(vars,cellstr{4})
                    varvalues = getfield( vars, char( cellstr{4} ) );
                    varidx    = find( ismember(varnames,cellstr{4})) - 1; 

                    if strcmp(varvalues,'numeric')
                        cellstr = textscan(tline,'%s %n %s %s %n');
                        out.info(trialID,varidx+1) = cellstr{5};
                    else
                        out.info(trialID,varidx+1) = find( ismember(varvalues,cellstr{5}) );
                    end
                end
                
                % check for phase start
                if any( ismember(phases,cellstr{4}) )
                    phaseidx = find( ismember(phases,cellstr{4}) );
                    out.tphase(trialID, 3+phaseidx ) = cellstr{2};
                    
                    if strcmp( cellstr{4}, pupilstart );
                        tstart = cellstr{2};
                    elseif strcmp( cellstr{4}, pupilend );
                        tend   = cellstr{2};
                    end
                end
                
            else % get pupil size
                cellstr = textscan(tline,'%n %n %n %n');
                if isempty(cellstr{1}) || isempty(cellstr{4})
                    fprintf('Hold  up t = %d p = %d\n',cellstr{1},cellstr{4});
                end
                t = [ t cellstr{1} ];
                p = [ p cellstr{4} ];
                
            end
        end
        
        % save trial end
        cellstr = textscan(tline,'%s %n %s %n %n %s');
        out.tphase(trialID,3) = cellstr{2}; 
        
        if ~isempty(tend) 
            % normalize pupil trace
            istart = find(t==tstart);
            iend   = find(t==tend);
            pnorm  = p(istart:iend);
            pnorm  = pnorm ./ median( p(istart-nsampnorm:istart-1) );
            tnorm  = t(istart:iend);
        
            % number of pupil samples per trial in current array
            if isfield(out,'pupil')
                nsamp = size(out.pupil,2) - 1;
            else
                nsamp = 1;
            end
            
            % save to array
            if ~isfield(out,'pupil') 
                out.pupil = [trialnum pnorm];
                
            elseif length(pnorm) == nsamp
                out.pupil = [ out.pupil; ...
                              trialnum pnorm ];
                
            elseif length(pnorm) < nsamp
                ndiff     = (size(out.pupil,2)-1) - length(pnorm);
                out.pupil = [ out.pupil; ...
                              trialnum pnorm NaN(1,ndiff) ];
                
            elseif length(pnorm) > nsamp
                ndiff     = length(pnorm) - nsamp;
                ntrials   = size(out.pupil,1);
                out.pupil = [ out.pupil NaN(ntrials,ndiff) ];
                out.pupil = [ out.pupil; ...
                              trialnum pnorm ];
            end
            
        elseif isfield(out,'pupil')
            out.pupil = [ out.pupil;...
                          trialnum NaN(1,nsamp) ];
        else
            out.pupil = [trialnum NaN];
        end
    end
   
end
fclose(fid);

