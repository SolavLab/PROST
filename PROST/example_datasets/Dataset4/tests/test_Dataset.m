%% Initialize script - DO NOT CHANGE
clearvars -except good_trials raw_data all_metadata -regexp ^Dataset\w*
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

% Load dataset for testing
if ~exist("Dataset_4", "var")
    load("../../Dataset_4.mat");
end
Dataset = Dataset_4;

% Dataset parameters information
dataset_ankle_marker_name = "ANK"; % Ankle marker name
dataset_knee_marker_name = "KNE"; % Knee marker name
dataset_n_steps = 3; % number of steps per trial
dataset_db_axis = ["x", "y", "z"]; % lab frame axis: [walking direction, other direction, up]
dataset_sides_uniform = ["right", "left"]; % side names in uniform format
dataset_sides_original = ["R", "L"]; % side names in original dataset
cmaps = dictionary("right", "summer", "left", "autumn"); % color maps for plotting sides

%% Input according to your test
% Which participant to test?
% Define:
% participants - list of participants to test. Leave empty to test all
% participants in the dataset.
% participants = [1 50 100 138];
prompt = "Which participant to test?\n" + ...
         "Define a list of participants to test.\n" + ...
         "Leave empty to test all participants in the dataset.\n";
participants = input(prompt);
n_participants = length(participants);


% Which trials to test?
% Either define:
% n_steps - the number of steps to test for both uniform format and processed
% original distributed equally for all steps of a participant for each side.
% Leave tests_uniform and tests_processed_orig empty.
% Or:
% tests_uniform - list of specific step numbers of each side from the
% uniform format data. Missing steps are ignored. 
% Example: tests_uniform.right = [1 2]. tests_uniform.left = [1 2]. 
% tests_processed_orig - list of specific trial numbers and step numbers
% for each of the trials from the processed original data. If empty, takes the 
% trials and steps equivalent to the steps chosen previously for the uniform 
% format data.
% Example: {1, [1 2]; 2 []}
% how_to_test_trials = 2;
% n_steps = 2;
% tests_uniform.right = [1 2]; % specific step numbers to test from the uniform format
% tests_uniform.left = [1 2]; % specific step numbers to test from the uniform format
% tests_processed_orig = {}; % specific trial numbers and step numbers to test
n_steps = 0;
tests_uniform = []; % specific step numbers to test from the uniform format
tests_processed_orig = {}; % specific trial numbers and step numbers to test
while true
    prompt = "Which trials to test?\n" + ...
             "1 - Define the number of steps to test for each side.\n" + ...
             "    Steps are evenly distributed.\n" + ...
             "    This is for both uniform format data and processed original data.\n" + ...
             "2 - Define lists of specific steps and trials to test for the uniform format data\n" + ...
             "    and the processed original data.\n";
    how_to_test_trials = input(prompt);
    if how_to_test_trials == 1
        prompt = "How mant steps to test for each side?\n" + ...
                 "If there are less steps for a particular participant, then tests all steps.\n";
        n_steps = input(prompt);
        break
    elseif how_to_test_trials == 2
        prompt = "Define a list of specific step numbers for each side of the uniform format.\n" + ...
                 "Missing steps are ignored.\n" + ...
                 "Example: [1 2 3].\n";
        fprintf(prompt);

        % specific step numbers for both sides to test from the uniform format data
        prompt = dataset_sides_uniform(1) + ":\n";
        tests_uniform.(dataset_sides_uniform(1)) = input(prompt);
        prompt = dataset_sides_uniform(2) + ":\n";
        tests_uniform.(dataset_sides_uniform(2)) = input(prompt);

        % specific trial numbers and step numbers to test from the processed original data
        prompt = "Define a list of specific trial numbers and step numbers (at most " + dataset_n_steps + " steps) for each of the trials from the processed original data.\n" + ...
                 "Leave empty to use the  trials and steps equivalent to the steps chosen previously for the uniform format data.\n" + ...
                 "You can also define trial numbers without step numbers to test all " + dataset_n_steps + " steps.\n" + ...
                 "Bad quality steps are ignored.\n" + ...
                 "Example: {1, [1 2]; 2 []; 3, [1]}\n";
        tests_processed_orig = input(prompt);
        break
    end
end
%% Loop over uniform format data
if isempty(participants)
    n_participants = numel(fieldnames(Dataset.Data));
    participants = 1:n_participants;
end

