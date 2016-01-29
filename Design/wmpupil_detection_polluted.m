clear all; close all; clc;
%-------------------------------------------------------------------------%
% Working memory X pupil
%-------------------------------------------------------------------------%
% Format data array
%    1. blocknumber
%    2. trialnumber
%    3. visual field
%    4. black-white layout of background
%    5. theta of stimulus 1
%    6. orientation of stimulus 1
%    7. theta of stimulus 2
%    8. orientation of stimulus 2
%    9. desired response
%   10. intensity (difference between theta1 and theta2 or between ori1 and ori2)
%   11. response
%   12. response time
%   13. which staircase was used?
%   14. threshold estimate
%   15. standard deviation of estimate
%   16. invalid (logical)

% dummymode ( = use mouse instead of eye-tracker)
dummymode = true;




%%  Initialize experiment
% folder with some extra helper functions
addpath([pwd filesep 'LocalToolbox']);
addpath([pwd filesep 'ExperimentFunctions']);

% folders for data storage
edfdir  = [fileparts(pwd) filesep 'Data' filesep 'edf'];
matdir  = [fileparts(pwd) filesep 'Data' filesep 'mat'];
subjdir = [fileparts(pwd) filesep 'Data' filesep 'subjects'];

% randomization
randseed = sum(clock);
try
    rng('default');
    rng( randseed );
catch
    rand('twister', randseed );
end



%% Subject and session info
[practice, sessionnumber, initials, conditionfull] = getsubjinfo( subjdir, edfdir, {'location','orientation'} );
condition = upper( conditionfull(1) );
fileprfx  = [ initials '_'  condition ];

if sessionnumber > 1
    try
        load( [ matdir filesep initials '_'  condition num2filestr(sessionnumber-1) '.mat' ] );
        fprintf('\nSuccessfully imported data from session %d!\n',sessionnumber-1);
    catch
        error('Failed to load data from session %d', sessionnumber-1);
    end
else
    data     = [];
    trialnum = 0;
    blocknum = 0;
end



%%  Parameters
% number of trials
p.n.thresholds    = 2;  % number of thresholds
p.n.trialsblock   = 12; % should be multiple of factorial block design (see below)
p.n.trialsthresh  = 48; % should be multiple of number of trials per block
p.n.blocks        = p.n.thresholds * p.n.trialsthresh / p.n.trialsblock;

% trialblock: factorial design
p.block.desresp  = [-1 1]; % which response should be given?
p.block.stimside = [1 2]; % at which side should the stimulus be presented?
p.block.whichq   = 1:p.n.thresholds; % which quest staircase to use on trial?

% screen
p.scr.number  = 1;  % max(Screen('Screens'));
p.scr.distscr = 70;              % distance to screen (cm)
p.scr.sizecm  = [ 50.67 33.89 ]; % width and height of screen (cm)
jnk           = Screen('Resolution',p.scr.number);
p.scr.hz      = jnk.hz;
p.scr.ifi     = 1 / p.scr.hz;
p.scr.hfi     = p.scr.ifi / 2;

% color indices
p.color.black = BlackIndex( p.scr.number );
p.color.white = WhiteIndex( p.scr.number );
p.color.grey  = WhiteIndex( p.scr.number ) / 2;
p.color.red   = [ p.color.white  p.color.black  p.color.black ];
p.color.green = [ p.color.black  p.color.white  p.color.black ];
p.color.blue  = [ p.color.black  p.color.black  p.color.white ];

% background
p.background.rOuter   = 15; % size outer annulus (dva)
p.background.rInner   = 5;  % size inner annulus (dva)
p.background.gradient = 4;  % size gradient      (dva)

% stimulus
p.stim.r          = 1.5;  % radius, (dva)
p.stim.ori        = 0;    % initial orientation
p.stim.cycles     = 5;    % number of cycles (freq = cycles/radius)
p.stim.phase      = 0;    % phase
p.stim.contrast   = 1;    % contrast
p.stim.propmask   = 0.25; % proportion of outer edge where mask decays to 0
p.stim.eccen      = ( p.background.rOuter-p.background.rInner )/2 + p.background.rInner;
p.stim.thetarange = [ 10*pi/16:(2*pi/360)/2:15*pi/16  ...  % possible theta for stimulus placement
                      17*pi/16:(2*pi/360)/2:22*pi/16; ... % horizontal and vertical axes are omitted
                         pi/16:(2*pi/360)/2: 6*pi/16  ...  % first row is left field, second row right
                      26*pi/16:(2*pi/360)/2:31*pi/16 ]; 

