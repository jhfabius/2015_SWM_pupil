% screennumber
p.scr.number = 0;

% color indices
p.color.black = BlackIndex( p.scr.number );
p.color.white = WhiteIndex( p.scr.number );
p.color.grey  = WhiteIndex( p.scr.number ) / 2;

% background
p.background.rOuter = 250; % size outer annulus, pix
p.background.rInner = 100; % size inner annulus, pix


% open screen
AssertOpenGL;
commandwindow;
Screen('Preference', 'SkipSyncTests', 1);
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
backgroundtex      = Screen('MakeTexture', w, background);

% background mask
[ bgx, bgy ]          = meshgrid( -cx:cx, -cy:cy );
bgx                   = bgx( [ 1:cy cy+2:end ], [ 1:cx cx+2:end ] );
bgy                   = bgy( [ 1:cy cy+2:end ], [ 1:cx cx+2:end ] );
backgroundMaskBoolean = sqrt(bgx.^2 + bgy.^2) < p.background.rInner  |  sqrt(bgx.^2 + bgy.^2) > p.background.rOuter;
backgroundMask        = ones( wrect(4), wrect(3), 2) * p.color.grey;
backgroundMask(:,:,2) = p.color.white * ( backgroundMaskBoolean );
backgroundMasktex     = Screen('MakeTexture', w, backgroundMask);


% draw background
Screen('DrawTexture', w, backgroundtex,     wrect);
Screen('DrawTexture', w, backgroundMasktex, wrect);


% draw fixation
Screen('DrawDots', w, [cx;cy], 15, p.color.black', [0 0], 1);
Screen('DrawDots', w, [cx;cy],  5, p.color.grey,  [0 0], 1);

% flip
Screen('Flip',w);

% Exit
FlushEvents('keyDown');
KbWait;
Screen('CloseAll');
Priority(0);
commandwindow;

