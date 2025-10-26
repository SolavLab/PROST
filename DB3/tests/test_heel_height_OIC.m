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
close all
clear variables
clc

addpath("..\Data files")
addpath("..\auxiliary functions")
addpath(genpath("..\..\Helper Functions"))

%%
for threshold_shift=[0 0.02 0.025 0.03 0.035 0.04]
    for participant_number=[6]
        load("Data files\Subject" + num2str(participant_number) + ".mat")
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
        trials = [right_trial_index left_trial_index];
    
        % Get the number of walking trials
        n_trials = length(trials);
    
        f1 = figure(Name="Heel Height and COP_P" + participant_number + "_Shift_" + threshold_shift*1000 + "[mm]");
        main_layout = tiledlayout(f1, 1, n_trials);
        sgtitle(f1, "Heel Height & COP: P" + participant_number + ", Shift: " + threshold_shift*1000 + " [mm]")
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
            [~, step_info.events.TO.trajectory_index] = min(abs(step_info.events.TO.time - markers_times_vector));
           
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
            [~, step_info.events.OIC.forceplate_index] = find_index(grf_times_vector, step_info.events.OIC.time);
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
            plot(ax1, markers_times_vector, markers_3d_location_data(strmatch("YLxHeel", s.MarkerVarName), :), 'b', LineWidth=2, DisplayName="Left Heel")
            plot(ax1, markers_times_vector, markers_3d_location_data(strmatch("YRxHeel", s.MarkerVarName), :), 'r', LineWidth=2, DisplayName="Right Heel")
            yline(ax1, heel(OIC_index_traj), 'k', LineWidth=2, DisplayName="OIC threshold")
            xline(ax1, OIC_time, '--', LineWidth=2, Color="#77AC30", DisplayName="OIC time")
            xline(ax1, IC_time, '--', LineWidth=2, Color="#7E2F8E", DisplayName="IC time")
            xline(ax1, TO_time, '--', LineWidth=2, Color="#EDB120", DisplayName="TO time")
            title(ax1, "Trial " + trial_number + ", IC Foot: " + foot)
            ylabel(ax1, "heel height [mm]")
            legend(ax1, Location="best")
            
            ax2 = nexttile(child_layout);
            hold(ax2, "on")
            grid(ax2, "on")
            plot(ax2, grf_times_vector, cop_data(1, :), 'b', LineWidth=2, DisplayName="COP X")
            plot(ax2, grf_times_vector, cop_data(3, :), 'r', LineWidth=2, DisplayName="COP Z")
            xline(ax2, OIC_time, '--', LineWidth=2, Color="#77AC30", DisplayName="OIC time")
            xline(ax2, IC_time, '--', LineWidth=2, Color="#7E2F8E", DisplayName="IC time")
            xline(ax2, TO_time, '--', LineWidth=2, Color="#EDB120", DisplayName="TO time")
            ax2.XLim = ax1.XLim;
            ax2.XTick = ax1.XTick;
            ax2.XTickLabel = ax1.XTickLabel;
            xlabel(ax2, "time [s]")
            ylabel(ax2, "COP [mm]")
            legend(ax2, Location="best")
            linkaxes([ax1, ax2], 'x')
        end
    end
end