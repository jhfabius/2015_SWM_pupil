function success=EyelinkDoDriftCorrection_wmpupil(el, tx, tx_tmpbackground, wrect, x, y, tardiam, draw, allowsetup)

success=1;
% DO PRE-TRIAL DRIFT CORRECTION */
% We repeat if ESC key pressed to do setup. */
% Setup might also have erased any pre-drawn graphics. */

% if no x and y are supplied, set x,y to center coordinates
if ~exist('x', 'var') || isempty(x) || ~exist('y', 'var') || isempty(y)
	[x,y] = WindowCenter(el.window); % convenience routine part of eyelink toolbox
end

if ~exist('draw', 'var') || isempty(draw)
	draw=1;
end

if ~exist('allowsetup', 'var') || isempty(allowsetup)
	allowsetup=1;
end

while 1	
    % draw our custom drift correct target
    Screen('DrawTexture', el.window, tx_tmpbackground,  wrect);
    Screen('DrawTexture', el.window, tx.backgroundMask, wrect);
    Screen('DrawDots', el.window, [x;y], tardiam(2), el.calibrationtargetcolour, [],1);
    Screen('DrawDots', el.window, [x;y], tardiam(1), el.backgroundcolour, [],1);
    Screen('Flip',el.window);
    
	if Eyelink('IsConnected')==el.notconnected   % Check link often so we don't lock up if tracker lost
		%result=el.ABORT_EXPT;
		success=0;
		return;
	end;
	% DRIFT CORRECTION */
	% 3rd argument would be 0 to NOT draw a target */
	% fprintf('drifcorr at % d %d\n', x, y );
    error = EyelinkDoDriftCorrect(el, x, y, draw, allowsetup);
	
	if error==el.TERMINATE_KEY
		%result=el.ABORT_EXPT;
		success=0;
		return;
	end;
	% repeat if ESC was pressed to access Setup menu
	if(error~=el.ESC_KEY)
        break; 
    end
end % while