for particpant_num=participants % all participants
    participant_name = "participant_" + num2str(particpant_num); % participant name
    capitalized_participant_name = PROST.utils.capitalize(participant_name); % Capitalized participant name for printing

    % Figure settings
    f_uniform = figure(Name=capitalized_participant_name + " Uniform Format");
    t_uniform_outer = tiledlayout(f_uniform, 'TileSpacing', 'tight', 'Padding', 'tight');
    sgtitle(f_uniform, replace(f_uniform.Name, "_", " "));
    tile_counter = 0;

    if how_to_test_trials == 1
        for side=dataset_sides_uniform
            % Get step numbers to test
            total_steps = length(Dataset.Data.(participant_name).uniform_data.(side).step);
            if n_steps < total_steps
                tests_uniform.(side) = round(linspace(1, total_steps, n_steps));
            else
                tests_uniform.(side) = 1:total_steps;
            end
        end % side
    end % how_to_test_trials == 1

    % test all sides
    for side=dataset_sides_uniform
        capitalized_side = PROST.utils.capitalize(side); % Capitalized side for printing

        % Loop over test trials
        for step_num=tests_uniform.(side)
            % Get trial (if exists)
            try
                step = Dataset.Data.(participant_name).uniform_data.(side).step(step_num);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end

            % Time vector
            time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points

            % Data in global frame
            cop = step.COP;
            ankle = step.Markers.Ankle.lateral;
            knee = step.Markers.Knee.lateral;

            % Data in shank frame
            shank_cop = PROST.PROSTAnalyzer.convert_to_shank_frame(cop, knee, ankle);
            shank_ankle = PROST.PROSTAnalyzer.convert_to_shank_frame(ankle, knee, ankle);
            shank_knee = PROST.PROSTAnalyzer.convert_to_shank_frame(knee, knee, ankle);

            % Inner tile for pair of shank frame and world frame plots
            tile_counter = tile_counter + 1;
            t_uniform_inner = tiledlayout(t_uniform_outer, 1, 2, 'Padding', 'tight', 'TileSpacing','tight');
            t_uniform_inner.Layout.Tile = tile_counter;
            title(t_uniform_inner, "Participant " + particpant_num + ", Trial " + num2str(step_num) + " " + capitalized_side,  "Original Trial " + replace(step.source.original_trial, "_", " ") + ", Step " + step.source.step_number + ", FP" + step.source.plate_number)

            % Plot data in shank frame
            % Should look like this:
            %     ...
            %    .--.
            %     ..
            %     ..
            %     ..
            %     ..
            %     ..
            %     ..
            %     ..
            %     ::.
            %     ...
            %                     ...
            %                 .:=*+:.
            %  ....     .:--+++=-..
            % .-++++++++++-:..
            ax_shank = nexttile(t_uniform_inner, 1);
            colormap(ax_shank, cmaps(side));
            hold(ax_shank, 'on');
            grid(ax_shank, "on");
            axis(ax_shank, 'equal');
            pbaspect(ax_shank, [1 1 1]);
            h = gobjects(3, 1);
            X = [shank_ankle.u; shank_knee.u];
            Y = [shank_ankle.w; shank_knee.w];
            plot(ax_shank, X, Y, '-k');
            h(1) = scatter(ax_shank, shank_ankle.u, shank_ankle.w, 30, time, 'square', 'filled', DisplayName="Ankle");
            h(2) = scatter(ax_shank, shank_knee.u, shank_knee.w, 30, time, 'o', 'filled', DisplayName="Knee");
            h(3) = scatter(ax_shank, shank_cop.u, shank_cop.w, 30, time, '^', 'filled', DisplayName="Cop");
            % c = colorbar(ax_shank, "eastoutside");
            % c.Label.String = 'WA + SS %';
            title(ax_shank, "Shank Frame");
            xlabel(ax_shank, "x [mm]");
            ylabel(ax_shank, "z [mm]");
            legend(ax_shank, h, location='best');
            hold(ax_shank, 'off');


            % Plot data in world frame
            % Should look like this:
            % ::::::--=====--::::....
            % ::::::--=+%@%#*+=-------:::::::.
            % .::::-:=-*@@%#+==----::::::::..
            % ..::::.=+#@@%*+=-----::::::..
            %  .:-:..=*@@@%*===---:-::..
            %  ..:-=-+*@@@#++=-----:..
            %   .:::=+%@@%*++===-:
            %   .:-=-+@@@%*+++-.
            %    .--=#@@@%*=..
            %    .:=+%@@*:.
            %     :-+@#:
            %     .-+*.
            ax_world = nexttile(t_uniform_inner, 2);
            colormap(ax_world, cmaps(side));
            hold(ax_world, 'on');
            grid(ax_world, "on");
            axis(ax_world, 'tight');
            axis(ax_world, 'equal');
            h = gobjects(3, 1);
            X = [ankle.x; knee.x];
            Y = [ankle.z; knee.z];
            plot(ax_world, X, Y, '-k');
            h(1) = scatter(ax_world, ankle.x, ankle.z, 30, time, 'square', 'filled', DisplayName="Ankle");
            h(2) = scatter(ax_world,knee.x, knee.z, 30, time, 'o', 'filled', DisplayName="Knee");
            h(3) = scatter(ax_world, cop.x, 0*cop.y, 30, time, '^', 'filled', DisplayName="CoP");
            c = colorbar(ax_world, "eastoutside");
            c.Label.String = 'WA + SS %';
            title(ax_world, "World Frame")
            xlabel(ax_world, "x [mm]")
            ylabel(ax_world, "z [mm]")
            legend(ax_world, h, location='best');
            hold(ax_world, 'off');

            % linkaxes([ax_shank ax_world], 'y');
        end % trial_num
    end % side
