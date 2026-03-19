% TEST_PLOT_SHANK_AND_THIGH_LENGTH :
% Loads raw motion-capture data for a selected participant and computes 
% right/left thigh (ASIS–knee) and shank (knee–ankle) lengths from 3-D marker 
% trajectories across all valid trials and walking speeds. Segment lengths are 
% plotted over time in a 2×2 layout with trials overlaid; bad trials are 
% excluded and lengths are converted to meters. Interactive data tips report 
% speed and trial number. For each subplot, the script computes the global min, 
% max, and mean and annotates the relative range ((max − min) / mean) × 100%.
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
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%%
% Choose a participant number - a number between 1 and 16
while true
    participant_number = input("Choose a participant number - a number between 1 and 16\n");
    if 1 <= participant_number && participant_number <= 16
        break;
    end
end

%%
% start the figure
figure
ax(1) = subplot(2, 2, 1);
title("right thigh length")
xlabel("Time [sec]")
ylabel("right thigh length [m]")
hold on
ax(2) = subplot(2, 2, 2);
title("left thigh length")
xlabel("Time [sec]")
ylabel("left thigh length [m]")
hold on
ax(3) = subplot(2, 2, 3);
title("right shank length")
xlabel("Time [sec]")
ylabel("right shank length [m]")
hold on
ax(4) = subplot(2, 2, 4);
title("left shank length")
xlabel("Time [sec]")
ylabel("left shank length [m]")
hold on

% Load the data:
participant_Data = load(fullfile(data_path, "Participant" + participant_number + "\Raw_Data.mat"));
participant_raw_Data = participant_Data.("Subject" + participant_number + "_raw");

% Get available speeds
available_speeds=zeros(1,7);
counter = 0;
for speed = [1 15 2 25 3 35 4]
    if length(fieldnames(participant_raw_Data.("V" + speed))) > 1
        counter = counter + 1;
        available_speeds(counter) = speed; 
    end
end
available_speeds=available_speeds(1:counter);

% Run on all the available speeds:
for speed = available_speeds
    trajectories_data = participant_raw_Data.("V" + speed).Trajectories;
    available_num_trials = length(trajectories_data);
    % Skip bad trials
    for num_trial=1:available_num_trials
        if (participant_number == 16) && ...
           (speed == 25) && ...
           ((num_trial == 5) || (num_trial == 6) || (num_trial == 7) || (num_trial == 8) || (num_trial == 9))
            continue
        end

        % Get the data of this single trial:
        single_trial_trajectories_data = trajectories_data{num_trial, 2};

        % Calculate the lengths:
        time = single_trial_trajectories_data.Time;

        % left ankle  -  [LLAX,   LLAY,   LLAZ]   -  left lateral ankle
        % left knee   -  [LLKX,   LLKY,   LLKZ]   -  left lateral knee
        % left ASIS   -  [LASISX, LASISY, LASISZ] -  left ASIS
        % right ankle -  [RLAX,   RLAY,   RLAZ]   -  right lateral ankle
        % right knee  -  [RLKX,   RLKY,   RLKZ]   -  right lateral knee
        % right ASIS  -  [RASISX, RASISY, RASISZ] -  right ASIS

        n = length(time);
        right_thigh_length = zeros(1,n);
        right_shank_length = zeros(1,n);
        left_thigh_length = zeros(1,n);
        left_shank_length = zeros(1,n);
        for i = 1:n
            right_thigh_length(i) = ...
                norm([single_trial_trajectories_data.RASISX(i) - single_trial_trajectories_data.RLKX(i);...
                      single_trial_trajectories_data.RASISY(i) - single_trial_trajectories_data.RLKY(i);...
                      single_trial_trajectories_data.RASISZ(i) - single_trial_trajectories_data.RLKZ(i)]); % [mm]
            left_thigh_length(i)  = ...
                norm([single_trial_trajectories_data.LASISX(i) - single_trial_trajectories_data.LLKX(i);...
                      single_trial_trajectories_data.LASISY(i) - single_trial_trajectories_data.LLKY(i);...
                      single_trial_trajectories_data.LASISZ(i) - single_trial_trajectories_data.LLKZ(i)]); % [mm]
            right_shank_length(i) = ...
                norm([single_trial_trajectories_data.RLAX(i) - single_trial_trajectories_data.RLKX(i);...
                      single_trial_trajectories_data.RLAY(i) - single_trial_trajectories_data.RLKY(i);...
                      single_trial_trajectories_data.RLAZ(i) - single_trial_trajectories_data.RLKZ(i)]); % [mm]
            left_shank_length(i)  = ...
                norm([single_trial_trajectories_data.LLAX(i) - single_trial_trajectories_data.LLKX(i);...
                      single_trial_trajectories_data.LLAY(i) - single_trial_trajectories_data.LLKY(i);...
                      single_trial_trajectories_data.LLAZ(i) - single_trial_trajectories_data.LLKZ(i)]); % [mm]
        end
        right_thigh_length = right_thigh_length / 1000; % [m]
        left_thigh_length = left_thigh_length / 1000;   % [m]
        right_shank_length = right_shank_length / 1000; % [m]
        left_shank_length = left_shank_length / 1000;   % [m]

        % plot the lengths as a function of time:

        % 1) right_thigh_length
        ax(1) = subplot(2, 2, 1);
        p = plot(time, right_thigh_length);
        p.UserData.speed = speed;
        p.UserData.trial = num_trial;

        % 2) left_thigh_length
        ax(2) = subplot(2, 2, 2);
        p = plot(time, left_thigh_length);
        p.UserData.speed = speed;
        p.UserData.trial = num_trial;

        % 3) right_shank_length
        ax(3) = subplot(2, 2, 3);
        p = plot(time, right_shank_length);
        p.UserData.speed = speed;
        p.UserData.trial = num_trial;

        % 4) left_shank_length
        ax(4) = subplot(2, 2, 4);
        p = plot(time, left_shank_length);
        p.UserData.speed = speed;
        p.UserData.trial = num_trial;
    end
end

% Now extract max/min/mean data from each subplot
for i = 1:4
    % Get line objects in this subplot
    lines = findall(ax(i), 'Type', 'line');
    all_y = [];
    for j = 1:length(lines)
        all_y = [all_y; lines(j).YData(:)];
    end
    % Calculate min/max for this subplot
    y_min(i) = min(all_y);
    y_max(i) = max(all_y);
    y_mean(i) = mean(all_y);

    % Add custom data tip info
    for j = 1:length(lines)
        N = length(lines(j).XData); % Number of data points
        speed_str = "v" + string(lines(j).UserData.speed);
        speed_vec = repmat({char(speed_str)}, 1, N);
        trial_vec = repmat(lines(j).UserData.trial, 1, N);
        lines(j).DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Speed', speed_vec);
        lines(j).DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial', trial_vec);
    end
end
 
subplot(2, 2, 1)
title("right thigh length : ((max - min) / mean) * 100% = " + num2str((y_max(1) - y_min(1))*100/mean(1)) + "%")
subplot(2, 2, 2)
title("left thigh length : ((max - min) / mean) * 100% = " + num2str((y_max(2) - y_min(2))*100/mean(1)) + "%")
subplot(2 ,2, 3)
title("right shank length : ((max - min) / mean) * 100% = " + num2str((y_max(3) - y_min(3))*100 / mean(1)) + "%")
subplot(2, 2, 4)
title("left shank length : ((max - min) / mean) * 100% = " + num2str((y_max(4) - y_min(4))*100 / mean(1)) + "%")
sgtitle("participant number " + participant_number)