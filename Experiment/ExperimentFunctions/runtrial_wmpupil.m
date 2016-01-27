function [ w, el, response, rt, abort, gotosetup, invalid ] = runtrial_wmpupil( w, el, tx, p, dummymode, trialnum, condition, stimparams, itrial, practice )
%% Run trials for working memory and pupil experiment
% Input
%   - w             windowpointer
%   - el            eyelinkpointer
%   - tx            struct with all relevant texturepointers
%   - p             struct with all parameters (fields for different items)
%   - dummymode     logical whether to enter dummymode (i.e. without eyetracker)
%   - trialnum      trialnumber, integer
%   - condition     condition name, string
%   - stimparams    all trialspecific stimulus parameters, vector
%                   1. visual field
%                   2. black and white layout (1=BW, 2=WB)
%                   3. theta stimulus 1
%                   4. orientation stimulus 1
%                   5. theta stimulus 2
%                   6. orientation stimulus 2
%                   7. desired response
%
% Output
%   - response      logical, correct (1) or incorrect (0), or invalid (-1)
%   - rt            manual reaction time
%   - abort         logical, 1 = quit from experiment
%   - gotosetup     logical, 1 = go to eyelink setup
%   - invalid       logical, 1 = invalid eye position detected, abort trial

%% Trial initialization
% output variables (preallocation)
response  = -999;  % correct/incorrect
rt        = -999;  % response time since transient onset
invalid   = 0;     % check: invalid gaze position
abort     = false; % check: abort-key pressed
gotosetup = false; % check: go-to-setup-key pressed


% stimulus location
stimulusBaserect = [ p.scr.cx - p.stim.r / 2 * p.scr.pixdeg ...
                     p.scr.cy - p.stim.r / 2 * p.scr.pixdeg ...
                     p.scr.cx + p.stim.r / 2 * p.scr.pixdeg ...
                     p.scr.cy + p.stim.r / 2 * p.scr.pixdeg ];
[x1, y1]         = pol2cart( stimparams(3), p.stim.eccen * p.scr.pixdeg );
[x2, y2]         = pol2cart( stimparams(5), p.stim.eccen * p.scr.pixdeg );
stim1rect        = CenterRectOnPointd( stimulusBaserect, p.scr.cx+x1, p.scr.cy-y1 );
switch condition
    case 'L'
        stim2rect = CenterRectOnPointd( stimulusBaserect, p.scr.cx+x2, p.scr.cy-y2 );
    case 'O'
        stim2rect = CenterRectOnPointd( stimulusBaserect, p.scr.cx, p.scr.cy );
end

% background color
if stimparams(2) == 1
     tx_tmpbackground = tx.backgroundBW;
else tx_tmpbackground = tx.backgroundWB;
end


% variable value eyelink msg
if stimparams(1) == stimparams(2)
     msg_bgcolor = 0; 
else msg_bgcolor = 255;
end

switch condition
    case 'L'
        if stimparams(1) == 2 && ( stimparams(3)<0.5*pi && stimparams(5)>1.5*pi ) || ...
                                 ( stimparams(3)>1.5*pi && stimparams(5)<0.5*pi )
            msg_intensity = rad2deg( mod( min(stimparams([3 5])) - max(stimparams([3 5])), 2*pi ) );
        else
            msg_intensity = rad2deg( abs( diff( stimparams([3 5]) ) ) );
        end
    case 'O'
        msg_intensity = abs( diff( stimparams([4 6]) ) );
end



