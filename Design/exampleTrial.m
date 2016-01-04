function exampleTrial(dummymode)

if nargin < 1
    dummymode = 1;
end


%-------------------------------------------------------------------------%
% Parameters
% screennumber
p.scr.number = 1;

% color indices
p.color.black = BlackIndex( p.scr.number );
p.color.white = WhiteIndex( p.scr.number );
p.color.grey  = WhiteIndex( p.scr.number ) / 2;
p.color.red   = [ p.color.white  p.color.black  p.color.black ];
p.color.green = [ p.color.black  p.color.white  p.color.black ];
p.color.blue  = [ p.color.black  p.color.black  p.color.white ];

% background
p.background.rOuter = 300; % size outer annulus, pix
p.background.rInner = 100; % size inner annulus, pix

% stimulus
p.stim.r          = 35;  % diameter, pix
p.stim.ori        = 45;  % orientation
p.stim.cycles     = 5;   % per s.r, spatial frequency
p.stim.phase      = 0;   % phase
p.stim.contrast   = 1;   % contrast
p.stim.eccen      = ( p.background.rOuter-p.background.rInner )/2 + p.background.rInner;
p.stim.thetaRange = [ pi/12:0.01:5*pi/12 ...
                      8*pi/12:0.01:11*pi/12 ...
                      pi/12:0.01:5*pi/12 + pi ...
                      8*pi/12:0.01:11*pi/12 + pi ];

% fixation
p.fix.rOuter = 15; % pix, size of outer dot
p.fix.rOuter = 5;  % pix, size of inner dot
p.fix.rROI   = 50; % pix, size of region of interest around fixation

% timing
p.time.adaptation = 1;   % initial adaptation, secs 
p.time.stimulus   = 0.1; % stimulus duration, secs
p.time.wmdelay    = 4;   % working memory delay, secs

% text displays
p.text.invalid    = sprintf([ 'Invalid gaze position detected.\n\n' ...
                              'press [space] to continue']);
%-------------------------------------------------------------------------%




%-------------------------------------------------------------------------%
% Initialize screen
AssertOpenGL;
commandwindow;

% open screen
%Screen('Preference', 'SkipSyncTests', p.scr.number);
w  = Screen('OpenWindow', p.scr.number, p.color.grey);

% set priority
Priority(MaxPriority(w));

% set blend function
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% get half flip interval
hfi = 0.5 * Screen('GetFlipInterval', w); % half flip interval

% get window size
wrect = Screen('Rect', p.scr.number); 
cx    = wrect(3)/2;
cy    = wrect(4)/2;

% background
background         = [ zeros( wrect(4), cx ) ones( wrect(4), cx ) ] .* p.color.white;
gradientsize       = round( wrect(3) / 30 ) * 2;
backgroundGradient = repmat( linspace( p.color.black, p.color.white, gradientsize ), wrect(4), 1 );
background( :, cx-gradientsize/2:cx+gradientsize/2-1 ) = backgroundGradient;
backgroundBWtex    = Screen('MakeTexture', w, background);
backgroundWBtex    = Screen('MakeTexture', w, fliplr(background));

% background mask
[ bgx, bgy ]          = meshgrid( -cx:cx, -cy:cy );
bgx                   = bgx( [ 1:cy cy+2:end ], [ 1:cx cx+2:end ] );
bgy                   = bgy( [ 1:cy cy+2:end ], [ 1:cx cx+2:end ] );
backgroundMaskBoolean = sqrt(bgx.^2 + bgy.^2) < p.background.rInner  |  sqrt(bgx.^2 + bgy.^2) > p.background.rOuter;
backgroundMask        = ones( wrect(4), wrect(3), 2) * p.color.grey;
backgroundMask(:,:,2) = p.color.white * ( backgroundMaskBoolean );
backgroundMasktex     = Screen('MakeTexture', w, backgroundMask);

%-------------------------------------------------------------------------%




%-------------------------------------------------------------------------%
% Create stimulus
theta        = pi;  % trial specific location (in polar coordinates)
thetaDiff    = pi/10; % trial specific location difference

[px, py]         = pol2cart( theta, p.stim.eccen );
stimulusBaserect = [ cx-p.stim.r/2 cy-p.stim.r/2 cx+p.stim.r/2 cy+p.stim.r/2 ];
stimulusRect     = CenterRectOnPointd( stimulusBaserect, cx+px, cy-py );
grating          = MakeGrating( p.stim.r, p.stim.cycles, p.stim.ori, p.stim.phase);
mask             = MakeSinMask( p.stim.r, p.stim.r*0.25);


% adjust to background color
if theta < pi/2 || theta > 3*pi/2
    % black background
    stimulus = ((grating * p.stim.contrast+1).*mask-1) * p.color.grey + p.color.grey;
else
    % white background
    stimulus = ((grating * p.stim.contrast-1).*mask+1) * p.color.grey + p.color.grey;
end

stimtex = Screen('MakeTexture', w, stimulus);
%-------------------------------------------------------------------------%




