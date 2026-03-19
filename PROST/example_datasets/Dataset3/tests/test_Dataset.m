clearvars -except -regexp ^Dataset_\d+$ good_trials raw_data all_metadata
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

if ~exist("Dataset_3", "var")
    load("../../Dataset_3.mat");
end
%% Change accordingly to your test
% What database to test
Dataset = Dataset_3;

% Database relevant marker names
ankle_marker_name = "LatMal";
knee_marker_name = "LatVirtualKnee";
% Database parameters
step_nums = [1]; % number of steps per trial
db_axis = ["x", "z", "y"]; % lab frame axis: [walking direction, other direction, up]

% Which participant to test?
participants = [24];
n_participants = length(participants);
sides.uniform = ["right", "left"];
cmaps = dictionary("right", "green", "left", "red");
sides.processed_original = ["Rx", "Lx"]; % How are the sides delineated in the database


%% Check Shank Frame Transformation
% close all
% How many trials to test?
n_trials = 3;
trials_test = [15];
for particpant_num=participants
    p = "participant_" + num2str(particpant_num);
    f = figure(Name=p + " Shank Frame");
    tiledlayout(f, "flow")

    if isempty(trials_test)
        total_trials = min(length(Dataset.Data.(p).uniform_data.left.step), length(Dataset.Data.(p).uniform_data.right.step));
        if n_trials < total_trials
            trials = round(linspace(1, total_trials, n_trials));
        else
            trials = 1:total_trials;
        end
    else
        trials = trials_test;
    end
    for t=trials
        nexttile
        for side=sides.uniform
            try
                trial = Dataset.Data.(p).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    continue;
                end
            end

            % Time vector
            time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points

            % Get COP in shank coordinate frame
            shank_cop = PROST.PROSTAnalyzer.cop_to_shank_frame(trial, "lateral");

            % colormap("autumn");
            scatter(shank_cop.u, shank_cop.w, 30, cmaps(side), 'o', 'filled', DisplayName=side)
            hold on
            axis equal
            title("P" + particpant_num + "T" + num2str(t), replace(trial.source.original_trial, "_", " "))

        end            
        legend()
    end
end

%% Loop over uniform data
% close all
% How many trials to test?
n_trials = 3;
trials_test = [15];
for particpant_num=participants
    p = "participant_" + num2str(particpant_num);
    f = figure(Name=p + " Uniform");
    tiledlayout(f, "flow")
    for side=sides.uniform
       if isempty(trials_test)
            total_trials = length(Dataset.Data.(p).uniform_data.(side).step);
            if n_trials < total_trials
                trials = round(linspace(1, total_trials, n_trials));
            else 
                trials = 1:total_trials;
            end
       else
           trials = trials_test;
        end
        for t=trials
            try
                trial = Dataset.Data.(p).uniform_data.(side).step(t);
            catch ME
                if ME.identifier == 'MATLAB:badsubscript'
                    % nexttile
                    continue;
                end
            end

            % Time vector
            time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points

            % Get COP and ankle, knee trajectories after temporal alignment
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
            scatter(COP.x, 0*COP.y, 30, time, '^', 'filled')
            title(upper(side) + ": Trial " + num2str(t), replace(trial.source.original_trial, "_", " "))
            xlabel("x [mm]")
            ylabel("z [mm]")
            hold off
        end
        sgtitle(strrep(f.Name, "_", " "))
    end
end