end % particpant_num

%% Loop over processed original data
if isempty(participants)
    n_participants = numel(fieldnames(Dataset.Data));
    participants = 1:n_participants;
end

for particpant_num=participants
    participant_name = "participant_" + num2str(particpant_num);
    capitalized_participant_name = PROST.utils.capitalize(participant_name); % Capitalized participant name for printing

    % Figure Settings
    f_orig = figure(Name=capitalized_participant_name + " Processed Original");
    % f_fp = figure(Name=capitalized_participant_name + " Forceplate Data");
    t_orig_outer = tiledlayout(f_orig, 'TileSpacing', 'tight', 'Padding', 'tight');
    % t_fp = tiledlayout(f_fp, 'TileSpacing', 'tight', 'Padding', 'tight');
    sgtitle(f_orig, replace(f_orig.Name, "_", " "));
    % sgtitle(f_fp, replace(f_fp.Name, "_", " "));
    tile_counter = 0;

    % Get trial numbers of all test trials (if exist)
    if isempty(tests_processed_orig)
        test_trials = {};
        for side=dataset_sides_uniform
            for step_num=tests_uniform.(side)
                try
                    trial_num = Dataset.Data.(participant_name).uniform_data.(side).step(step_num).source.original_trial_number_in_database;
                    step_num = Dataset.Data.(participant_name).uniform_data.(side).step(step_num).source.step_number;
                catch ME
                    if ME.identifier == 'MATLAB:badsubscript'
                        continue;
                    end
                end % try
                test_trials(end+1, :) = {trial_num, step_num};
            end % idx=tests_uniform.(side)
        end % side=dataset_sides_uniform
    else % isempty(tests_processed_orig)
        test_trials = tests_processed_orig;
        for trial_num=[test_trials{:, 1}]
            if isempty(test_trials{trial_num, 2})
                test_trials{trial_num, 2} = 1:dataset_n_steps;
            end
        end % trial_num
    end % isempty(tests_processed_orig)

    for tdx=1:size(test_trials, 1)
        trial_num = test_trials{tdx, 1};
        step_nums = test_trials{tdx, 2};
        trial = Dataset.Data.(participant_name).processed_original_data.trial(trial_num);
        for step_num=step_nums
            % Get step info
            step_info = trial.("step_" + step_num + "_info");
            
            % Only plot good quality steps
            if strcmp(step_info.step_quality, "bad")
                disp(participant_name + " Trial: " + trial_num + " Step: " + step_num + " bad!")
                continue
            end

            % Get step parameters
            side = step_info.foot;
            side_prefix = dataset_sides_original(strcmp(side, dataset_sides_uniform));
            capitalized_side = PROST.utils.capitalize(side); % For printing side name

            % Indices of step events
            IC_index_grf = step_info.events.IC.forceplate_index;
            IC_index_traj = step_info.events.IC.trajectory_index;
            IC_time = step_info.events.IC.time;
            OIC_index_grf = step_info.events.OIC.forceplate_index;
            OIC_index_traj = step_info.events.OIC.trajectory_index;
            OIC_time = step_info.events.OIC.time;
            TO_index_grf = step_info.events.TO.forceplate_index;
            TO_index_traj = step_info.events.TO.trajectory_index;
            TO_time = step_info.events.TO.time;
    
            % Time vectors
            forceplate_time = trial.GRF.time_vector.value; % Time vector for force-plate data
            marker_time = trial.trajectories.time_vector.value; % Time vector for marker data
            
            % Get processed original data before temporal alignment
            cop = trial.COP.("plate_" + step_info.plate);
            cop_unit = trial.COP.unit;
            grf = trial.GRF.("plate_" + step_info.plate);
            grf_unit = trial.GRF.unit;
            ankle = trial.trajectories.(side_prefix + dataset_ankle_marker_name);
            knee = trial.trajectories.(side_prefix + dataset_knee_marker_name);
            trajectory_unit = trial.trajectories.unit;
            wd = trial.walking_direction.value; % walking direction

            % Cut data to IC-OIC segment and unify measurement units
            cut_cop.x = PROST.utils.convert_units(cop.x(IC_index_grf:OIC_index_grf), cop_unit, "mm");
            cut_cop.y = PROST.utils.convert_units(cop.y(IC_index_grf:OIC_index_grf), cop_unit, "mm");
            cut_cop.z = PROST.utils.convert_units(cop.z(IC_index_grf:OIC_index_grf), cop_unit, "mm");
            cut_ankle.x = PROST.utils.convert_units(ankle.x(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_ankle.y = PROST.utils.convert_units(ankle.y(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_ankle.z = PROST.utils.convert_units(ankle.z(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_knee.x = PROST.utils.convert_units(knee.x(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_knee.y = PROST.utils.convert_units(knee.y(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_knee.z = PROST.utils.convert_units(knee.z(IC_index_traj:OIC_index_traj), trajectory_unit, "mm");
            cut_grf.x = grf.x(IC_index_grf:TO_index_grf);
            cut_grf.y = grf.y(IC_index_grf:TO_index_grf);
            cut_grf.z = grf.z(IC_index_grf:TO_index_grf);
            cut_forceplate_time = forceplate_time(IC_index_grf:TO_index_grf);

            % Inner tile for triplet of world frame and force plate data
            % plots
            tile_counter = tile_counter + 1;
            t_orig_inner = tiledlayout(t_orig_outer, 2, 2, 'Padding', 'tight', 'TileSpacing','tight');
            t_orig_inner.Layout.Tile = tile_counter;
            title(t_orig_inner, "Participant " + particpant_num + ", Trial " + trial_num + ", Step " + step_num + " (" + capitalized_side + ")",  "Original Trial " + trial.origin.trial_number + ", FP" + step_info.plate)

            % Plot processed original data before temporal alignment
            % Should look like this:
            % ::::::--=====--::::....         
            % ::::::--=+%@%#*+=-------:::::::.
            % .::::-:=-*@@%#+==----::::::::.. 
            % ..::::.=+#@@%*+=-----::::::..   
            %  .:-:..=*@@@%*===---:-::..      
            %  ..:-=-+*@@@#++=-----:..        
            %   .:::=+%@@%*++===-:            
            %   .:-=-+@@@%*+++-.              
            %    .--=#@@@%*=..                
            %    .:=+%@@*:.                   
            %     :-+@#:                      
            %     .-+*.                       
            ax_orig_world = nexttile(t_orig_inner, 1);
            hold(ax_orig_world, 'on');
            grid(ax_orig_world, "on");
            axis(ax_orig_world, 'tight');
            axis(ax_orig_world, 'equal');
            h = gobjects(3, 1);
            X = wd.*[cut_ankle.(dataset_db_axis(1)); cut_knee.(dataset_db_axis(1))];
            Y = [cut_ankle.(dataset_db_axis(3)); cut_knee.(dataset_db_axis(3))];
            plot(ax_orig_world, X, Y, '-k');        
            h(1) = plot(ax_orig_world, wd.*cut_ankle.(dataset_db_axis(1)), cut_ankle.(dataset_db_axis(3)), LineStyle="none", Marker='square', MarkerSize=8, DisplayName="Ankle");
            h(1).MarkerFaceColor = h(1).Color;
            h(2) = plot(ax_orig_world, wd.*cut_knee.(dataset_db_axis(1)), cut_knee.(dataset_db_axis(3)), LineStyle="none", Marker='o', MarkerSize=8, DisplayName="Knee");
            h(2).MarkerFaceColor = h(2).Color;
            h(3) = plot(ax_orig_world, wd.*cut_cop.(dataset_db_axis(1)), 0.*cut_cop.(dataset_db_axis(1)), LineStyle="none", Marker='^', MarkerSize=8, DisplayName="CoP");
            h(3).MarkerFaceColor = h(3).Color;
            t = title(ax_orig_world, "World Frame", Units="normalized");
            t.Position = [t.Position(2) t.Position(1) t.Position(3)];
            t.Rotation = -90;
            xlabel(ax_orig_world, "x [mm]");
            ylabel(ax_orig_world, "z [mm]");
            legend(ax_orig_world, h, location='best');
            hold(ax_orig_world, 'off');
            
            % Plot force plate data - CoP
            % Should look like this:                                 
            %  .:.                                          
            %  :+=-+:.......   ..                           
            % .:++*****++***+++=+-::....                    
            %    ...:===--==++=+********+=::::.             
            %                     ..:---=++****+++===+=:.   
            %                             ...-+-+*++++-:.   
            ax_cop = nexttile(t_orig_inner, 3, [1 2]);
            hold(ax_cop, 'on');
            grid(ax_cop, "on");
            axis(ax_cop, 'tight');
            axis(ax_cop, 'equal');
            h = gobjects(3, 1);
            h(1) = plot(ax_cop, wd.*cut_cop.(dataset_db_axis(1)), cut_cop.(dataset_db_axis(2)),LineStyle="none", Marker='^', MarkerSize=8, DisplayName="CoP");
            h(1).MarkerFaceColor = h(1).Color;
            h(2) = plot(ax_cop, wd.*cop.(dataset_db_axis(1))(IC_index_grf), cop.(dataset_db_axis(2))(IC_index_grf), LineStyle="none", Marker='o', MarkerSize=8, DisplayName="IC");
            h(2).MarkerFaceColor = h(2).Color;
            h(3) = plot(ax_cop, wd.*cop.(dataset_db_axis(1))(OIC_index_grf), cop.(dataset_db_axis(2))(OIC_index_grf), LineStyle="none", Marker='o', MarkerSize=8, DisplayName="OIC");
            h(3).MarkerFaceColor = h(3).Color;
            plot(ax_cop, 0, 0, 'ok', MarkerSize=8);
            t = title(ax_cop, "CoP", Units="normalized");
            t.Position = [t.Position(2) t.Position(1) t.Position(3)];
            t.Rotation = -90;
            xlabel(ax_cop, dataset_db_axis(1) + " [" + cop_unit + "]");
            ylabel(ax_cop, dataset_db_axis(2) + " [" + cop_unit + "]");
            legend(ax_cop, h, location='best');
            hold(ax_cop, 'off');

            % linkaxes([ax_orig ax_cop], 'x');

            % Plot force plate data - GRF
            % Should look like this:
            %
            %
            %
            ax_grf = nexttile(t_orig_inner, 2);
            hold(ax_grf, 'on');
            grid(ax_grf, "on");
            h = gobjects(6, 1);
            h(1) = plot(ax_grf, cut_forceplate_time, cut_grf.(dataset_db_axis(1)), LineWidth=2, DisplayName="GRF " + dataset_db_axis(1));
            h(2) = plot(ax_grf, cut_forceplate_time, cut_grf.(dataset_db_axis(2)), LineWidth=2, DisplayName="GRF " + dataset_db_axis(2));
            h(3) =  plot(ax_grf, cut_forceplate_time, cut_grf.(dataset_db_axis(3)), LineWidth=2, DisplayName="GRF " + dataset_db_axis(3));
            h(4) = xline(ax_grf, IC_time, '-k', LineWidth=1, DisplayName="IC");
            h(5) = xline(ax_grf, OIC_time, '-.k', LineWidth=1, DisplayName="OIC");
            h(6) = xline(ax_grf, TO_time, '--k', LineWidth=1, DisplayName="TO");
            yline(ax_grf, 0, '-k', LineWidth=1);
            t = title(ax_grf, "GRF", Units="normalized");
            t.Position = [t.Position(2) t.Position(1) t.Position(3)];
            t.Rotation = -90;
            xlabel(ax_grf, "Time [s]");
            ylabel(ax_grf, "Force [" + grf_unit + "]");
            legend(ax_grf, h, location='best');
            hold(ax_grf, 'off');
        end % step_num
    end % tdx
end % participant_num