%% Start eyelink
targetdiam = [ p.fix.dInner*p.scr.pixdeg p.fix.dOuter*p.scr.pixdeg ];
if ~dummymode
    
    % drift check
    FlushEvents('keyDown');
    success = EyelinkDoDriftCorrection_wmpupil( el, tx, tx_tmpbackground, p.scr.wrect, p.scr.cx, p.scr.cy, targetdiam, 0);
    if ~success
        FlushEvents('keyDown');
        EyelinkDoTrackerSetup(el);
    end
    WaitSecs(0.1);
    FlushEvents('keyDown');
    
    % start recording
    status = Eyelink('StartRecording');
    while status~=0 % retry when failed the first time
        WaitSecs(0.5);
        errorRecording = Eyelink('CheckRecording');
        if(errorRecording~=0)
            status = Eyelink('StartRecording');
        else status = 0;
        end
    end
    WaitSecs(0.1);
    
    % check if recording correctly
    errorRecording = Eyelink('CheckRecording');
    if(errorRecording~=0)
        warning( 'CheckRecording error, status: %d', errorRecording );
        abort = true;
        return
    end
    
    % get eye that's tracked
    eye_used = Eyelink('EyeAvailable');
    if eye_used == el.BINOCULAR; % if both eyes are tracked
        eye_used = el.LEFT_EYE;  % use left eye
    end
    
    % Eyelink messages
    Eyelink('Message', 'start_trial %d', trialnum);
    Eyelink('Message', 'var condition %s', condition);
    Eyelink('Message', 'var backgroundcolor %d', msg_bgcolor);
    Eyelink('Message', 'var intensity %s', num2str( round( msg_intensity*1000 ) / 1000 ) );
    
    eyelinkScreenMessage = [ condition ' ' num2str(trialnum) ' (' num2str(itrial) ')'];
    Eyelink('Command', [ 'record_status_message "' eyelinkScreenMessage '"']);
    
    % Draw ROI at experiment sceen
    Eyelink( 'Command','clear_screen 0' );
    Eyelink( 'Command','draw_box %d %d %d %d 15', ...
             p.scr.cx - p.fix.rROI * p.scr.pixdeg, ...
             p.scr.cy - p.fix.rROI * p.scr.pixdeg, ...
             p.scr.cx + p.fix.rROI * p.scr.pixdeg, ...
             p.scr.cy + p.fix.rROI * p.scr.pixdeg );
else
    % dummy mode drift correct
    Screen('DrawDots', w, [p.scr.cx;p.scr.cy], targetdiam(2), p.color.blue, [],1);
    Screen('DrawDots', w, [p.scr.cx;p.scr.cy], targetdiam(1), p.color.grey, [],1);
    Screen('Flip', w);
    ShowCursor(w);
    SetMouse(p.scr.cx, p.scr.cy);
    eye_used = 999;
    KbReleaseWait;
    FlushEvents('keyDown');
    KbWait;
end



%% START TRIAL
% Phase 1: adaptation
Screen('DrawTexture', w, tx_tmpbackground,  p.scr.wrect);
Screen('DrawTexture', w, tx.backgroundMask, p.scr.wrect);
Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dOuter * p.scr.pixdeg, p.color.blue', [0 0], 1);
Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dInner * p.scr.pixdeg, p.color.grey,  [0 0], 1);
currentphase = 'adaptation';

tFlip = Screen('Flip',w); % flip
if ~dummymode
    Eyelink('Message', 'start_phase %s', currentphase);
end
drawnew   = true;          % draw next screen offline a.s.a.p. after flip
nextphase = 'sample_stim'; % name of next screen