% fixation
p.fix.dOuter = 0.75; % diameter outer dot, (dva)
p.fix.dInner = 0.25; % diameter inner dot, (dva)
p.fix.rROI   = 2.5;  % radius of ROI around fixation (dva)

% timing
p.time.adaptation = 2;   % initial adaptation, secs 
p.time.stimulus   = 0.1; % stimulus duration, secs
p.time.wmdelay    = 3;   % working memory delay, secs

% text displays
p.text.invalid   = sprintf([ 'Invalid gaze position detected.\n\n' ...
                             'press [space] to continue']);
p.text.abort     = sprintf(  'Experiment aborted');
p.text.saving    = sprintf(  'Saving block data');
p.text.nextblock = sprintf([ 'Continue to next block?\n\n' ...
                             'press [space] to continue']);
p.text.theend    = sprintf(  'The end.\n\nThanks for your participation');

% quest parameters
p.maxdiffSWM            = 20;       % max orientation difference SWM (angular degrees)
p.maxdiffVWM            = 20;       % max orientation difference VWM (angular degrees)
p.mindiffSWM            = 0.5;      % min orientation difference SWM (angular degrees)
p.mindiffVWM            = 0.2;      % min orientation difference VWM (angular degrees)

p.quest.guessSWM        = log10(10); % initial guess SWM threshold (angular degrees in log scale)
p.quest.priorstdSWM     = log10(6);  % sd of initial guess SWM threshold(angular degrees in log scale)
p.quest.guessVWM        = log10(10); % initial guess orientation threshold (angular degrees in log scale)
p.quest.priorstdVWM     = log10(6);  % sd of initial guess orientation threshold(angular degrees in log scale)
p.quest.beta            = 3.5;       % controls the steepness of the psychometric function
p.quest.delta           = 0.05;      % fraction of trials on which the observer presses blindly
p.quest.gamma           = 0.5;       % fraction of trials that will generate response 1 when intensity == -inf
p.quest.threshcriterion = 0.75;      % threshold criterion expressed as probability of response == 1



%%  Quest initialization
for ithresh = 1:p.n.thresholds
    
    switch conditionfull
        case 'location'
            q(ithresh) = QuestCreate( p.quest.guessSWM, p.quest.priorstdSWM, ...
                                      p.quest.threshcriterion, p.quest.beta, ...
                                      p.quest.delta, p.quest.gamma );
        case 'orientation'
            q(ithresh) = QuestCreate( p.quest.guessVWM, p.quest.priorstdVWM, ...
                                      p.quest.threshcriterion, p.quest.beta, ...
                                      p.quest.delta, p.quest.gamma );
    end
    
    q(ithresh).normalizePdf = 1;
    
end



%%  RUN EXPERIMENT

