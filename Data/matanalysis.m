clear all; close all; clc;


%% Settings
plot_staircaseIndi  = false;
plot_thresholdGroup = true;

fignum = 0;

color_l = [   0 102  51] ./ 255;
color_o = [ 184 134  11] ./ 255;

lw    = 4;    % linewidth
tw    = 0;    % tickwidth
mSize = 5;    % markersize
bw    = 0.95; % bar width




%% Excluded participants
exclude = {'CC','MM'};

% reason: it appears as though these two subjects were not doing the
%         orientation task properly (or, at all...)
%  - CC: threshold orientation > 3 std above average & threshold > 45 deg.
%  - MM: threshold orientation > 3 std above average & threshold > 45 deg.




%% Load data
% set filepath to analysis functions
addpath( [fileparts(pwd) filesep 'AnalysisFun'] );

% files
dirmat   = [pwd filesep 'mat'];
allfiles = dir(dirmat);
allfiles = allfiles( not( [allfiles.isdir] ) );

% extract data
allinitials = [];
isubj       = 0;
for i_file = 1:length(allfiles)
    
    % filename and initials
    filename = allfiles(i_file).name;
    initials = filename(1:2);
    
    % is this subject included?
    if ~ismember( initials, exclude )
        
        % load data
        load( [dirmat filesep filename] );
        
        % set subject variables
        if ~ismember(initials,allinitials)
            isubj              = isubj + 1;
            allinitials{isubj} = initials;
        end
        
        % save to final data frame
        eval( [ 'final(isubj).' filename(4) ' = data;' ] );
        
    end
    
end

% number of subjects
nsubj = size(final,2);




%% Column names
%    1. blocknumber
%    2. trialnumber
%    3. visual field
%    4. black-white layout of background
%    5. theta of stimulus 1
%    6. orientation of stimulus 1
%    7. theta of stimulus 2
%    8. orientation of stimulus 2
%    9. desired response (-1: lower/ccw, 1 = higher/cw)
%   10. intensity (difference between theta1 and theta2 or between ori1 and ori2)
%   11. response
%   12. response time
%   13. which staircase was used?
%   14. threshold estimate
%   15. standard deviation of estimate
%   16. valid (logical)




%% Plot: individual staircase progression
if plot_staircaseIndi

    % Location thresholds
    fignum = fignum + 1;
    figure(fignum);
    for isubj = 1:nsubj
        valid  = final(isubj).L(:,16) == 1;
        
        stair  = final(isubj).L(valid,13);
        thresh = final(isubj).L(valid,14);
        
        subplot(4,4,isubj); 
        hold on;
        for istair = 1:2
            plot( thresh(stair==istair), 'Color', color_l );
        end
        hold off;
        
        title(allinitials{isubj});
        axis([0 50 0 25])
    end
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    text(0.5, 1,'\bf Location','HorizontalAlignment','center','VerticalAlignment', 'top')
    
    % Orientation thresholds
    fignum = fignum + 1;
    figure(fignum);
    for isubj = 1:nsubj
        valid  = final(isubj).O(:,16) == 1;
        
        stair  = final(isubj).O(valid,13);
        thresh = final(isubj).O(valid,14);
        
        subplot(4,4,isubj); 
        hold on;
        for istair = 1:2
            plot( thresh(stair==istair), 'Color', color_o );
        end
        hold off;
        
        title(allinitials{isubj});
        axis([0 50 0 90])
    end
    ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    text(0.5, 1,'\bf Orientation','HorizontalAlignment','center','VerticalAlignment', 'top')
    
end



%% Plot: average final thresholds
if plot_thresholdGroup
    fignum = fignum + 1;
    figure(fignum);
    
    tl = NaN(nsubj,2); % threshold estimates of location task
    to = NaN(nsubj,2); % threshold estimates of orientation task
    for isubj = 1:nsubj
        % location data
        valid  = final(isubj).L(:,16) == 1;
        stair  = final(isubj).L(:,13);
        
        thresh1 = final(isubj).L(valid & stair==1,14);
        thresh2 = final(isubj).L(valid & stair==2,14);
        
        tl(isubj,1) = thresh1( end );
        tl(isubj,2) = thresh2( end );
        
        % orientation data
        valid  = final(isubj).O(:,16) == 1;
        stair  = final(isubj).O(:,13);
        
        thresh1 = final(isubj).O(valid & stair==1,14);
        thresh2 = final(isubj).O(valid & stair==2,14);
        
        to(isubj,1) = thresh1( end );
        to(isubj,2) = thresh2( end );
    end
    
    subplot(1,2,1); hold on;
    bl = bar( 1:2, mean(tl), 'FaceColor', color_l, 'EdgeColor', color_l, 'LineWidth', 0.1 );
    el = terrorbar( 1:2,  mean(tl), std(tl)./sqrt(nsubj), std(tl)./sqrt(nsubj), 0);
    axis([0.3 2.7 0 10])
    set(gca,'XTick',1:2,'YTick',0:5:15);
    
    subplot(1,2,2); hold on;
    bo = bar( 1:2, mean(to), 'FaceColor', color_o, 'EdgeColor', color_o, 'LineWidth', 0.1 );
    eo = terrorbar( 1:2,  mean(to), std(to)./sqrt(nsubj), std(to)./sqrt(nsubj), 0);
    axis([0.3 2.7 0 20])
    set(gca,'XTick',1:2,'YTick',0:5:20);
    
    set([bl bo],'BarWidth',bw);
    set([el eo],'Color','k','LineWidth', lw);
    
end
