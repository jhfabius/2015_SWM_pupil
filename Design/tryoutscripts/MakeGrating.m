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
[Xm Ym] = meshgrid(X0, X0);

% compute proportion of Xm and Xy for given orientation
Xt = Xm * cos(oriRad);
Yt = Ym * sin(oriRad);

% sum X and Y components
XYt = Xt + Yt;

% convert to radians and scale by frequency
XYf = XYt * freq * 2*pi;

% shift grating to correct phase
grating = sin(XYf + phaseRad);