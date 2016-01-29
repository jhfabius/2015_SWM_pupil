function output = MakeGabor(imsize, ncycles, ori, phase, sigma, bg, trim)
% Make gabor matrix with values between -1 and 1
%
% INPUT: 
%   - imsize:  size of matrix (n X n)
%   - ncycles: number of cycles (grey-black-grey-white-grey)
%   - ori:     orientation of grating (0 to 360)
%   - phase:   phase of gratin (0 to 1)
%   - sigma:   standard deviation of gaussian filter
%   - bg:      background value (-1 to 1, default = 0)
%   - trim:    trim off gaussian values smaller than this (default = 0.005)
%
% Source: http://www.icn.ucl.ac.uk/courses/MATLAB-Tutorials/Elliot_Freeman/html/gabor_tutorial.html

%-------------------------------------------------------------------------%
% Input check
if ~exist('bg','var') || isempty(bg)
    bg = 0;
end

if ~exist('trim','var') || isempty(trim)
    trim = 0.005;
end

%-------------------------------------------------------------------------%
% Initialize parameters
% set frequency
freq = ncycles;

% set phase in radians
phaseRad = phase * 2* pi;

% set orientation in radians
oriRad = (ori / 360) * 2*pi;

% gaussian width as fraction of imageSize
s = sigma / imsize;


%-------------------------------------------------------------------------%
% Make 2D sinewave
% make linear ramp
X  = 1:imsize;

% rescale X -> -.5 to .5
X0 = (X / imsize) - 0.5; 

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
XYp = sin(XYf + phaseRad);

% correct background colour
grating = XYp - bg;


%-------------------------------------------------------------------------%
% Add gaussian filter sinewave
% matrix with gaussian
gauss = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)) );
gauss = gauss/max(max(gauss));

% trim around edges
gauss(gauss < trim) = 0;

% add gaussian filter to grating
output = grating .* gauss;
output = output + bg;

end