try
    %%  Screen initialization
    % open screen
    AssertOpenGL;
    commandwindow;
    Screen('Preference', 'SkipSyncTests', 4);
    w  = Screen('OpenWindow', p.scr.number, p.color.grey);
    
    % set priority
    Priority(MaxPriority(w));
    
    % set blend function
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
    % get half flip interval
    hfi = 0.5 * Screen('GetFlipInterval', w); % half flip interval
    
    % get window size
    p.scr.wrect  = Screen('Rect', p.scr.number);
    p.scr.cx     = p.scr.wrect(3)/2;
    p.scr.cy     = p.scr.wrect(4)/2;
    p.scr.pixdeg = pixperdva( p.scr.distscr, p.scr.sizecm, p.scr.wrect(3:4) );
    
    % set textual preferences
    Screen('TextFont', w,'Helvetica');
    Screen('TextSize', w, 15);
    Screen('Preference', 'TextRenderer', 1);
    
    % keyboard settings
    KbName('UnifyKeyNames');
    
    % hide mouse
    HideCursor(w,0);
    

    
    %%  Textures: background
    % background
    background         = [ zeros( p.scr.wrect(4), p.scr.cx ) ones( p.scr.wrect(4), p.scr.cx ) ] .* p.color.white;
    backgroundGradient = repmat( linspace( p.color.black, p.color.white, p.background.gradient*p.scr.pixdeg ), p.scr.wrect(4), 1 );
    background( :, p.scr.cx-p.background.gradient*p.scr.pixdeg/2:p.scr.cx+p.background.gradient*p.scr.pixdeg/2-1 ) = backgroundGradient;
    tx.backgroundBW    = Screen('MakeTexture', w, background);
    tx.backgroundWB    = Screen('MakeTexture', w, fliplr(background));
    
    % background mask
    [ bgx, bgy ]          = meshgrid( -p.scr.cx:p.scr.cx, -p.scr.cy:p.scr.cy );
    bgx                   = bgx( [ 1:p.scr.cy p.scr.cy+2:end ], [ 1:p.scr.cx p.scr.cx+2:end ] );
    bgy                   = bgy( [ 1:p.scr.cy p.scr.cy+2:end ], [ 1:p.scr.cx p.scr.cx+2:end ] );
    backgroundMaskBoolean = sqrt(bgx.^2 + bgy.^2) < p.background.rInner * p.scr.pixdeg  |  ...
                            sqrt(bgx.^2 + bgy.^2) > p.background.rOuter * p.scr.pixdeg;
    backgroundMask        = ones( p.scr.wrect(4), p.scr.wrect(3), 2) * p.color.grey;
    backgroundMask(:,:,2) = p.color.white * ( backgroundMaskBoolean );
    tx.backgroundMask     = Screen('MakeTexture', w, backgroundMask);
    %---------------------------------------------------------------------%
    
    
    
    %%  RUN BLOCKS
    for iblock = 1:p.n.blocks
        %% Block parameters
        blockSorted = factorizeblock( p.block, 'sort' ); % factorial block
        blockSorted = repmat( blockSorted, p.n.trialsblock/size(blockSorted,1), 1 ); % repeat up to desirable number of trials per block
        if iblock == 1 % black-white (1) or white-black (2) layout?
            blockSorted = [ ones( size(blockSorted,1), 1 ) + round( rand(1) ) blockSorted ] ;
        else
            blockSorted = [ repmat( abs(block(1,1)-1)+2, size(blockSorted,1), 1 ) blockSorted ];
        end
        rndIdx      = Shuffle( 1:size( blockSorted, 1 ) );
        block       = blockSorted( rndIdx, : );
        
        % Update continuous blocknumber
        blocknum = blocknum + 1;
        
        % Filename
        filename = [ fileprfx num2filestr(blocknum) ];
        

        
        %% Textures: gratings 
        % with random phase and correct background color
        mask      = makeSinMask( p.stim.r*p.scr.pixdeg, p.stim.r*p.scr.pixdeg*p.stim.propmask);
        stimulus1 = NaN( p.stim.r*p.scr.pixdeg*2+1, p.stim.r*p.scr.pixdeg*2+1, p.n.trialsblock );
        stimulus2 = NaN( p.stim.r*p.scr.pixdeg*2+1, p.stim.r*p.scr.pixdeg*2+1, p.n.trialsblock );
        for itmp = 1:p.n.trialsblock
            grating1 = makeGrating( p.stim.r * p.scr.pixdeg, p.stim.cycles, 0, rand(1)*2*pi );
            grating2 = makeGrating( p.stim.r * p.scr.pixdeg, p.stim.cycles, 0, rand(1)*2*pi );
            
            if block(itmp,1) == block(itmp,3)
                % black background
                stimulus1(:,:,itmp) = ((grating1 * p.stim.contrast+1).*mask-1) * p.color.grey + p.color.grey;
                switch conditionfull
                    case 'location'
                        stimulus2(:,:,itmp) = ((grating2 * p.stim.contrast+1).*mask-1) * p.color.grey + p.color.grey;
                    case 'orientation'
                        stimulus2(:,:,itmp) = ((grating2 * p.stim.contrast).*mask-1) * p.color.grey;
                end
            else 
                % white background
                stimulus1(:,:,itmp) = ((grating1 * p.stim.contrast-1).*mask+1) * p.color.grey + p.color.grey;
                switch conditionfull
                    case 'location'
                        stimulus2(:,:,itmp) = ((grating2 * p.stim.contrast-1).*mask+1) * p.color.grey + p.color.grey;
                    case 'orientation'
                        stimulus2(:,:,itmp) = ((grating2 * p.stim.contrast).*mask+1) * p.color.grey;
                end
                
            end
            
            tx.stim1(itmp) = Screen( 'MakeTexture', w, stimulus1(:,:,itmp) );
            tx.stim2(itmp) = Screen( 'MakeTexture', w, stimulus2(:,:,itmp) );
        end
        
        
        
        %% Eyelink initialization
        if ~dummymode
            el = EyelinkInitDefaults(w);
            initEyelink_JF(el, p.scr.wrect, p.color.grey, p.color.black, false, [filename '.edf']);
            EyelinkDoTrackerSetup(el);
            KbReleaseWait;
        else
            el = [];
        end
        
        
        
        %% RUN TRIALS
        itrial = 0;
        while itrial < size(block,1)
            
            % update trial index & continuous trialnumber
            itrial   = itrial + 1;
            trialnum = trialnum + 1;
            
            % renaming for my own overview
            bwlayout = block(itrial,1);
            desresp  = block(itrial,2);
            vf       = block(itrial,3);
            whichq   = block(itrial,4);
             
            % set location & orientation
            switch conditionfull
                case 'location'
                    % locations
                    theta1 = randsample( p.stim.thetarange(vf,:), 1 );
                    if desresp == 1
                        thetadiff = min( 10^QuestQuantile( q( whichq ) ), p.maxdiffSWM );
                        thetadiff = deg2rad( max( thetadiff, p.mindiffSWM ) );
                        direction = randsample([-1 1],1);
                        theta2    = theta1 + thetadiff * desresp;
                        if ( vf==1 && ( ( theta2<0.5*pi+pi/16 ) || ( theta2>1.5*pi-pi/16 ) ) ) || ...
                           ( vf==2 && ( ( theta2<0 ) || ( theta2>0.5*pi-pi/16 && theta2<1.5*pi+pi/16 ) || ( theta2 > 2*pi-pi/16 ) ) )
                            direction = direction * -1;
                            theta2    = theta1 + thetadiff * direction;
                        end
                    else
                        theta2     = theta1;
                        direction  = 0;
                    end
                        
                    % orientations
                    ori1    = rad2deg( randsample( p.stim.thetarange(1,:), 1 ) );
                    oridiff = randsample( [-p.maxdiffVWM:-p.mindiffVWM p.mindiffVWM:p.maxdiffVWM], 1);
                    ori2    = ori1 + oridiff;
                    
                    
                case 'orientation'
                    % locations
                    theta1    = randsample( p.stim.thetarange(vf,:), 1 );
                    thetadiff = 0; % not used in orientation change detection
                    theta2    = 0; % not used in orientation change detection
                    
                    % orientations
                    ori1 = rad2deg( randsample( p.stim.thetarange(:), 1 ) );
                    if desresp == 1
                        oridiff   = min( 10^QuestQuantile( q(whichq) ), p.maxdiffVWM );
                        oridiff   = max( oridiff, p.mindiffSWM );
                        direction = randsample([-1 1],1);
                        ori2      = ori1 + oridiff * direction;
                    else
                        ori2      = ori1;
                        oridiff   = 0;
                        direction = 0;
                    end
            end
            stimparams = [vf bwlayout theta1 ori1 theta2 ori2 desresp];

            
            % run trial
            [ w, el, response, rt, gotoquit, gotosetup, invalid ] = runtrial_wmpupil( w, el, tx, p, dummymode, trialnum, condition, stimparams, itrial );
            
            % did we do well?
            if invalid % no, repeat trial at end of block
                block     = [ block; block(itrial,:) ];
                tx.stim1  = [ tx.stim1 tx.stim1(itrial) ];
                tx.stim2  = [ tx.stim2 tx.stim2(itrial) ];
                intensity = 999;
                
            else % yes, update staircase
                switch conditionfull
                    case 'location'
                        intensity = abs( rad2deg(theta1) - rad2deg(theta2) );
                    case 'orientation'
                        intensity = abs( ori1 - ori2 );
                end
                if intensity ~= 0
                    q(whichq) = QuestUpdate( q(whichq), log10( intensity ), response );
                end
            end
            fprintf('Trial %d, intensity %.4f\n',trialnum,intensity);
            
            % add response to data array
            data = [ data; blocknum trialnum stimparams intensity response rt whichq 10^QuestMean( q(whichq) ), 10^QuestSd( q(whichq) ) invalid];
            
            % save data array
            if ~dummymode
                save( [matdir filesep fileprfx '.mat'], 'data','trialnum','blocknum','q','p');
            end
            
            % if quit- or setup-key was pressed, take appropriate action
            if gotoquit
                break
            elseif gotosetup && ~dummymode
                FlushEvents('keyDown');
                EyelinkDoTrackerSetup(el);
                KbReleaseWait;
            end
            
        end % of trials within block
        
        
        
        %% End block
        % close textures
        Screen('Close', [ tx.stim1 tx.stim2 ]);
        
        if ~practice
            
            % display save text
            Screen('FillRect', w, p.color.grey);
            DrawFormattedText( w, p.text.saving, 'center', 'center', p.color.black);
            Screen('Flip',w);
            
            % save .edf
            if ~dummymode
                Eyelink('Command', 'set_idle_mode');    WaitSecs(0.5);
                Eyelink('CloseFile');                   WaitSecs(0.5);
                status = Eyelink( 'ReceiveFile', [filename '.edf'] );
                if status > 0
                    fprintf('ReceiveFile status %d\n', status);
                end
                movefile( [pwd filesep filename '.edf'], edfdir )
            end
            
            % save .mat
            save( [matdir filesep fileprfx '.mat'], 'data','trialnum','blocknum','q','p');
            
            % display next run text
            if ~gotoquit && iblock < p.n.blocks
                 todrawtext = txt.nextblock;
            elseif gotoquit
                 todrawtext = 'Experiment aborted.';
            else todrawtext = txt.theend;
            end
            DrawFormattedText(w, todrawtext, 'center', 'center', p.color.black);
            Screen('Flip',w);
            
            % wait for response
            if ~gotoquit && iblock < p.n.blocks
                decided = false;
                while ~decided
                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown
                        % if multiple keynames use first one
                        allKeyNames = KbName(keyCode);
                        if iscell(allKeyNames)
                            keyName = allKeyNames{1};
                        else
                            keyName = allKeyNames;
                        end
                        
                        % change variables appropriately
                        if ismember(keyName,{'BackSpace','ESCAPE'})
                            gotoquit = true;
                            decided  = true;
                        elseif strcmp(keyName,'space')
                            decided = true;
                        end
                    end
                end
            else WaitSecs(1);
            end
            
        else
            % at the end of a practice block, quit
            gotoquit = true;
            
            % close .edf-file
            if ~dummymode
                Eyelink('Command', 'set_idle_mode');    WaitSecs(0.5);
                Eyelink('CloseFile');                   WaitSecs(0.5);
            end
        end
        
        % quit experiment if abort-key was pressed
        if gotoquit;
            break;
        end
        
        
    end
    
    
    
catch ME
    
    %% Try to save everythin' whn something goes wrong
    % close textures
    Screen('CloseAll');
    
    % save .edf
    if ~dummymode
        Eyelink('Command', 'set_idle_mode');    WaitSecs(0.5);
        Eyelink('CloseFile');                   WaitSecs(0.5);
        status = Eyelink( 'ReceiveFile', [filename '.edf'] );
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        movefile( [pwd filesep filename '.edf'], edfdir )
    end
    
    % close .mat
    save( [matdir filesep fileprfx '.mat'], 'data','trialnum','blocknum','q','p');
    
    % print error message
    warning( [ '\n??? ' ME.message '\n\nError in ==> ' ME.stack(1).name ' at %d\n\n' ],...
               ME.stack(1).line);
    
end


%% Close screen
if ~dummymode
    Eyelink('Shutdown');
end
Screen('CloseAll');
Priority(0);
ShowCursor(w);
commandwindow;