% TEST_AXIS_DIRECTIONS :
% Explores and verifies coordinate-system consistency and walking direction in 
% gait data. For a selected subject and trial, the script plots GRF and COP 
% components to confirm axis definitions (walking, vertical, lateral), 
% visualizes COP trajectories in the walking–medial plane, and generates a 
% simple lower-limb animation from marker data as well as heel height data. 
% Finally, PSIS marker trajectories and COP signals are plotted for multiple 
% subjects and trials to validate walking direction consistency across the 
% dataset.
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = mfilename('fullpath'); % Full path of this script (MATLAB editor, VS Code, and batch)
if isempty(script_full_path)
    script_full_path = matlab.desktop.editor.getActiveFilename; % Fallback: evaluating a selection in the MATLAB editor
end
assert(~isempty(script_full_path), "Cannot determine script location. Run the whole file rather than a selection.")
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
% Choose which subject and trial to plot as an example
subject_number = 1;
trial_number = 1;

% Choose subjects and number of walking trials for multiple COP, GRF and PSIS
% Trajectory plots
subjects = [1 20 50]; % Subjects to plot
numTrials = [5 5 5]; % Number of trials for each subject to plot

%% Plot COP and GRF of Example Trial
% Loading example subject data
load(fullfile(data_path, "Subject" + subject_number + ".mat"))

% Make a vector with only the numbers of the walking trials:
walking_trials_numbers = find(arrayfun(@(x) strcmp(x.Task, 'Walking'), s.Data));
walking_trials = s.Data(walking_trials_numbers);

% Access data from the example trial
grf_data = walking_trials(trial_number).Grf(1:3, :);
cop_data = walking_trials(trial_number).Grf(4:6, :);
force_plate_time_vector = (0:size(grf_data, 2)-1) ./ (s.GrfFreq);

% plot the GRF data
figure
% x
subplot(3, 1, 1)
yline(0, '--k')
hold on
plot(force_plate_time_vector, grf_data(1,:), '.', 'linewidth', 2)
title("x - walking direction", "FontSize", 12)
ylabel('Force [N]')
xlabel('Time [s]')
% y
subplot(3, 1, 2)
yline(0, '--k')
hold on
plot(force_plate_time_vector, grf_data(2,:), '.', 'linewidth', 2)
title("y - up", "FontSize", 12)
ylabel('Force [N]')
xlabel('Time [s]')
% z
subplot(3, 1, 3)
yline(0, '--k')
hold on
plot(force_plate_time_vector, grf_data(3,:), '.', 'linewidth', 2)
title("z - latteral direction (by right hand rule)", "FontSize", 12)
ylabel('Force [N]')
xlabel('Time [s]')
sgtitle(sprintf("GRF\nSubject %d, Trial %d", subject_number, trial_number), "FontSize", 20)

% plot the COP data
figure
% x
subplot(3, 1, 1)
plot(force_plate_time_vector, cop_data(1,:), '.', 'linewidth', 2)
title("x - walking direction", "FontSize", 12)
ylabel('COP location [mm]')
xlabel('Time [s]')
% y
subplot(3, 1, 2)
plot(force_plate_time_vector, cop_data(2,:), '.', 'linewidth', 2)
title("y - up", "FontSize", 12)
ylabel('COP location [mm]')
xlabel('Time [s]')
% z
subplot(3, 1, 3)
plot(force_plate_time_vector, cop_data(3,:), '.', 'linewidth', 2)
title("z - latteral direction (by right hand rule)", "FontSize", 12)
ylabel('COP location [mm]')
xlabel('Time [s]')
sgtitle(sprintf("COP\nSubject %d, Trial %d", subject_number, trial_number), "FontSize", 20)

figure
psis_x = walking_trials(trial_number).Marker(7, :);
waling_direction = sign(psis_x(end) - psis_x(1));
plot(cop_data(1,:), waling_direction*cop_data(3,:), "*", 'linewidth', 2)
xlabel('COP location in walking direction [mm]')
ylabel('COP location in medial direction [mm]')
axis equal
title(sprintf("COP\nSubject %d, Trial %d", subject_number, trial_number), "FontSize", 20)

%% Plot Walking Animation for Example Trial
% Creating an animation of a walking trial as an example.
% Right/left ankle: 'X(R/L)xLatMal' , 'Y(R/L)xLatMal' , 'Z(R/L)xLatMal'
% Right/left knee: 'X(R/L)xLatCon' , 'Y(R/L)xLatCon' , 'Z(R/L)xLatCon'
% Right/Left heel: 'X(R/L)xHeel' , 'Y(R/L)xHeel' , 'Z(R/L)xHeel'
right_ankle = walking_trials(trial_number).Marker(64:66, :);
left_ankle  = walking_trials(trial_number).Marker(67:69, :);
right_knee  = walking_trials(trial_number).Marker(46:48, :);
left_knee   = walking_trials(trial_number).Marker(49:51, :);
right_heel  = walking_trials(trial_number).Marker(70:72, :);
left_heel   = walking_trials(trial_number).Marker(73:75, :);

% Timing parameters
dt = 1/s.KinFreq;
kinematic_time_vector = (0:size(right_ankle, 2)-1) ./ (s.KinFreq);