%% Loop over processed_original data
% close all
% How many trials to test?
n_trials = 3;
trials_test = [22];
for particpant_num=participants
    p = "participant_" + num2str(particpant_num);
    f = figure(Name=p + " Processed Original");
    tiledlayout
    if isempty(trials_test)
        total_trials = length(Dataset.Data.(p).processed_original_data.trial);
        if n_trials < total_trials
            trials = round(linspace(1, total_trials, n_trials));
        else 
            trials = 1:total_trials;
        end
    else
       trials = trials_test;
    end
    for t=trials
        trial = Dataset.Data.(p).processed_original_data.trial(t);
        for step_num=step_nums
            step_info = trial.("step_" + step_num + "_info");
            side = step_info.foot;
            side_prefix = sides.processed_original(strcmp(side, sides.uniform));
            if strcmp(step_info.step_quality, "bad")
                disp(step_num + "," + t)
            end
            if isempty(side_prefix)
                continue
            end
            % Time vectors
            forceplate_time = trial.GRF.time_vector.value; % Time vector for force-plate data
            trajectory_time = trial.trajectories.time_vector.value; % Time vector for trajectory data
            
            % Indices of step events
            IC_index_grf = step_info.events.IC.forceplate_index;
            IC_index_traj = step_info.events.IC.trajectory_index;
            OIC_index_grf = step_info.events.OIC.forceplate_index;
            OIC_index_traj = step_info.events.OIC.trajectory_index;
            TO_index_grf = step_info.events.TO.forceplate_index;
            TO_index_traj = step_info.events.TO.trajectory_index;
    
            % Get COP and ankle, knee trajectories before temporal alignment
            COP = trial.COP.("plate_" + step_info.plate);
            ankle = trial.trajectories.(side_prefix + ankle_marker_name);
            knee = trial.trajectories.(side_prefix + knee_marker_name);
    
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
            X = [ankle.(db_axis(1)); knee.(db_axis(1))];
            Y = [ankle.(db_axis(3)); knee.(db_axis(3))];
            plot(X(:, IC_index_traj:OIC_index_traj), Y(:, IC_index_traj:OIC_index_traj), '-k')
            hold on
            axis equal
            scatter(ankle.(db_axis(1))(IC_index_traj:OIC_index_traj), ankle.(db_axis(3))(IC_index_traj:OIC_index_traj), 30, 'square', 'filled')
            scatter(knee.(db_axis(1))(IC_index_traj:OIC_index_traj), knee.(db_axis(3))(IC_index_traj:OIC_index_traj), 30, 'o', 'filled')
            scatter(COP.(db_axis(1))(IC_index_grf:OIC_index_grf), 0*COP.(db_axis(1))(IC_index_grf:OIC_index_grf), 30, '^', 'filled')
            title(upper(side) + ": Trial " + num2str(t), trial.origin.catagory + " " + trial.origin.trial_number)
            xlabel("x [mm]")
            ylabel("z [mm]")
        end
    end
    sgtitle(strrep(f.Name, "_", " "))
end

%% Loop over Just Forceplate Data
close all
for particpant_num=participants
    p = "participant_" + num2str(particpant_num);
    f = figure(Name=p + " Forceplate Data");
    tiledlayout;
    if isempty(trials_test)
        total_trials = length(Dataset.Data.(p).processed_original_data.trial);
        if n_trials < total_trials
            trials = round(linspace(1, total_trials, n_trials));
        else 
            trials = 1:total_trials;
        end
    else
       trials = trials_test;
    end
    for t=trials
        trial = Dataset.Data.(p).processed_original_data.trial(t);
        h = [];
        for step_num=step_nums
            step_info = trial.("step_" + step_num + "_info");
            side = step_info.foot;
            side_prefix = sides.processed_original(strcmp(side, sides.uniform));
            if strcmp(step_info.step_quality, "bad")
                disp(p + " Trial: " + t + " Step: " + step_num)
            end
            if isempty(side_prefix)
                continue
            end
            % Time vectors
            forceplate_time = trial.GRF.time_vector.value; % Time vector for force-plate data
            
            % Indices of step events
            IC_index_grf = step_info.events.IC.forceplate_index;
            OIC_index_grf = step_info.events.OIC.forceplate_index;
            TO_index_grf = step_info.events.TO.forceplate_index;
    
            % Get COP and ankle, knee trajectories before temporal alignment
            COP = trial.COP.("plate_" + step_info.plate);
            GRF = trial.GRF.("plate_" + step_info.plate);
    
            nexttile;
            hold on
            
            title(upper(side) + ": Trial " + num2str(t), trial.origin.catagory + " " + trial.origin.trial_number);
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
            ylabel("GRF [mm]");
            h = [h; xline(forceplate_time(IC_index_grf), '-k', LineWidth=3, DisplayName="IC")];
            h = [h; xline(forceplate_time(OIC_index_grf), '--k', LineWidth=3, DisplayName="OIC")];
            h = [h; xline(forceplate_time(TO_index_grf), '-.k', LineWidth=3, DisplayName="TO")];
            legend;
        end
    end
    sgtitle(strrep(f.Name, "_", " "));
end