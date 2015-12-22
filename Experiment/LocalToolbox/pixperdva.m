function [ pixdeg ] = pixperdva( dist2scr, wh_cm, wh_pix )
% [ pixdeg ] = pixperdva( dist2scr, wh_cm, wh_pix )
%
% Calculate pixels in 1 degree visual angle
%
% Input
%   o dist2scr  distance to screen in cm
%   o wh_cm     vector = [width height] of screen in cm
%   o wh_pix    vector = [width height] of screen in pixels (-> resolution)
%
% Output
%   o pixdeg    number of pixels per degree visual angle

pixcm  = mean( wh_pix ./ wh_cm );
cmdeg  = 2*atand( 0.5 / dist2scr );
pixdeg = round( pixcm * cmdeg );

end