% make animation
figure
for idx=1:length(kinematic_time_vector)
    % draw the floor:
    plot([-1 3], [0 0], 'k', DisplayName="Floor")
    hold on

    % draw the right shank
    plot([right_heel(1, idx), right_ankle(1, idx), right_knee(1, idx)], ...
         [right_heel(2, idx), right_ankle(2, idx), right_knee(2, idx)], Color=[0 0.85 0], DisplayName="Right")
    
    % draw the left shank
    plot([left_heel(1, idx), left_ankle(1, idx), left_knee(1, idx)], ...
         [left_heel(2, idx), left_ankle(2, idx), left_knee(2, idx)], Color=[0.85 0 0], DisplayName="Left")
    hold off
    axis equal
    title("Knee-Ankle-Heel Walking Animation", "time: " + idx*dt + " [sec]")
    legend
    pause(0.01)
end

%% Heel Height
% perhaps we can identify the start of the double limb support by the height of 
% the left heel:
figure
plot(kinematic_time_vector, left_heel(2, :), Color=[0.85 0 0], DisplayName="Left")
hold on
plot(kinematic_time_vector, right_heel(2, :), Color=[0 0.85 0], DisplayName="Right")

title('Heel Height as a Function of Time')
ylabel("Heel Height [m]")
xlabel("Time [sec]")
legend

%% Test walking direction for multiple subjects
for subject_number=subjects
    % Loading example subject data
    load(fullfile(data_path, "Subject" + subject_number + ".mat"))
    
    % Check how many trials there are
    number_of_trials = length(s.Data);
    
    % Make a vector with only the numbers of the walking trials:
    walking_trials_numbers = find(arrayfun(@(x) strcmp(x.Task, 'Walking'), s.Data));
    walking_trials = s.Data(walking_trials_numbers);
    
    figure
    sgtitle("Subject " + subject_number)
    for trial_number=1:min(numTrials(sdx), length(walking_trials))
        % Access data from the trial
        grf_data = walking_trials(trial_number).Grf(1:3, :);
        cop_data = walking_trials(trial_number).Grf(4:6, :);
        psis_data = walking_trials(trial_number).Marker(31:33, :);
        force_plate_time_vector = (0:size(grf_data, 2)-1) ./ (s.GrfFreq);
        marker_time_vector = (0:size(psis_data, 2)-1) / (s.KinFreq);
        
        if strcmp(walking_trials(trial_number).Foot, 'RX')
            side = "Right";
        else
            side = "Left";
        end

        ax1 = subplot(3, 3, 1);
        plt = plot(ax1, force_plate_time_vector, grf_data(1, :));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector);
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector)));
        xlabel("time [s]")
        ylabel("x [N]")
        title("GRF")
        grid on
        hold on

        ax4 = subplot(3, 3, 4);
        plt = plot(ax4, force_plate_time_vector, grf_data(2, :));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector);
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector)));
        xlabel("time [s]")
        ylabel("y [N]")
        grid on
        hold on

        ax7 = subplot(3, 3, 7);
        plt = plot(ax7, force_plate_time_vector, grf_data(3, :));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector);
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector)));
        xlabel("time [s]")
        ylabel("z [N]")
        grid on
        hold on

        % COP
        ax2 = subplot(3, 3, 2);
        xlabel("time [s]")
        ylabel("x [mm]")
        title("COP")
        grid on
        hold on
        % is_in = ~isoutlier(cop_data(1, :));
        is_in = true(size(cop_data(1, :)));
        plt = plot(ax2, force_plate_time_vector(is_in), cop_data(1, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector(is_in))));

        ax5 = subplot(3, 3, 5);
        xlabel("time [s]")
        ylabel("y [mm]")
        grid on
        hold on
        % is_in = ~isoutlier(cop_data(2, :));
        is_in = true(size(cop_data(2, :)));
        plt = plot(ax5, force_plate_time_vector(is_in), cop_data(2, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector(is_in))));

        ax8 = subplot(3, 3, 8);
        xlabel("time [s]")
        ylabel("z [mm]")
        grid on
        hold on
        % is_in = ~isoutlier(cop_data(3, :));
        is_in = true(size(cop_data(3, :)));
        plt = plot(ax8, force_plate_time_vector(is_in), cop_data(3, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*force_plate_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(force_plate_time_vector(is_in))));

        % PSIS Trajectory
        ax3 = subplot(3, 3, 3);
        xlabel("samples")
        ylabel("x [m]")
        title("PSIS Trajectories")
        grid on
        hold on
        % is_in = ~isoutlier(psis_data(1, :));
        is_in = true(size(psis_data(1, :)));
        plt = plot(ax3, marker_time_vector(is_in), psis_data(1, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*marker_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(marker_time_vector(is_in))));

        ax6 = subplot(3, 3, 6);
        xlabel("samples")
        ylabel("y [m]")
        grid on
        hold on
        % is_in = ~isoutlier(psis_data(2, :));
        is_in = true(size(psis_data(2, :)));
        plt = plot(ax6, marker_time_vector(is_in), psis_data(2, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*marker_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(marker_time_vector(is_in))));

        ax9 = subplot(3, 3, 9);
        xlabel("samples")
        ylabel("z [m]")
        grid on
        hold on
        % is_in = ~isoutlier(psis_data(3, :));
        is_in = true(size(psis_data(3, :)));
        plt = plot(ax9, marker_time_vector(is_in), psis_data(3, is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trial_number + 0.*marker_time_vector(is_in));
        plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Side', side + strings(size(marker_time_vector(is_in))));

    end
end
