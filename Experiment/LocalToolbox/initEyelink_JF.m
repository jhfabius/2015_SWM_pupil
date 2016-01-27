function [el] = initEyelink_JF(el, wRect, colbg, colstim, withsound, edfName)
% wRect = vector with resolution of stimulus monitor, as obtained with
%         Screen('Rect', ...)
% edfName = full name of the EDF file to which eyelink data will be saved

% Define visual
el.allowlocalcontrol       = 1;
el.backgroundcolour        = colbg;
el.msgfontcolour           = colstim;
el.imgtitlecolour          = colstim;
el.calibrationtargetcolour = colstim;
el.calibrationtargetsize   = 0.9; % inner size
el.calibrationtargetwidth  = 0.3; % outer size

% Define auditory (frequency, volume, duration);
el.targetbeep = 0;
if withsound
    el.cal_target_beep               =[1000 0.6 0.05];
    el.drift_correction_target_beep  =[1000 0.8 0.05];
    el.calibration_failed_beep       =[1200 0.8 0.25];
    el.calibration_success_beep      =[600  0.8 0.25];
    el.drift_correction_failed_beep  =[1200 0.8 0.25];
    el.drift_correction_success_beep =[600  0.8 0.25];
else
    el.cal_target_beep               =[1250 0 0.05];
    el.drift_correction_target_beep  =[1250 0 0.05];
    el.calibration_failed_beep       =[400  0 0.25];
    el.calibration_success_beep      =[800  0 0.25];
    el.drift_correction_failed_beep  =[400  0 0.25];
    el.drift_correction_success_beep =[800  0 0.25];
end

EyelinkUpdateDefaults(el);


% Initialization connection with Eyelink
if Eyelink('Initialize', 'PsychEyelinkDispatchCallback') ~=0
    error('Eyelink initialization failed...')
end


% Creat edf-file to record data to
if Eyelink('Openfile',edfName) ~= 0
    error('Failed to create EDF file: ''%s'' ',edfName);
end


% Set eye-tracking configuration
% 1. map gaze position from tracker to screen pixel positions
Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, wRect(3)-1, wRect(4)-1);

% 2. set calibration type
Eyelink('Command', 'calibration_type = HV5');
Eyelink('Command', 'generate_default_targets = YES');
Eyelink('Command', 'enable_automatic_calibration = YES');	% YES default
Eyelink('Command', 'automatic_calibration_pacing = 1000');	% 1000 ms default
Eyelink('Command', 'randomize_calibration_order = YES');    % YES default
Eyelink('Command', 'randomize_validation_order = YES');     % YES default


% 3. set parser (conservative saccade thresholds)
Eyelink('Command', 'saccade_velocity_threshold = 35');
Eyelink('Command', 'saccade_acceleration_threshold = 9500');

% 4. set EDF file contents
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE');

% 5. set link data
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');



end