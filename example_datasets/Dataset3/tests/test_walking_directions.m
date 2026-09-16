% TEST_WALKING_DIRECTIONS
% Evaluates walking direction consistency across subjects and trials. For each 
% walking trial, direction is determined from the sign of PSIS 
% anterior–posterior displacement. Trials identified as backward walking 
% (negative direction) are flagged and visualized with GRF, CoP, and PSIS 
% trajectories to support inspection and validation.
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

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

%%
subjects = 1:50;
n_subjects = length(subjects);
walking_directions = cell(n_subjects, 1);
for s_idx=1:n_subjects
    subject_number = subjects(s_idx);
    % Loading example subject data
    load(fullfile(data_path, "Subject" + subject_number + ".mat"))

    % Check how many trials there are
    number_of_trials = length(s.Data);
    
    % Make a vector with only the numbers of the walking trials:
    walking_trials_numbers = find(arrayfun(@(x) strcmp(x.Task, 'Walking'), s.Data));
    walking_trials = s.Data(walking_trials_numbers);

    n_trials = length(walking_trials);
    walking_directions{s_idx} = zeros(n_trials, 1);

    for trial_number=1:n_trials
        psis_x = walking_trials(trial_number).Marker(31, :);
        waling_direction = sign(psis_x(end) - psis_x(1));
        walking_directions{s_idx}(trial_number) = sign(psis_x(end) - psis_x(1));

        % Plot Trial where subject walked backwords
        if walking_directions{s_idx}(trial_number) < 0
            % Access data from the trial
            grf_data = walking_trials(trial_number).Grf(1:3, :);
            cop_data = walking_trials(trial_number).Grf(4:6, :);
            psis_data = walking_trials(trial_number).Marker(31:33, :);
            force_plate_time_vector = (0:size(grf_data, 2)-1) ./ (s.GrfFreq);
            marker_time_vector = (0:size(psis_data, 2)-1) / (s.KinFreq);

            f = figure(Name="Subject " + subject_number + " Trial: " + trial_number);
            sgtitle(f, f.Name)
            % GRF
            subplot(3, 3, 1)
            plot(force_plate_time_vector, grf_data(1, :))
            hold on
            grid on
            title("GRF")
            xlabel("time [s]")
            ylabel("x [N]")

            subplot(3, 3, 4)
            plot(force_plate_time_vector, grf_data(2, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("y [N]")

            subplot(3, 3, 7)
            plot(force_plate_time_vector, grf_data(3, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("z [N]")

            % CoP
            subplot(3, 3, 2)
            plot(force_plate_time_vector, cop_data(1, :))
            hold on
            grid on
            title("CoP")
            xlabel("time [s]")
            ylabel("x [mm]")

            subplot(3, 3, 5)
            plot(force_plate_time_vector, cop_data(2, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("y [mm]")

            subplot(3, 3, 8)
            plot(force_plate_time_vector, cop_data(3, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("z [mm]")

            % PSIS Trajectory
            subplot(3, 3, 3)
            plot(marker_time_vector, psis_data(1, :))
            hold on
            grid on
            title("PSIS Trajectory")
            xlabel("time [s]")
            ylabel("x [m]")

            subplot(3, 3, 6)
            plot(marker_time_vector, psis_data(2, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("y [m]")

            subplot(3, 3, 9)
            plot(marker_time_vector, psis_data(3, :))
            hold on
            grid on
            xlabel("time [s]")
            ylabel("z [m]")

            disp(f.Name)
        end
    end  
end