%-------------------------------------------------------------------------%
% Run trial
try
    
    if dummymode
        ShowCursor(w);
        SetMouse(cx,cy);
        eye_used = 999;
        FlushEvents('keyDown');
        KbWait;
    end
    
    
    %---------------------------------------------------------------------%
    % Screen 1: adaptation
    % background annulus
    Screen('DrawTexture', w, backgroundWBtex,   wrect);
    Screen('DrawTexture', w, backgroundMasktex, wrect);
    
    % fixation
    Screen('DrawDots', w, [cx;cy], p.fix.rOuter, p.color.blue', [0 0], 1);
    Screen('DrawDots', w, [cx;cy], p.fix.rInner, p.color.grey,  [0 0], 1);
    
    % flip
    tFlip = Screen('Flip',w);

    
    %---------------------------------------------------------------------%
    % Screen 2: stimulus
    % background annulus
    Screen('DrawTexture', w, backgroundWBtex,   wrect);
    Screen('DrawTexture', w, backgroundMasktex, wrect);

    % fixation
    Screen('DrawDots', w, [cx;cy], p.fix.rOuter, p.color.blue', [0 0], 1);
    Screen('DrawDots', w, [cx;cy], p.fix.rInner, p.color.grey,  [0 0], 1);
    
    % gabor
    Screen('DrawTexture', w, stimtex, [], stimulusRect);
    
    % flip
    tFlip = Screen('Flip',w, tFlip + p.time.adaptation - hfi);

    
    %---------------------------------------------------------------------%
    % Screen 3: working memory delay
    % background annulus
    Screen('DrawTexture', w, backgroundWBtex,   wrect);
    Screen('DrawTexture', w, backgroundMasktex, wrect);

    % fixation
    Screen('DrawDots', w, [cx;cy], p.fix.rOuter, p.color.blue', [0 0], 1);
    Screen('DrawDots', w, [cx;cy], p.fix.rInner, p.color.grey,  [0 0], 1);
    
    % flip
    tFlip = Screen('Flip',w, tFlip + p.time.stimulus - hfi);

    
    %---------------------------------------------------------------------%
    % Screen 4: reference
    % set gabor position
    [px, py]   = pol2cart( theta+thetaDiff, p.stim.eccen );
    stimulusRect  = CenterRectOnPointd( stimulusBaserect, cx+px, cy-py );
    
    % background annulus
    Screen('DrawTexture', w, backgroundWBtex,   wrect);
    Screen('DrawTexture', w, backgroundMasktex, wrect);

    % fixation
    Screen('DrawDots', w, [cx;cy], p.fix.rOuter, p.color.blue', [0 0], 1);
    Screen('DrawDots', w, [cx;cy], p.fix.rInner, p.color.grey,  [0 0], 1);
    
    % gabor
    Screen('DrawTexture', w, stimtex,[], stimulusRect);
    
    % flip
    tFlip = Screen('Flip',w, tFlip + p.time.wmdelay - hfi);
    Screen('Close', stimtex);

    
    %---------------------------------------------------------------------%
    % Screen 5: response window
    % background annulus
    Screen('DrawTexture', w, backgroundWBtex,   wrect);
    Screen('DrawTexture', w, backgroundMasktex, wrect);

    % fixation
    Screen('DrawDots', w, [cx;cy], 15, p.color.blue', [0 0], 1);
    Screen('DrawDots', w, [cx;cy],  5, p.color.grey,  [0 0], 1);
    
    % flip
    tFlip = Screen('Flip', w, tFlip + p.time.stimulus - hfi);

    
    %---------------------------------------------------------------------%
    % Wait
    FlushEvents('keyDown');
    KbWait;
end



%-------------------------------------------------------------------------%
% Exit
Screen('CloseAll');
Priority(0);
commandwindow;
%-------------------------------------------------------------------------%
end


function [grating] = MakeGrating(radius, freq, ori, phase)

% set phase in radians
phaseRad = phase * 2* pi;

% set orientation in radians
oriRad = (ori / 360) * 2*pi;

% make linear ramp
X  = 1:(2*radius+1);

% rescale X -> -.5 to .5
X0 = (X / (2*radius+1)) - 0.5; 

% make 2D matrix
[Xm, Ym] = meshgrid(X0, X0);

% compute proportion of Xm and Xy for given orientation
Xt = Xm * cos(oriRad);
Yt = Ym * sin(oriRad);

% sum X and Y components
XYt = Xt + Yt;

% convert to radians and scale by frequency
XYf = XYt * freq * 2*pi;

% shift grating to correct phase
grating = sin(XYf + phaseRad);
end

function [mask] = MakeSinMask(rStimulus, startDecay, rThresh)
% Function makes array with circular mask.
% Mask is a flat with sinusoid decay at the edge
%
% rStimulus:  radius of the entire stimulus 
%             (size of final matrix will be 2*rStimulus+1)
% startDecay: at which eccentricity starts the mask decay
% rThresh:    at which eccentricity should the mask be full
%
% Example: img = MakeSinMask(50,30,45);
%          imagesc(img); colormap gray


if nargin < 3; rThresh = rStimulus; end

[x,y]       = meshgrid(-rStimulus:rStimulus,-rStimulus:rStimulus);
eccen       = sqrt((x).^2+(y).^2); % calculate eccentricity of each point in grid relative to center of 2D image
rDistCenter = abs(eccen);          % calculate radial distance to center of gaussian window for every point in image

mask        = double(rDistCenter < rThresh);
rDistCenter = mask.* rDistCenter;
edgeDecay   = cos( linspace(pi, 2*pi, rThresh-startDecay+1 ) ) ./ 2 + 0.5;

for i = 1:length(edgeDecay)
    mask( rDistCenter >= startDecay-1+i) = 1-edgeDecay(i);
end

end