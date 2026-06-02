% TEST_FIND_IC_OIC_TO :
% The point of this is to find IC, OIC and TO of step.
% Each trial is comprised of a step phase which includes 2 steps. The GRF
% and COP data etc. was cut to only show single support from a single force 
% plate.
% This means the GRF and COP of each trial begins at IC and ends at TO. 
% The trajectory data was cut to show the full stance phase from IC to
% contact of the same leg.
% But where is OIC? We need to find it by looking at marker trajectories of 
% the heel and toe of the other foot during that trial.
% Where do they indicate OIC? Maybe look at a different trial where the
% other foot was the main foot and see how IC looks for that foot.
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = "..\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
i_end = find(matches(toolbox_root, "PROST"), 1, "last");
toolbox_root = fullfile(toolbox_root{1:i_end});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%%
subjects = [1 5 10 25 50];
for subject=subjects
    load(fullfile(data_path, "Subject" + subject + ".mat"));
    
    % make a vector with only the numbers of the walking trials:
    walking_data = s.Data(matches({s.Data.Task}, 'Walking'));
    n_trials = length(walking_data);
    
    % Search for a trial with the right foot as initial contact
    trial_right = 1; 
    while trial_right <= n_trials && ...
    ~strcmp(walking_data(trial_right).Foot, 'RX')
    trial_right = trial_right + 1;
    end
    if trial_right > n_trials
    continue
    end
    
    % Search for a trial with the left foot as initial contact
    trial_left = 1; 
    while trial_left <= n_trials && ...
    ~strcmp(walking_data(trial_left).Foot, 'LX')
    trial_left = trial_left + 1;
    end
    if trial_left > n_trials
    continue
    end
    
    % Get marker indices
    iYLxHeel = strmatch("YLxHeel", s.MarkerVarName);
    iYRxHeel = strmatch("YRxHeel", s.MarkerVarName);
    iYLxToe = strmatch("YLxToe1", s.MarkerVarName);
    iYRxToe = strmatch("YRxToe1", s.MarkerVarName);
    
    % Get GRF indices
    iYGrf = strmatch("GRFF_Y", s.GrfVarName);
    iXCop = strmatch("Cop_X", s.GrfVarName);
    iZCop = strmatch("Cop_Z", s.GrfVarName);
    
    %% Right foot for identifying IC, OIC and TO
    % Num samples
    n_marker_samples = size(walking_data(trial_right).Marker, 2);
    n_grf_samples = size(walking_data(trial_right).Grf, 2);

    % Get markers
    R_right_heel = walking_data(trial_right).Marker(iYRxHeel, :) * 1000; % [mm]
    R_left_heel = walking_data(trial_right).Marker(iYLxHeel, :) * 1000; % [mm]
    R_right_toe = walking_data(trial_right).Marker(iYRxToe, :) * 1000; % [mm]
    R_left_toe = walking_data(trial_right).Marker(iYLxToe, :) * 1000; % [mm]
    
    % Get GRF
    R_grf = walking_data(trial_right).Grf(iYGrf, :);
    R_cop_x = walking_data(trial_right).Grf(iXCop, :);
    R_cop_z = walking_data(trial_right).Grf(iZCop, :);
    
    % Get time vector
    R_marker_time = (0:n_marker_samples - 1) / s.KinFreq;
    R_grf_time = (0:n_grf_samples - 1) / s.GrfFreq;

    % Plot Right foot step
    figure
    plot(R_marker_time, R_left_heel, LineWidth=2, DisplayName="Left Heel")
    hold on
    grid on
    plot(R_marker_time, R_right_heel, LineWidth=2, DisplayName="Right Heel")
    plot(R_marker_time, R_left_toe, LineWidth=2, DisplayName="Left Toe")
    plot(R_marker_time, R_right_toe, LineWidth=2, DisplayName="Right Toe")
    plot(R_grf_time, R_grf, LineWidth=2, DisplayName="GRF")
    plot(R_grf_time, R_cop_x, LineWidth=2, DisplayName="COP X")
    plot(R_grf_time, R_cop_z, LineWidth=2, DisplayName="COP Z")
    legend
  
    title("Subject: " + num2str(subject) + ", IC Foot: Right",...
          "Height of both heels and toes as a function of time")
    ylabel("Height of heel and toe [mm]")
    xlim([0 R_marker_time(end)])
    xlabel("Time [sec]")


    IC_idx = 1;
    TO_idx = round(length(R_grf)*(s.KinFreq/s.GrfFreq));
    xticks([R_marker_time(IC_idx), R_marker_time(TO_idx)])
    xticklabels({"IC", "TO"})
    
    %% Left foot for comparison
    % Get markers
    L_right_heel = walking_data(trial_left).Marker(iYRxHeel, :) * 1000; % [mm]
    L_left_heel = walking_data(trial_left).Marker(iYLxHeel, :) * 1000; % [mm]
    L_right_toe = walking_data(trial_left).Marker(iYRxToe, :) * 1000; % [mm]
    L_left_toe = walking_data(trial_left).Marker(iYLxToe, :) * 1000; % [mm]
    
    % Get GRF
    L_grf = walking_data(trial_left).Grf(iYGrf, :);
    
    % Get time vector
    L_marker_time = (0:length(walking_data(trial_left).Marker) - 1) / s.KinFreq;
    
    % Cut left foot for comparison
    IC_idx = 1;
    TO_idx = round(length(L_grf)*(s.KinFreq/s.GrfFreq));
    cut_marker_time = L_marker_time(IC_idx:TO_idx);
    cut_left_heel = L_left_heel(IC_idx:TO_idx);
    cut_right_heel = L_right_heel(IC_idx:TO_idx);
    cut_left_toe = L_left_toe(IC_idx:TO_idx);
    cut_right_toe = L_right_toe(IC_idx:TO_idx);
    
    [~, R_min_idx] = min(R_left_heel);
    [~, L_min_idx] = min(cut_left_heel);
    skip_idx = R_min_idx - L_min_idx;
    
    plot(cut_marker_time + R_marker_time(skip_idx), cut_left_heel, '--', LineWidth=2, DisplayName="Left Heel (L)")
    plot(cut_marker_time + R_marker_time(skip_idx), cut_right_heel, '--', LineWidth=2, DisplayName="Right Heel (L)")
    plot(cut_marker_time + R_marker_time(skip_idx), cut_left_toe, '--', LineWidth=2, DisplayName="Left Toe (L)")
    plot(cut_marker_time + R_marker_time(skip_idx), cut_right_toe, '--', LineWidth=2, DisplayName="Right Toe (L)")
end
