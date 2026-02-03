clearvars -except DB_1 
close all; 
clc

addpath("C:\Users\chenr\Documents\PROST\")
addpath("C:\Users\chenr\Documents\PROST\DB1\")

set(0, 'DefaultFigureWindowStyle', 'alwaysontop');

if ~exist("DB_1", "var")
    load("DB_1.mat");
end

%% Change accordingly to your test
% What database to test
DB = DB_1;

% Database relevant marker names
ankle_marker_name = "LA";
knee_marker_name = "LK";
% Database parameters
step_nums.right = [1 3]; % number of steps per trial (right)
step_nums.left = 2; % number of steps per trial (left)
steps_feet = ["right" "left" "right"]; % the feet per trial
db_axis = ["y", "x", "z"]; % lab frame axis: [walking direction, other direction, up]
sides.uniform = ["right", "left"];
sides.processed_original = ["R", "L"]; % How are the sides delineated in the database
cmaps = dictionary("right", "green", "left", "red");

%% Which participants and trials to test?
% A cell array listing each participant and each trial for that participant to
% test.
% The cell array has the format
% {participant_number, [uniform_trial_numbers], [uniform_trial_sides]}
% Example:
% {1, [1 2 3], ["right"]; 2, [1 2], ["right" left"]}
tests = {1, [104], ["right"]};


% If you don't want to choose a specific trial for each participant, leave it
% empty and choose the number of trials to test instead and the script will
% choose trials spaced equally as that number.
n_trials = 10;

%% Check Shank Frame Transformation
% close all
participants = [tests{:, 1}];
n_participants = length(participants);

for p=1:n_participants
    % Get test parameters
    particpant_num = participants(p);
    participant_name = "participant_" + num2str(particpant_num);
    trials_test_processsed = tests{p, 2};
    test_sides = tests{p, 3};
    if isempty(test_sides)
        test_sides = ["left" "right"];
    end
    if isempty(trials_test_processsed)
        total_trials = min(length(DB.Data.(participant_name).uniform_data.(test_sides(1)).step), length(DB.Data.(participant_name).uniform_data.(test_sides(end)).step));
        if n_trials < total_trials
            trials = round(linspace(1, total_trials, n_trials));
        else
            trials = 1:total_trials;
        end
    else
        trials = trials_test_processsed;
    end

    % Plot trials
    f = figure(Name=participant_name + " Shank Frame");
    tiledlayout(f, "flow")
    for t=trials
        for side=test_sides
            try
                trial = DB.Data.(participant_name).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end

            % Time vector
            time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points

            % Get COP in shank coordinate frame
            shank_cop = PROST.PROSTAnalyzer.cop_to_shank_frame(trial, "lateral");
            nexttile
            % X = [0; knee.x];
            % Y = [0; knee.z];
            % plot(X, Y, '-k')
            % hold on;
            % axis square;
            % scatter(ankle.x, ankle.z, 30, time, 'square', 'filled')
            % scatter(knee.x, knee.z, 30, time, 'o', 'filled')
            scatter(shank_cop.x, shank_cop.z, 30, time, '^', 'filled', DisplayName=side)
            hold on
            axis equal
            title(PROST.utils.capitalize(side) + ": P" + p + " Trial " + num2str(t), replace(trial.source.original_trial, "_", " "))

        end
        legend
    end
    colorbar('east')
end

%% Loop over uniform data
% close all
for p=1:n_participants
    % Get test parameters
    particpant_num = participants(p);
    participant_name = "participant_" + num2str(particpant_num);
    trials_test_processsed = tests{p, 2};
    test_sides = tests{p, 3};
    if isempty(test_sides)
        test_sides = ["left" "right"];
    end
    
    % Plot trials
    f = figure(Name=participant_name + " Uniform");
    tiledlayout(f, "flow")
    for side=test_sides
        if isempty(trials_test_processsed)
            total_trials = length(DB.Data.(participant_name).uniform_data.(side).step);
            if n_trials < total_trials
                trials = round(linspace(1, total_trials, n_trials));
            else
                trials = 1:total_trials;
            end
        else
            trials = trials_test_processsed;
        end

        for t=trials
            try
                trial = DB.Data.(participant_name).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end

            % Time vector
            time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points

            % Get COP and lateral ankle, knee trajectories after temporal alignment
            COP = trial.COP;
            ankle = trial.Markers.Ankle.lateral;
            knee = trial.Markers.Knee.lateral;

            % Check ankle-knee trajectories in space.
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
            nexttile
            X = [ankle.x; knee.x];
            Y = [ankle.z; knee.z];
            plot(X, Y, '-k')
            hold on;
            axis square;
            scatter(ankle.x, ankle.z, 30, time, 'square', 'filled')
            scatter(knee.x, knee.z, 30, time, 'o', 'filled')
            scatter(COP.x, 0.*COP.x, 30, time, '^', 'filled')
            title(PROST.utils.capitalize(side) + ": P" + p + " Trial " + num2str(t), replace(trial.source.original_trial, "_", " "))
            xlabel("x [mm]")
            ylabel("z [mm]")
            hold off
        end
        sgtitle(replace(string(f.Name), "_", " "))
    end
    colorbar('east')
end

%% Loop over processed_original data
% close all
participants = [tests{:, 1}];
n_participants = length(participants);

for p=1:n_participants
    % Get test parameters
    particpant_num = participants(p);
    participant_name = "participant_" + num2str(particpant_num);
    trials_test_processsed = tests{p, 2};
    test_sides = tests{p, 3};
    if isempty(test_sides)
        test_sides = ["left" "right"];
    end

    % Plot trials
    f = figure(Name=participant_name + " Processed Original");
    tiledlayout
    for side=test_sides
        if isempty(trials_test_processsed)
            total_trials = length(DB.Data.(participant_name).uniform_data.(side).step);
            if n_trials < total_trials
                trials = round(linspace(1, total_trials, n_trials));
            else
                trials = 1:total_trials;
            end
        else
            trials = trials_test_processsed;
        end

        for t=trials
            try
                trial_uniform = DB.Data.(participant_name).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end
            t_processed_original = trial_uniform.source.original_trial_number_in_database;
            trial = DB.Data.(participant_name).processed_original_data.("trial_" + t_processed_original);
            
            for step_num=step_nums.(side)
                foot = steps_feet(step_num);
                side_prefix = sides.processed_original(strcmp(foot, sides.uniform));
                if isempty(side_prefix)
                    continue
                end
                % Time vectors
                forceplate_time = trial.Time.value; % Time vector for force-plate data
                trajectory_time = trial.Time.value; % Time vector for trajectory data

                % Indices of step events
                IC_index_grf = trial.events.("IC" + step_num).index;
                IC_index_traj = trial.events.("IC" + step_num).index;
                OIC_index_grf = trial.events.("IC" + (step_num + 1)).index;
                OIC_index_traj = trial.events.("IC" + (step_num + 1)).index;
                TO_index_grf = trial.events.("TO" + step_num).index;
                TO_index_traj = trial.events.("TO" + step_num).index;

                % Get COP and ankle, knee trajectories before temporal alignment
                COP = trial.COP.FP(step_num);
                ankle.x = trial.trajectories.value.(side_prefix + ankle_marker_name + "X");
                ankle.y = trial.trajectories.value.(side_prefix + ankle_marker_name + "Y");
                ankle.z = trial.trajectories.value.(side_prefix + ankle_marker_name + "Z");
                knee.x = trial.trajectories.value.(side_prefix + knee_marker_name + "X");
                knee.y = trial.trajectories.value.(side_prefix + knee_marker_name + "Y");
                knee.z = trial.trajectories.value.(side_prefix + knee_marker_name + "Z");

                % Check ankle-knee trajectories in space.
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

                nexttile
                X = [ankle.(db_axis(1))'; knee.(db_axis(1))'];
                Y = [ankle.(db_axis(3))'; knee.(db_axis(3))'];
                plot(X(:, IC_index_traj:OIC_index_traj), Y(:, IC_index_traj:OIC_index_traj), '-k')
                hold on
                axis equal
                scatter(ankle.(db_axis(1))(IC_index_traj:OIC_index_traj), ankle.(db_axis(3))(IC_index_traj:OIC_index_traj), 30, 'square', 'filled')
                scatter(knee.(db_axis(1))(IC_index_traj:OIC_index_traj), knee.(db_axis(3))(IC_index_traj:OIC_index_traj), 30, 'o', 'filled')
                scatter(COP.(db_axis(1))(IC_index_grf:OIC_index_grf), 0*COP.(db_axis(1))(IC_index_grf:OIC_index_grf), 30, '^', 'filled')
                title(upper(foot) + ": Trial " + num2str(t_processed_original), trial.origin.speed_catagory + " " + trial.origin.number_of_trial_under_speed_catagory)
                xlabel("x [mm]")
                ylabel("z [mm]")
            end
        end
        sgtitle(strrep(f.Name, "_", " "))
    end
end

%% Loop over Just Force plate Data
% close all
for p=1:n_participants
    % Get test parameters
    particpant_num = participants(p);
    participant_name = "participant_" + num2str(particpant_num);
    trials_test_processsed = tests{p, 2};
    test_sides = tests{p, 3};
    if isempty(test_sides)
        test_sides = ["left" "right"];
    end

    % Plot trials
    f = figure(Name=participant_name + " Forceplate Data");
    tiledlayout
    for side=test_sides
        if isempty(trials_test_processsed)
            total_trials = length(DB.Data.(participant_name).uniform_data.(side).step);
            if n_trials < total_trials
                trials = round(linspace(1, total_trials, n_trials));
            else
                trials = 1:total_trials;
            end
        else
            trials = trials_test_processsed;
        end

        for t=trials
             try
                trial_uniform = DB.Data.(participant_name).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end
            t_processed_original = trial_uniform.source.original_trial_number_in_database;
            trial = DB.Data.(participant_name).processed_original_data.("trial_" + t_processed_original);

            h = [];
            for step_num=step_nums.(side)
                foot = steps_feet(step_num);
                side_prefix = sides.processed_original(strcmp(foot, sides.uniform));
                if isempty(side_prefix)
                    continue
                end
                % Time vectors
                forceplate_time = trial.Time.value; % Time vector for force-plate data

                % Indices of step events
                IC_index_grf = trial.events.("IC" + step_num).index;
                OIC_index_grf = trial.events.("IC" + (step_num + 1)).index;
                TO_index_grf = trial.events.("TO" + step_num).index;

                % Get COP and ankle, knee trajectories before temporal alignment
                COP = trial.COP.FP(step_num);
                GRF = trial.GRF.(PROST.utils.capitalize(foot));

                nexttile;
                hold on

                title(upper(side) + ": Trial " + num2str(t_processed_original), trial.origin.speed_catagory + " " + trial.origin.number_of_trial_under_speed_catagory);
                xlabel("time [s]");
                grid on

                yyaxis left
                h = [h; plot(forceplate_time, COP.(db_axis(1)), '-', LineWidth=3, DisplayName="CoP " + db_axis(1))];
                h = [h; plot(forceplate_time, COP.(db_axis(2)), '--', LineWidth=3, DisplayName="CoP " + db_axis(2))];
                ylabel("CoP [mm]");

                yyaxis right
                h = [h; plot(forceplate_time, GRF.(db_axis(1)), '-', LineWidth=3, DisplayName="GRF " + db_axis(1))];
                h = [h; plot(forceplate_time, GRF.(db_axis(2)), '--', LineWidth=3, DisplayName="GRF " + db_axis(2))];
                h = [h; plot(forceplate_time, GRF.(db_axis(3)), '-.', LineWidth=3, DisplayName="GRF " + db_axis(3))];
                ylabel("GRF [N]");
                h = [h; xline(forceplate_time(IC_index_grf), '-k', LineWidth=3, DisplayName="IC")];
                h = [h; xline(forceplate_time(OIC_index_grf), '--k', LineWidth=3, DisplayName="OIC")];
                h = [h; xline(forceplate_time(TO_index_grf), '-.k', LineWidth=3, DisplayName="TO")];
                legend;
            end
        end
        sgtitle(strrep(f.Name, "_", " "));
    end
end