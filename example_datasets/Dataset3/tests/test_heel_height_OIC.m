% TEST_HEEL_OIC :
% Tests the get_OIC_threshold function
% Opposite initial contact between IC and TO.
% We estimate it as the time where the other foot reaches the height 
% threshold for the first time.
% The process of estimation is:
% 1. Identify the foot of the first step.
% 2. Calculate OIC_threshold (average heel height at IC of all trials of
%    opposite foot).
% 3. Use that height as the threshold of the heel height denoting 
%    OIC for this trial.
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

% Add path to get_OIC_thresholds function
addpath("../");

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%%
plot_color = dictionary(["right" "left"], {[1 0 0], [0 1 0]});
for threshold_shift=[0.025] %[0 0.02 0.025 0.03 0.035 0.04]
    for participant_number=[6]
        load(fullfile(data_path, "Subject" + participant_number + ".mat"))
        n_markers = size(s.MarkerVarName, 1);
        n_grf = size(s.GrfVarName, 1);
    
        % Only use walking data
        walking_data = s.Data(matches({s.Data.Task}, 'Walking'));
        
        % Trial 9 of participant 40 has missing marker measurements so we
        % replace with NaNs to keep the marker number consistent
        if participant_number == 40
            walking_data(9).Marker = [walking_data(9).Marker;...
                                      nan + walking_data(9).Marker(1:3, :)];
        end
        
        % Get OIC heel height thresholds
        [right_OIC_threshold, left_OIC_threshold] = get_OIC_thresholds(walking_data, s.MarkerVarName, threshold_shift);
        right_OIC_threshold = right_OIC_threshold*1000; % convert to[mm]
        left_OIC_threshold = left_OIC_threshold*1000; % convert to [mm]
        
        % Find left and right trials
        feet = string({walking_data.Foot});
        right_trial_index = find(feet == "RX", 1, 'first');
        left_trial_index = find(feet == "LX", 1, 'first');
        trials = [left_trial_index right_trial_index];
    
        % Get the number of walking trials
        n_trials = length(trials);
    
        f1 = figure(Name="Heel Height and GRF_P" + participant_number + "_Shift_" + threshold_shift*1000 + " mm");
        main_layout = tiledlayout(f1, 1, n_trials);
        sgtitle(f1, "Heel Height & GRF: P" + participant_number + ", Shift: " + threshold_shift*1000 + " [mm]")
        for i=1:n_trials
            trial_number = trials(i);
            % Samples in trial
            n_marker_samples = size(walking_data(trial_number).Marker, 2);
            n_grf_samples = size(walking_data(trial_number).Grf, 2);
    
            % Time vectors of trial
            markers_times_vector = (0:n_marker_samples - 1)/s.KinFreq;
            grf_times_vector = (0:n_grf_samples - 1)/s.GrfFreq;
    
            % Signals
            markers_3d_location_data = walking_data(trial_number).Marker; % [m]
            markers_3d_location_data = markers_3d_location_data * 1000; % convert to [mm]
            grf_data = walking_data(trial_number).Grf(contains(string(s.GrfVarName), 'GRF'), :);
            cop_data = walking_data(trial_number).Grf(contains(string(s.GrfVarName), 'Cop'), :);
            
            % Foot
            if strcmp(walking_data(trial_number).Foot, 'RX')
                step_info.foot = 'right';
                other_foot = 'Lx';
                OIC_threshold = left_OIC_threshold;

            elseif strcmp(walking_data(trial_number).Foot, 'LX')
                step_info.foot = 'left';
                other_foot = 'Rx';
                OIC_threshold = right_OIC_threshold;
            else
                error("All trials should be good so there should be no missing foot.")
            end
            
            % Initial contact
            step_info.events.IC.time = 0;
            step_info.events.IC.forceplate_index = 1;
            step_info.events.IC.trajectory_index = 1;
            
            % Toe off
            step_info.events.TO.time = grf_times_vector(end);
            step_info.events.TO.forceplate_index = n_grf_samples;
            step_info.events.TO.trajectory_index = PROST.utils.find_index_from_value(markers_times_vector, step_info.events.TO.time);
           
            % Heel Height
            heel_idx = strmatch("Y" + other_foot + "Heel", s.MarkerVarName, 'exact');
            heel = markers_3d_location_data(heel_idx, :);
            
            % Find where the heel starts descending
            d_heel = diff(heel); d_heel(end+1) = d_heel(end);
            start_descent = find(d_heel < 0, 1, 'first');
    
            % Find first 2 indices where heel reaches the threshold, in case
            % the first one is at the IC.
            OIC_indices = start_descent - 1 + find(heel(start_descent:end) <= OIC_threshold, 2, 'first');
    
            % If the heel height doesn't reach the threshold, use the minimum
            % instead
            if isempty(OIC_indices)
                OIC_threshold = min(heel);
                OIC_indices = start_descent - 1 + find(heel(start_descent:end) <= OIC_threshold, 2, 'first');
            end
            
            % If the first time the threshold was reached was at IC, use the
            % second index.
            if OIC_indices(1) == 1
                OIC_index_traj = OIC_indices(2);
            else
                OIC_index_traj = OIC_indices(1);
            end
    
            step_info.events.OIC.time = markers_times_vector(OIC_index_traj);
            step_info.events.OIC.forceplate_index = PROST.utils.find_index_from_value(grf_times_vector, step_info.events.OIC.time);
            step_info.events.OIC.trajectory_index = OIC_index_traj;
    
            IC_time = step_info.events.IC.time;
            OIC_time = step_info.events.OIC.time;
            TO_time = step_info.events.TO.time;
            foot = step_info.foot;
    
            % nexttile(main_layout);
            child_layout = tiledlayout(main_layout, 'vertical');
            child_layout.Layout.Tile = i;
            ax1 = nexttile(child_layout);
            hold(ax1, "on")
            grid(ax1, "on")
            plot(ax1, markers_times_vector, markers_3d_location_data(strmatch("YLxHeel", s.MarkerVarName), :), Color=plot_color{"left"}, LineWidth=1.5, DisplayName="Left Heel")
            plot(ax1, markers_times_vector, markers_3d_location_data(strmatch("YRxHeel", s.MarkerVarName), :), Color=plot_color{"right"}, LineWidth=1.5, DisplayName="Right Heel")
            yline(ax1, heel(OIC_index_traj), 'k', LineWidth=1.5, DisplayName="OIC threshold")
            xline(ax1, OIC_time, '--', LineWidth=1.5, Color="#0072BD", DisplayName="OIC time")
            xline(ax1, IC_time, '--', LineWidth=1.5, Color="#7E2F8E", DisplayName="IC time")
            xline(ax1, TO_time, '--', LineWidth=1.5, Color="#EDB120", DisplayName="TO time")
            title(ax1, "Trial " + trial_number + ", IC Foot: " + foot)
            ylabel(ax1, "Heel Height [mm]")
            
            
            ax2 = nexttile(child_layout);
            hold(ax2, "on")
            grid(ax2, "on")
            plot(ax2, grf_times_vector, grf_data(2, :), Color=plot_color{step_info.foot}, LineWidth=1.5, DisplayName="GRF")
            % plot(ax2, grf_times_vector, cop_data(1, :), 'b', LineWidth=1.5, DisplayName="CoP X")
            % plot(ax2, grf_times_vector, cop_data(3, :), 'r', LineWidth=1.5, DisplayName="CoP Z")
            xline(ax2, OIC_time, '--', LineWidth=1.5, Color="#0072BD", DisplayName="OIC time")
            xline(ax2, IC_time, '--', LineWidth=1.5, Color="#7E2F8E", DisplayName="IC time")
            xline(ax2, TO_time, '--', LineWidth=1.5, Color="#EDB120", DisplayName="TO time")
            xlabel(ax2, "Time [s]")
            ylabel(ax2, "GRF [N]")
            linkaxes([ax1, ax2], 'x')

            if i == 1
                lgd=legend(ax1, Location="westoutside");
            end
        end
    end
end