% Trial loop
while true

    %% Gaze
    % get gaze positions
    if dummymode
        [gx,gy] = GetMouse(w);
    elseif Eyelink('NewFloatSampleAvailable') > 0
        evt = Eyelink('NewestFloatSample');
        gx = evt.gx(1 + eye_used);
        gy = evt.gy(1 + eye_used);
    end
    
    % check if gaze is valid
    if sqrt( (gx-p.scr.cx)^2 + (gy-p.scr.cy)^2 ) > ...
       p.fix.rROI * p.scr.pixdeg  &&  ...
       strcmp( currentphase, 'wmdelay')

        invalid = 1;
        
        Screen('FillRect', w, p.color.grey);
        Screen('DrawTexture', w, tx_tmpbackground,  p.scr.wrect);
        Screen('DrawTexture', w, tx.backgroundMask, p.scr.wrect);
        DrawFormattedText(w, p.text.invalid, 'center', 'center', p.color.red*0.78);
        Screen('Flip',w);
        
        KbWait;
       
        break
    end
       
    
    
    %% Screen
    if drawnew
        
        % background + fixation
        Screen('DrawTexture', w, tx_tmpbackground,  p.scr.wrect);
        Screen('DrawTexture', w, tx.backgroundMask, p.scr.wrect);
        Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dOuter * p.scr.pixdeg, p.color.blue', [0 0], 1);
        Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dInner * p.scr.pixdeg, p.color.grey,  [0 0], 1);
        
        % screen specific
        switch nextphase
            case 'sample_stim'
                Screen('DrawTexture', w, tx.stim1(itrial), [], stim1rect, stimparams(4) );
                tVariation    = max( randn(1)*p.time.adapt_std, p.time.adapt_min );
                tVariation    = min(tVariation, p.time.adapt_max);
                tScreen       = p.time.adaptation + tVariation;
                nextnextphase = 'wmdelay';
                
            case 'wmdelay' 
                tScreen       = p.time.stimulus;
                nextnextphase = 'match_stim';
                
            case 'match_stim'
                Screen('DrawTexture', w, tx.stim2(itrial),[], stim2rect, stimparams(6) );
                tScreen       = p.time.wmdelay;
                nextnextphase = 'respwin';
                
            case 'respwin'
                tScreen       = p.time.stimulus;
                nextnextphase = 'end_trial';
        end
        
        % reset boolean
        drawnew = false;
    end
    
    % flip
    if GetSecs()-tFlip >= tScreen-p.scr.hfi && ~strcmp(nextphase,'end_trial')
        tFlip   = Screen('Flip',w);
        
        if ~dummymode
            Eyelink('Message', 'end_phase %s', currentphase);
            Eyelink('Message', 'start_phase %s', nextphase);
        end
        
        % name of offline screen
        currentphase = nextphase;
        nextphase    = nextnextphase;
        
        % get onset of matching stimulus
        if strcmp( currentphase, 'match_stim' )
            start_rt = tFlip;
        end
        
        % update offline screen
        if ~strcmp(nextphase,'end_trial')
            drawnew = true;
        end
    end
        

    
    %% Keyboard
    % check for key press
    [keyIsDown, timestamp, keyCode] = KbCheck;
    if keyIsDown
        % if multiple keynames use first one
        allKeyNames = KbName(keyCode);
        if iscell(allKeyNames);  keyName = allKeyNames{1};
        else                     keyName = allKeyNames;
        end

        % change variables appropriately
        if ismember(keyName,{'BackSpace','q'})
            abort   = true;
            invalid = 1;
            break
        elseif strcmp(keyName,'ESCAPE')
            gotosetup = true;
            invalid   = 1;
            break
        elseif ismember(keyName,{'LeftArrow','DownArrow'}) && ...
               ismember(currentphase,{'match_stim','respwin'})
            response  = -1 == stimparams(7);
            rt        = round( (timestamp - start_rt) * 1000 );
            break
        elseif ismember(keyName,{'RightArrow','UpArrow'}) && ...
               ismember(currentphase,{'match_stim','respwin'})
            response  = 1 == stimparams(7);
            rt        = round( (timestamp - start_rt) * 1000 );
            break
        end
    end
    
    WaitSecs(0.0005); % PTB goodbøy: døn't rush thrøugh while løøp
    
    
    
end

%% WRAP UP
if ~dummymode
    % send response variables to edf
    Eyelink('Message', 'end_phase %s', currentphase);
    Eyelink('Message', 'var valid %s', num2str(~invalid) );
    Eyelink('Message', 'var response %s', num2str(response) );
    Eyelink('Message', 'var rt %s', num2str(rt) );
    Eyelink('Message', 'end_trial');
    
    % clear experiment screen
    Eyelink( 'Command','clear_screen 0' );
    
    % stop eyelink recording
    WaitSecs(0.1);
    Eyelink('StopRecording');
    WaitSecs(0.1);
end

if practice && ~invalid && ~abort && ~gotosetup
    Screen('DrawTexture', w, tx_tmpbackground,  p.scr.wrect);
    Screen('DrawTexture', w, tx.backgroundMask, p.scr.wrect);
    if response == 1
        Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dOuter * p.scr.pixdeg, p.color.green', [0 0], 1);
    elseif response == 0
        Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dOuter * p.scr.pixdeg, p.color.red', [0 0], 1);
    end
    Screen('DrawDots',    w, [p.scr.cx;p.scr.cy], p.fix.dInner * p.scr.pixdeg, p.color.grey,  [0 0], 1);
    
    Screen('Flip',w);
    WaitSecs(0.4);
end
    