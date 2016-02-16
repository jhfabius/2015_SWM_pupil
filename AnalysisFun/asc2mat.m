function out = asc2mat(filename,triggers)

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
endTrialLine = triggers{2};
nExtraTriggers = length(triggers)-2;

fid = fopen(filename);
trialID = 1;
flagSaccade = 0;
flagBlink   = 0;
isBlink = false;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break
    end
    nSaccades = 0;
    nBlinks   = 0;
    eyePositionCounter = 0;

    if ~isempty(strfind(tline,startTrialLine))
        string = textscan(tline,'%s %n %s %n %n %s');
        triggersStartTrial(trialID,1) = string{2};
        
        if ~isempty( string{4} )
            triggersTrialNumber(trialID,1) = string{4};
        else
            triggersTrialNumber(trialID,1) = 1;
        end
        
        while isempty(strfind(tline,endTrialLine))
            
            tline = fgetl(fid);
            
            if ~isempty(strfind(tline,'EBLINK'))
                % the end of a blink was detected. The next saccade end
                % will be used to determine blink start and end, as eyelink
                % wraps SBLINK and EBLINK in SSACC and ESSACC.
                isBlink = true;
            end
            
            if isempty(strfind(tline,'ESACC'))
                eyePositionCounter = eyePositionCounter + 1;
                string = textscan(tline,'%d %d %d %d');
                if ~isempty(string{1})
                    time(trialID,eyePositionCounter) = string{1};
                else
                    time(trialID,eyePositionCounter) = 0;
                end
                if ~isempty(string{2})
                    xPos(trialID,eyePositionCounter) = string{2};
                else
                    xPos(trialID,eyePositionCounter) = 0;
                end
                if ~isempty(string{3})
                    yPos(trialID,eyePositionCounter) = string{3};
                else
                    yPos(trialID,eyePositionCounter) = 0;
                end
                
            elseif isBlink
                
                flagBlink = 1;
                string    = textscan(tline,'%s %s %n %n %n %n %n %n %n %n %n');
                nBlinks   = nBlinks + 1;
                isBlink   = false; % at the next line we are not reading about a blink anymore
                
                if ~isempty(string{3})
                    blinkDataFrame(trialID,nBlinks,1) = string{3}; %#ok<*AGROW> % blink onset
                else
                    blinkDataFrame(trialID,nBlinks,1) = 0; % blink onset
                end
                if ~isempty(string{4})
                    blinkDataFrame(trialID,nBlinks,2) = string{4}; %#ok<*AGROW> % blink end
                else
                    blinkDataFrame(trialID,nBlinks,2) = 0; % blink end
                end
                
            else
                flagSaccade = 1;
                string = textscan(tline,'%s %s %n %n %n %n %n %n %n %n %n');
                nSaccades = nSaccades + 1;
                isBlink   = false; % at the next line we are not reading about a blink
                
                % COLLECT DATA
                if ~isempty(string{10})
                    saccadeDataFrame(trialID,nSaccades,1) = string{10};%#ok<*AGROW> % amplitude
                else
                    saccadeDataFrame(trialID,nSaccades,1) = 0;% amplitude
                end
                if ~isempty(string{5}); % duration
                    saccadeDataFrame(trialID,nSaccades,2) = string{5}; % duration
                else
                    saccadeDataFrame(trialID,nSaccades,2) = 0; % duration
                end
                if ~isempty(string{11})
                    saccadeDataFrame(trialID,nSaccades,3) = string{11};% peak velocity
                else
                    saccadeDataFrame(trialID,nSaccades,3) = 0;% peak velocity
                end
                if ~isempty(string{3})
                    saccadeDataFrame(trialID,nSaccades,4) = string{3}; % onset time
                else
                    saccadeDataFrame(trialID,nSaccades,4) = 0; % onset time
                end
                if ~isempty(string{4})
                    saccadeDataFrame(trialID,nSaccades,5) = string{4}; % offset time
                else
                    saccadeDataFrame(trialID,nSaccades,5) = 0; % offset time
                end
                if ~isempty(string{8})
                    saccadeDataFrame(trialID,nSaccades,6) = string{8}; % esacc end x position
                else
                    saccadeDataFrame(trialID,nSaccades,6) = 0; % esacc end x position
                end
                if ~isempty(string{9})
                    saccadeDataFrame(trialID,nSaccades,7) = string{9}; % esacc end y position
                else
                    saccadeDataFrame(trialID,nSaccades,7) = 0; % esacc end y position
                end
                if ~isempty(string{6})
                    saccadeDataFrame(trialID,nSaccades,8) = string{6}; % esacc start x position
                else
                    saccadeDataFrame(trialID,nSaccades,8) = 0; % esacc start x position
                end
                if ~isempty(string{7})
                    saccadeDataFrame(trialID,nSaccades,9) = string{7}; % esacc start y position
                else
                    saccadeDataFrame(trialID,nSaccades,9) = 0; % esacc start y position
                end
            end
            
            % COLLECT TRIGGER ONSETS AND TRIGGER NAMES
            for x = 1:nExtraTriggers
                triggersCounter = x+2;
                if ~isempty(strfind(tline,triggers{triggersCounter}))
                    string = textscan(tline,'%s %n %s %n %s');
                    triggersOnset(trialID,x) = string{2};
                    triggersName(trialID,x) = string{3};                    
                end
            end
        end
        
        string = textscan(tline,'%s %n %s %n %n %s');
        triggersEndTrial(trialID,1) = string{2}; 
        
        % In case no saccades are pefrormed during the trial, 
        % then pad the trial matrix with zeroes;
        if flagSaccade == 0 
            saccadeDataFrame(trialID,:,:) = 0;
        end
        if flagBlink == 0 
            blinkDataFrame(trialID,:,:) = 0;
        end
        output(trialID,1) = trialID;   % trialCounter
        output(trialID,2) = nSaccades; % nSaccades performed after request saccade signal
        trialID = trialID + 1;
        flagSaccade = 0;
        flagBlink   = 0;
    end
   
end
fclose(fid);

out.saccadeDataFrame = saccadeDataFrame;
out.blinkDataFrame   = blinkDataFrame;
if nExtraTriggers > 0
    triggersOnset = cat(2,triggersStartTrial,triggersEndTrial,triggersTrialNumber,triggersOnset);
else
    triggersOnset = cat(2,triggersStartTrial,triggersEndTrial,triggersTrialNumber);
end
out.triggers = triggersOnset;
out.triggersName = triggersName;
out.time = time;
out.xPos = xPos;
out.yPos = yPos;

