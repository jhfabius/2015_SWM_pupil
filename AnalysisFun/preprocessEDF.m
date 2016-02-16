%-------------------------------------------------------------------------%
%                             .EDF to .MAT                                %
%-------------------------------------------------------------------------%
% out.saccadeDataFrame
%   1. amplitude
%   2. duration
%   3. peak velocity
%   4. onset time
%   5. offset time
%   6. end x
%   7. end y
%   8. start x
%   9. start y
for minimize_edf2mat = 1;
    
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



%-------------------------------------------------------------------------%
%                             GET PUPIL DATA                              %
%-------------------------------------------------------------------------%
for minimize_eyeAnalysis = 1;
    
% eyedir content
alleye = dir(dir_eye);
alleye = alleye( not( [alleye.isdir] ) );
isubj  = 1;

for i_mat = 1:length(alleye)
    
    if exist('initials','var')
        prev_initials  = initials;
        prev_condition = condition;
    end
    
    % original filenames
    filename  = alleye(i_mat).name;
    initials  = filename(1:2);
    condition = filename(4);
    
    % check if a file already exists for this subject
    if ~exist([dir_eye_final filesep initials '_final.mat'],'file')
        
        if exist('allinitials','var')
            allinitials = [ allinitials{:}, {initials} ];
        else allinitials = { initials };
        end
        
        if exist('prev_initials','var') && ~strcmp( initials, prev_initials)
            isubj = isubj + 1;
        end
        
        % load data
        if exist('eyedata','var'); clear eyedata out; end
        load([dir_eye filesep filename]);
        out = eyedata;
        
        % preallocate some arrays
        saccadeOnsetArray     = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        saccadeOffsetArray    = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        saccadeAmplitudeArray = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        saccadeDurationArray  = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        saccadePeakArray      = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        startXArray           = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        startYArray           = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        endXArray             = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        endYArray             = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        keepTrialArray        = zeros(1,size(out.saccadeDataFrame,1)) + 999;
        
        % set more variables
        startTrial = out.triggers(:,1);
        if size(out.triggers,2) > 4
            
            reqSaccadeArray = out.triggers(:,6);
            
            for trial = 1:size(out.saccadeDataFrame,1)
                
                if size(out.triggers,2) >= 9 && out.triggers(trial,10) == 0 % check if trial was completed
                    
                    flagTrial = 0;
                    for saccade = 1:size(out.saccadeDataFrame,2)
                        if flagTrial == 0 && length( out.saccadeDataFrame(trial,saccade,:) ) > 1
                            reqSaccade = out.triggers(trial,5);
                            saccOnset = out.saccadeDataFrame(trial,saccade,4);
                            saccOffset = out.saccadeDataFrame(trial,saccade,5);
                            saccAmplitude = out.saccadeDataFrame(trial,saccade,1);
                            saccDuration = out.saccadeDataFrame(trial,saccade,2);
                            saccPeak = out.saccadeDataFrame(trial,saccade,3);
                            startX = out.saccadeDataFrame(trial,saccade,8);
                            startY = out.saccadeDataFrame(trial,saccade,9);
                            endX = out.saccadeDataFrame(trial,saccade,6);
                            endY = out.saccadeDataFrame(trial,saccade,7);
                            if ( saccOnset-reqSaccade ) > onsetThr && saccAmplitude > ampThr;
                                flagTrial = 1;
                                keepTrialArray(trial) = flagTrial;
                                saccadeOnsetArray(trial) = saccOnset;
                                saccadeOffsetArray(trial) = saccOffset;
                                saccadeAmplitudeArray(trial) = saccAmplitude;
                                saccadeDurationArray(trial) = saccDuration;
                                saccadePeakArray(trial) = saccPeak;
                                startXArray(trial) = startX;
                                startYArray(trial) = startY;
                                endXArray(trial) = endX;
                                endYArray(trial) = endY;
                            end
                        elseif length( out.saccadeDataFrame(trial,saccade,:) ) == 1 && strcmp(condition,'F')
                            flagTrial = 1;
                        end
                    end
                end
            end
            
            % check if at any trial a response was collected
            switch condition
                case 'S'
                    if size(out.triggers,2) >= 9
                        filterSacc = keepTrialArray' == 999 | out.triggers(:,10) ~= 0;
                    else
                        filterSacc = ones( size(out.triggers,1), 1 );
                    end
                    
                case 'F'
                    if size(out.triggers,2) >= 9
                        filterSacc = keepTrialArray' ~= 999 | out.triggers(:,10)~=0;
                    else
                        filterSacc = ones( size(out.triggers,1), 1 );
                    end
            end
            
            % fixation stability: sqrt( (x-median(x))^2 + (y-median(y))^2 )
            MAD_ind    = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            MAD_trn    = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            xMedianPre = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            yMedianPre = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            xMedianTrn = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            yMedianTrn = zeros(1,size(out.saccadeDataFrame,1)) + 999;
            switch condition
                case 'S'
                    for itrial = 1:size(out.saccadeDataFrame,1);
                        
                        if filterSacc(itrial) == 0  &&  size(out.triggers,2) >= 9
                            
                            % timestamps
                            inducerPreOnset = out.triggers(itrial,5);
                            cueOnset        = out.triggers(itrial,6);
                            transOnset      = out.triggers(itrial,8);
                            rwOnset         = out.triggers(itrial,9);
                            
                            % gaze coordinates during inducer
                            xPre = double( out.xPos( itrial, out.time(itrial,:) >= inducerPreOnset & out.time(itrial,:) < cueOnset ) );
                            yPre = double( out.yPos( itrial, out.time(itrial,:) >= inducerPreOnset & out.time(itrial,:) < cueOnset ) );
                            tPre = double( out.time( itrial, out.time(itrial,:) >= inducerPreOnset & out.time(itrial,:) < cueOnset ) );
                            
                            % gaze coordinates during transient
                            xTrans = double( out.xPos( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            yTrans = double( out.yPos( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            tTrans = double( out.time( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            
                            % filter blinks
                            if any( out.blinkDataFrame(itrial,:,1) ~= 0 )
                                for iblink = 1:size(out.blinkDataFrame,2)
                                    blinkOnset  = out.blinkDataFrame( itrial, iblink, 1);
                                    blinkOffset = out.blinkDataFrame( itrial, iblink, 2);
                                    
                                    if any( tPre >= blinkOnset & tPre <= blinkOffset )
                                        xPre = xPre( tPre < blinkOnset | tPre > blinkOffset );
                                        yPre = yPre( tPre < blinkOnset | tPre > blinkOffset );
                                        tPre = tPre( tPre < blinkOnset | tPre > blinkOffset );
                                    end
                                    if any( tTrans >= blinkOnset & tTrans <= blinkOffset )
                                        xTrans = xTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                        yTrans = yTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                        tTrans = tTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                    end
                                end
                            end
                            
                            % remove padding zeros
                            xPre = xPre( xPre ~= 0);
                            yPre = yPre( yPre ~= 0);
                            xTrans = xTrans( xTrans ~= 0);
                            yTrans = yTrans( yTrans ~= 0);
                            
                            % median gaze positions and stability
                            xMedianPre(itrial) = median(xPre);
                            yMedianPre(itrial) = median(yPre);
                            xMedianTrn(itrial) = median(xTrans);
                            yMedianTrn(itrial) = median(yTrans);
                            MAD_ind(itrial)    = median( sqrt( ( xPre-median(xPre) ).^2 + ( yPre-median(yPre) ).^2 ) );
                            MAD_trn(itrial)    = median( sqrt( ( xTrans-median(xTrans) ).^2 + ( yTrans-median(yTrans) ).^2 ) );
                            
                        else
                            xMedianPre(itrial) = 999;
                            yMedianPre(itrial) = 999;
                            xMedianTrn(itrial) = 999;
                            yMedianTrn(itrial) = 999;
                            MAD_ind(itrial)    = 999;
                            MAD_trn(itrial)    = 999;
                        end
                    end
                case 'F'
                    for itrial = 1:size(out.saccadeDataFrame,1);
                        if filterSacc(itrial) == 0  &&  size(out.triggers,2) >= 9
                            
                            % timestamps
                            inducerOnset = out.triggers(itrial,7);
                            transOnset   = out.triggers(itrial,8);
                            rwOnset      = out.triggers(itrial,9);
                            
                            % if response was made during transient already we
                            % use the time of the response
                            if rwOnset == 0 && out.triggers(itrial,11) ~= 0
                                rwOnset = out.triggers(itrial,11);
                            elseif rwOnset == 0 && out.triggers(itrial,12) ~= 0
                                rwOnset = out.triggers(itrial,12);
                            end
                            
                            % gaze coordinates during inducer
                            if inducerOnset ~= 0
                                xPre = double( out.xPos( itrial, out.time(itrial,:) >= inducerOnset & out.time(itrial,:) < transOnset ) );
                                yPre = double( out.yPos( itrial, out.time(itrial,:) >= inducerOnset & out.time(itrial,:) < transOnset ) );
                                tPre = double( out.time( itrial, out.time(itrial,:) >= inducerOnset & out.time(itrial,:) < transOnset ) );
                            end
                            
                            % gaze coordinates during transient
                            xTrans = double( out.xPos( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            yTrans = double( out.yPos( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            tTrans = double( out.time( itrial, out.time(itrial,:) >= transOnset & out.time(itrial,:) < rwOnset ) );
                            
                            % filter blinks
                            if any( out.blinkDataFrame(itrial,:,1) ~= 0 )
                                for iblink = 1:size(out.blinkDataFrame,2)
                                    blinkOnset  = out.blinkDataFrame( itrial, iblink, 1);
                                    blinkOffset = out.blinkDataFrame( itrial, iblink, 2);
                                    
                                    if any( tPre >= blinkOnset & tPre <= blinkOffset ) && inducerOnset ~= 0
                                        xPre = xPre( tPre < blinkOnset | tPre > blinkOffset );
                                        yPre = yPre( tPre < blinkOnset | tPre > blinkOffset );
                                        tPre = tPre( tPre < blinkOnset | tPre > blinkOffset );
                                    end
                                    if any( tTrans >= blinkOnset & tTrans <= blinkOffset )
                                        xTrans = xTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                        yTrans = yTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                        tTrans = tTrans( tTrans < blinkOnset | tTrans > blinkOffset );
                                    end
                                end
                            end
                            
                            % remove padding zeros
                            if inducerOnset ~= 0
                                xPre = xPre( xPre ~= 0);
                                yPre = yPre( yPre ~= 0);
                            end
                            xTrans = xTrans( xTrans ~= 0);
                            yTrans = yTrans( yTrans ~= 0);
                            
                            % median gaze positions and stability
                            xMedianTrn(itrial) = median(xTrans);
                            yMedianTrn(itrial) = median(yTrans);
                            MAD_trn(itrial)    = median( sqrt( ( xTrans-median(xTrans) ).^2 + ( yTrans-median(yTrans) ).^2 ) );
                            if inducerOnset ~= 0
                                xMedianPre(itrial) = median(xPre);
                                yMedianPre(itrial) = median(yPre);
                                MAD_ind(itrial)    = median( sqrt( ( xPre-median(xPre) ).^2 + ( yPre-median(yPre) ).^2 ) );
                            else
                                xMedianPre(itrial) = 999;
                                yMedianPre(itrial) = 999;
                                MAD_ind(itrial)    = 999;
                            end
                            
                        else
                            MAD_ind(itrial)    = 999;
                            MAD_trn(itrial)    = 999;
                            xMedianPre(itrial) = 999;
                            yMedianPre(itrial) = 999;
                            xMedianTrn(itrial) = 999;
                            yMedianTrn(itrial) = 999;
                        end
                    end
            end
            
            
            % add to final array
            switch condition
                case 'S'
                    if size(out.triggers,2) >= 7
                        tmparray = [ out.triggers(:,3) filterSacc...
                                     out.triggers(:,4:8) ...
                                     saccadeOnsetArray' saccadeOffsetArray' ...
                                     saccadeAmplitudeArray' ...
                                     out.triggers(:,7) - saccadeOffsetArray' ...
                                     out.triggers(:,8) - saccadeOffsetArray' ...
                                     startXArray' startYArray' ...
                                     endXArray' endYArray' ...
                                     xMedianPre' yMedianPre' MAD_ind' ...
                                     xMedianTrn' yMedianTrn' MAD_trn'];
                    else
                        tmparray = [ out.triggers(:,3) 1 repmat(999, 1, 16)];
                    end
                    
                case 'F'
                    if size(out.triggers,2) >= 7
                        tmparray = [ out.triggers(:,3) filterSacc ...
                                     out.triggers(:,4:8) ...
                                     xMedianPre' yMedianPre' MAD_ind' ...
                                     xMedianTrn' yMedianTrn' MAD_trn'];
                    else
                        tmparray = [ out.triggers(:,3) 1 repmat(999, 1, 9)];
                    end
            end
            
        else
            ntrialstmp = size(out.triggers(:,3),1);
            if strcmp(condition,'S')
                tmparray = [ out.triggers(:,3) ones(ntrialstmp,1) repmat(999, ntrialstmp, 18-2)];
            elseif strcmp(condition,'F');
                tmparray = [ out.triggers(:,3) ones(ntrialstmp,1) repmat(999, ntrialstmp, 11-2)];
            end
        end
        
        
        if exist('prev_initials','var') && strcmp( condition, prev_condition )
            eval( ['final(' num2str(isubj) ').' condition ' = '  ...
                 '[ final(' num2str(isubj) ').' condition '; tmparray ]; ' ] );
        else
            eval( [ 'final(' num2str(isubj) ').' condition ' = tmparray; ' ] );
            eval( [ 'final(' num2str(isubj) ').name = initials; ' ] );
        end
        
    else
        if ~exist('prev_initials','var') || ~strcmp(initials,prev_initials)
            fprintf('Final file already existed for subject %s\n',initials);
        end
    end
end

end



%-------------------------------------------------------------------------%
%                           SAVE SACCADE DATA                             %
%-------------------------------------------------------------------------%
if exist('final','var')
    for isubj = 1:size(final,2)
        final_F     = final(isubj).F;
        final_S     = final(isubj).S;
        newfilename = [dir_eye_final filesep final(isubj).name '_final'];
        
        save(newfilename,'final_S','final_F');
    end
end

