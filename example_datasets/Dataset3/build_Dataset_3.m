% ------------------------------------------------------------------
%  build a matlab structure containing the third dataset data
%  Created by Chen Reichsbouscher, 11.06.2025
% -------------------------------------------------------------------
clearvars -except -regexp ^Dataset_(?!3$)\d+$
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
data_path = ".\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
i_end = find(matches(toolbox_root, "PROST"), 1, "last");
toolbox_root = fullfile(toolbox_root{1:i_end});
addpath(toolbox_root); % Add PROST package to path

%% -----------------------------
%  General Database info:
% ------------------------------
%       -------------
% Dataset_3 / Article_data :
%       -------------
Article_data.article_name = "Human kinematic, kinetic and EMG data during different walking and stair ascending and descending tasks";
Article_data.authors = "Tiziana Lencioni, Ilaria Carpinella, Marco Rabuffetti, Alberto Marzegan & Maurizio Ferrarin";
Article_data.link_to_paper = "https://doi.org/10.1038/s41597-019-0323-z";
Article_data.link_to_dataset = "https://doi.org/10.6084/m9.figshare.c.4494755.v1";
Article_data.published_year = 2019;

Dataset_3.Article_data = Article_data;

%       --------------
% Dataset_3 / Markers_guide :
%       --------------
Markers_guide.explanation_txt =  "The field reference_guide containes a dictionary that maps our naming of important markers to the names and indices in the original dataset.\n" + ...
                                 "The knee markers in this dataset are not provided so are mapped to 'virtual' markers which will be calculated from other provided markers.\n" + ...                                 
                                 "The keys: our naming of important markers for cohesiveness between the different datasets.\n" + ...
                                 "The values: a cell array with the names and indices of each marker in the original dataset.\n" + ...
                                 "Column 1: the name they gave each marker in the article / original dataset.\n" + ...
                                 "Columns 2, 3, 4: the index numbers in the original trajectory dataset of the X, Y and Z directions.\n"+...
                                 "-----------------------------------------------------------";
% Important markers reference guide
keys = ["Right Lateral Ankle"; ...
        "Right Lateral Knee"; ...
        "Right Lateral Femoral Epicondyle"; ...
        "Right Fibular Head"; ...
        "Right ASIS"; ...
        "Right Heel"; ...
        "Left Lateral Ankle"; ...
        "Left Lateral Knee"; ...
        "Left Lateral Femoral Epicondyle"; ...
        "Left Fibular Head"; ...
        "Left ASIS"; ...
        "Left Heel"; ...
        "Walking Direction Marker"];
values = {{'RxLatMal', 64, 65, 66}; ...
          {'RxLatVirtualKnee', NaN, NaN, NaN}; ...
          {'RxLatCon', 46, 47, 48}; ...
          {'RxFH', 52, 53, 54}; ...
          {'RxAsis', 34, 35, 36}; ...
          {'RxHeel', 70, 71, 72}; ...
          {'LxLatMal', 67, 68, 69}; ...
          {'LxLatVirtualKnee', NaN, NaN, NaN}; ...
          {'LxLatCon', 49, 50, 51}; ...
          {'LxFH', 55, 56, 57}; ...
          {'LxAsis', 37, 38, 39}; ...
          {'LxHeel', 73, 74, 75}; ...
          {'Psis', 31, 32, 33}};
Markers_guide.reference_guide = dictionary(keys, values);
Dataset_3.Markers_guide = Markers_guide;

%       ---------------
% Dataset_3 / Lab_system :
%       ---------------
Lab_system.lab_frame = ...
    "X Direction: \n" + ...
    "The x direction is the direction in the lab from the first force-plate to the second force-plate.\n" + ...
    "(this is the walking direction for trials where the first force-plate was stepped on first,\n" + ...
    "and minus the walking direction for trials where the second force-plate was stepped on first).\n" + ...
    "Y Direction: \n" + ...
    "The y direction is pointing up.\n" + ...
    "Z Direction: \n" + ...
    "The z direction is pointing in the direction that completes a right handed coordinate system\n"+...
    "(this is towards the right (of the body) for trials where the first force-plate was stepped on first,\n"+...
    "and towards the left (of the body) for trials where the second force-plate was stepped on first).";
Lab_system.num_forceplates = 2;

Dataset_3.Lab_system = Lab_system;


%       ---------------------
% Dataset_3 / Experiment_protocol :
%       ---------------------

% Explanation for how the experiment was conducted generally.
Experiment_protocol.explanation_txt = ...
    "Relevant text taken from Lencioni et al.:\n\n" + ...
    "Subjects were required to wear tight clothes or swimsuit, and markers were attached on the skin above bony landmarks with double-sided adhesive tape. All tasks were performed barefoot.\n\n" + ...
    "For each subject, the acquisition session included a static calibration phase and, subsequently, a dynamic one including five locomotor tasks: walking at different speeds, toe-walking (T), heel-walking (H), step ascending (U) and step descending (D).\n" + ...
    "(We are only interested in the walking trials).\n" + ...
    "The static calibration phase included two static trials: the calibration and the standing trial.\n" + ...
    "The calibration trial, performed in an erect posture such that all markers are visible, is used to derive anthropometric measurements (e.g. femoral length) and to calibrate the position of the great trochanters and the medial part of the body, since the latter are hardly visible during locomotor movements.\n" + ...
    "The standing trial, performed in the natural erect posture of each subject, is recorded to compute reference values for kinematic data during locomotion.\n\n" + ...
    "After the calibration phase, the 8 anatomical markers placed on great trochanters and medial lower limbs were removed and the dynamic locomotor tasks were acquired.\n\n" + ...
    "For the walking task, we initially asked the subjects to walk five trials at their natural speed (N).\n" + ...
    "Hence, we asked to perform the following ten trials while progressively increasing (first 5 trials) or decreasing (latter 5 trials) their speed.\n" + ...
    "We gave no precise indications about gait speed or cadence in order not to induce gait alterations.\n\n" + ...
    "For each trial, foot-strikes were defined from platform data as the first samples with presence of GRF data.\n" + ...
    "Two consecutive foot-strike instants correspond to the initiation (tstart) and termination (tend) of the stride.\n" + ...
    "Only strides including one step on a force plate were considered.\n" + ...
    "The data reported in the present study includes, for each trial, the portions of kinematic, dynamic and EMG signals between tstart and tend.";
Experiment_protocol.speed_categories = ["Self selected speed.", ...
                                        "5 trials in natural speed.", ...
                                        "5 trials in progressively increasing speed.", ...
                                        "5 trials in progressively decreasing speed."];
Experiment_protocol.num_participants = 50;
Experiment_protocol.num_trials = 0;
Experiment_protocol.num_steps = 0;
Experiment_protocol.num_markers = 29;
Dataset_3.Experiment_protocol = Experiment_protocol;


%% -----------------------------
%  participant specific info:
% ------------------------------
% Number of participants
n_participants = size(dir(fullfile(data_path, "*.mat")), 1);

% Get relevant marker names in original database
markers_guide = Dataset_3.Markers_guide;
for participant_number = 1:n_participants
    right_steps_counter = 0; left_steps_counter = 0;
    participant_name = "participant_" + participant_number;
    load(fullfile(data_path, "Subject" + participant_number + ".mat"));
    n_markers = size(s.MarkerVarName, 1);
    n_grf = size(s.GrfVarName, 1);

    %                              -------------------------------------
    % Dataset_3 / Data / participant_# / participant_ID_in_original_structure :
    %                              -------------------------------------
    % the participant ID in the original data structure:
    participant_ID = s.name;
    Dataset_3.Data.(participant_name).participant_ID_in_original_structure = string(participant_ID);
    
    %                              ---------
    % Dataset_3 / Data / participant_# / metadata :
    %                              ---------
    
    % age
    metadata.Age.value = s.Age;
    metadata.Age.unit = "years";
    metadata.Age.method = "provided";
    
    % sex
    if contains(s.Gender,'M')
        metadata.Sex.value = "Male";
    elseif contains(s.Gender, 'F')
        metadata.Sex.value = "Female";
    end
    metadata.Sex.unit = "Male/Female";
    metadata.Sex.method = "provided";

    % height
    metadata.Height.value = s.BH/100;
    metadata.Height.unit = "m";
    metadata.Height.method = "provided";

    % mass
    metadata.Mass.value = s.BM;
    metadata.Mass.unit = "kg";
    metadata.Mass.method = "provided";
    
    % Footwear Condition
    metadata.Footwear_condition.value = "Barefoot";
    metadata.Footwear_condition.unit = "Shod/Barefoot";
    metadata.Footwear_condition.method = "provided";

    % standing trial
    ST_data = s.StandingData.Marker;
    
    % Marker names:
    % ankle - Lateral Malleolus (LatMal)
    % knee - Virtual marker calculated from Fibular Head (FH) and Lateral
    %        Femoral Epicondyle (LatCon)
    % asis - Anterior Superior Iliac Spine (Asis)
    right_ankle = ST_data([markers_guide.reference_guide{"Right Lateral Ankle"}{2:end}]); % RxLatMal
    left_ankle = ST_data([markers_guide.reference_guide{"Left Lateral Ankle"}{2:end}]); % LxLatMal
    
    right_above_knee = ST_data([markers_guide.reference_guide{"Right Lateral Femoral Epicondyle"}{2:end}]); % RxLatCon
    left_above_knee = ST_data([markers_guide.reference_guide{"Left Lateral Femoral Epicondyle"}{2:end}]); % LxLatCon
    right_below_knee = ST_data([markers_guide.reference_guide{"Right Fibular Head"}{2:end}]); % RxFH
    left_below_knee = ST_data([markers_guide.reference_guide{"Left Fibular Head"}{2:end}]); % LxFH
    
    right_virtual_knee = PROST.utils.get_knee_marker(right_below_knee, right_ankle, right_below_knee, right_above_knee);
    right_knee = [right_virtual_knee.x;right_virtual_knee.y;right_virtual_knee.z];
    left_virtual_knee = PROST.utils.get_knee_marker(left_below_knee, left_ankle, left_below_knee, left_above_knee);
    left_knee = [left_virtual_knee.x;left_virtual_knee.y;left_virtual_knee.z];

    right_asis = ST_data([markers_guide.reference_guide{"Right ASIS"}{2:end}]); % RxAsis
    left_asis = ST_data([markers_guide.reference_guide{"Left ASIS"}{2:end}]);  % LxAsis

    % thigh length
    metadata.Thigh_length.right = norm(right_asis - right_knee);
    metadata.Thigh_length.left = norm(left_asis - left_knee);
    metadata.Thigh_length.unit = "m";
    metadata.Thigh_length.method = "calculated by distance between ASIS and lateral knee markers in the standing trial";

    % shank length
    metadata.Shank_length.right = norm(right_knee - right_ankle);
    metadata.Shank_length.left = norm(left_knee - left_ankle);
    metadata.Shank_length.unit = "m";
    metadata.Shank_length.method = "calculated by distance between lateral knee and lateral ankle markers in the standing trial";
    
    % leg length
    metadata.Leg_length.right = norm(right_asis - right_ankle);
    metadata.Leg_length.left = norm(left_asis - left_ankle);
    metadata.Leg_length.unit = "m";
    metadata.Leg_length.method = "calculated by distance between ASIS and lateral ankle markers in the standing trial";
    
    Dataset_3.Data.(participant_name).metadata = metadata;

    %                                               ---------------------
    % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#)
    %                                               ---------------------
    % Prepping uniform data database
    Dataset_3.Data.(participant_name).uniform_data.right.step = [];
    Dataset_3.Data.(participant_name).uniform_data.left.step = [];

    % Only use walking data
    walking_data = s.Data(matches({s.Data.Task}, 'Walking'));
    
    % Trial 9 of participant 40 has missing marker measurements so we
    % replace with NaNs to keep the marker number consistent
    if participant_number == 40
        walking_data(9).Marker = [walking_data(9).Marker;...
                                  nan + walking_data(9).Marker(1:3, :)];
    end
    
    % Get the number of walking trials
    n_trials = size(walking_data, 2);

    % Add up total number of trials
    Dataset_3.Experiment_protocol.num_trials = Dataset_3.Experiment_protocol.num_trials + n_trials;

    % Estimating the OIC event time\index. To do so we need to find
    % thresholds for left and right feet of heel height of the opposite
    % foot. This identifies when the heel touches the ground.
      % Get OIC heel height thresholds
      threshold_shift = 0.025; % [m]
      [right_OIC_threshold, left_OIC_threshold] = get_OIC_thresholds(walking_data, s.MarkerVarName, threshold_shift);

    for trial_number = 1:n_trials
        %                               ---------------- -----------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#)
        %                               ---------------- -----------
        
        % now get the signals:
        % number of samples in trial
        n_marker_samples = size(walking_data(trial_number).Marker, 2);
        n_grf_samples = size(walking_data(trial_number).Grf, 2);

        % Time vectors of trial
        trajectory_time_vector = (0:n_marker_samples - 1)/s.KinFreq;
        forceplate_time_vector = (0:n_grf_samples - 1)/s.GrfFreq;

        % Signals
        markers_3d_location_data = walking_data(trial_number).Marker;
        grf_data = walking_data(trial_number).Grf(contains(string(s.GrfVarName), 'GRF'), :);
        cop_data = walking_data(trial_number).Grf(contains(string(s.GrfVarName), 'Cop'), :);
        
        %                                                            -------
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / origin
        %                                                            -------        
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).origin.trial_number = trial_number;

        %                                                            --------------------------------------------
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / step_#_info / events , step_quality , foot
        %                                                            --------------------------------------------
        % Each trial consists of a single foot strike on the force plate.
        % For each trial, foot-strikes were defined from platform data as 
        % the first samples with presence of GRF data. Two consecutive 
        % foot-strike instants correspond to the initiation (tstart) and 
        % termination (tend) of the stride. Only strides including one step 
        % on a force plate were considered.
        
            % step quality
        % Take out any trials where there is too much missing data.
        step_info.step_quality = "good"; % step quality
        marker_mask = [zeros(30, 1); ones(n_markers - 30, 1)]; % we only care about lower body markers
        if size(markers_3d_location_data, 1) ~= size(s.MarkerVarName, 1) || ...
            any(all(isnan(markers_3d_location_data), 2) & marker_mask) || ...
            size(grf_data, 1) ~= size(string(s.GrfVarName(contains(string(s.GrfVarName), 'GRF'), :)), 1) || ...
            any(all(isnan(grf_data), 2)) || ...
            size(cop_data, 1) ~= size(string(s.GrfVarName(contains(string(s.GrfVarName), 'Cop'), :)), 1) || ...
            any(all(isnan(cop_data), 2))
            step_info.step_quality = "bad"; % step quality
        end

            % foot of initial contact
        if strcmp(walking_data(trial_number).Foot, 'RX')
            step_info.foot = "right";
            other_foot = "Left";
            OIC_threshold = left_OIC_threshold; % [m]
        elseif strcmp(walking_data(trial_number).Foot, 'LX')
            step_info.foot = "left";
            other_foot = "Right";
            OIC_threshold = right_OIC_threshold; % [m]
        else
            error("All trials should be good so there should be no missing foot.")
        end
        
            % plate
        step_info.plate = 1;
        
            % By what frequency to round?
            round_by = max(s.KinFreq, s.GrfFreq);

            % initial contact
        step_info.events.IC.time = 0;
        step_info.events.IC.time = round(round_by*(step_info.events.IC.time))/round_by;
        step_info.events.IC.forceplate_index = 1;
        step_info.events.IC.trajectory_index = 1;
        if ~(mod(step_info.events.IC.forceplate_index, 1) == 0) || ~(mod(step_info.events.IC.trajectory_index, 1) == 0)
            error("IC index not an integer.\n" + ...
                  "Forceplate index: %d. Trajectory index: %d", step_info.events.IC.forceplate_index, step_info.events.IC.trajectory_index)
        end

            % toe off
        step_info.events.TO.time = forceplate_time_vector(end);
        step_info.events.TO.time = round(round_by*(step_info.events.TO.time))/round_by;
        step_info.events.TO.forceplate_index = n_grf_samples;
        step_info.events.TO.trajectory_index = PROST.utils.find_index_from_value(trajectory_time_vector, step_info.events.TO.time);
        
        if ~(mod(step_info.events.TO.forceplate_index, 1) == 0) || ~(mod(step_info.events.TO.trajectory_index, 1) == 0)
            error("TO index not an integer.\n" + ...
                  "Forceplate index: %d. Trajectory index: %d", step_info.events.TO.forceplate_index, step_info.events.TO.trajectory_index)
        end

            % Opposite initial contact
        % We estimate it as the time where the other foot reaches the height 
        % threshold for the first time.
        % The process of estimation is:
        % 1. Identify the foot of the first step.
        % 2. Find another trial where the other foot is the first step.
        % 3. Identify heel height at IC of that foot.
        % 4. Use that height as the threshold of the heel height denoting 
        %    OIC for this trial.
          % Find trajectory of other foot heel 
          heel_idx = markers_guide.reference_guide{other_foot + " Heel"}{3};
          heel = markers_3d_location_data(heel_idx, :); % [m]

          % Find where the heel starts descending
          d_heel = diff(heel); d_heel(end+1) = d_heel(end);
          start_descent = find(d_heel < 0, 1, 'first');

          % First 2 indices where heel reaches threshold
          OIC_indices = start_descent - 1 + find(heel(start_descent:end) <= OIC_threshold, 2, 'first');
        
          % If the heel never passes the threshold - take the minimum heel
          % height instead and 
          if isempty(OIC_indices)
              OIC_threshold = min(heel) + threshold_shift;
              OIC_indices = start_descent - 1 + find(heel(start_descent:end) <= OIC_threshold, 2, 'first');
          end
          
          % If the first index is of the IC (if IC happened below
          % threshold) we need to take the second one
          if OIC_indices(1) == step_info.events.IC.trajectory_index
              OIC_index_traj = OIC_indices(2);
          else
              OIC_index_traj = OIC_indices(1);
          end
        
        % Add OIC to step info event
        step_info.events.OIC.time = trajectory_time_vector(OIC_index_traj);
        step_info.events.OIC.time = round(round_by*(step_info.events.OIC.time))/round_by;
        step_info.events.OIC.forceplate_index = PROST.utils.find_index_from_value(forceplate_time_vector, step_info.events.OIC.time);
        step_info.events.OIC.trajectory_index = OIC_index_traj;
        if ~(mod(step_info.events.OIC.forceplate_index, 1) == 0) || ~(mod(step_info.events.OIC.trajectory_index, 1) == 0)
            error("OIC index not an integer.\n" + ...
                  "Forceplate index: %d. Trajectory index: %d", step_info.events.OIC.forceplate_index, step_info.events.OIC.trajectory_index)
        end

        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info = step_info;
        
        %                                                            -----
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / Time
        %                                                            -----
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).Trajectory_Time.value = trajectory_time_vector;
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).Trajectory_Time.unit = "second";
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).Forceplate_Time.value = forceplate_time_vector;
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).Forceplate_Time.unit = "second";
        
        %                                                            ----
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / GRF
        %                                                            ----
        % -------------------------------------------
        % the x direction is the direction of walking.
        % the y direction is pointing up.
        % the z direction is pointing to the right (of the body).
        % -------------------------------------------
        GRF.plate_1.x = grf_data(1, :);
        GRF.plate_1.y = grf_data(2, :);
        GRF.plate_1.z = grf_data(3, :);
        GRF.unit = "N";
        GRF.sampling_freq = s.GrfFreq; % [Hz]
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).GRF = GRF;
        
        %                                                            ----
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / COP
        %                                                            ----
        COP.plate_1.x = cop_data(1, :);
        COP.plate_1.y = cop_data(2, :);
        COP.plate_1.z = cop_data(3, :);
        COP.unit = "mm";
        COP.sampling_freq = s.GrfFreq; % [Hz]
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).COP = COP;
        
        % now if the step is good,
        % we will change the initial contact that we saved
        % according to the COP (check where the COP starts making sense)
        trial = Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number);
        if ((trial.step_1_info.step_quality) == "good")
            step_info = trial.step_1_info;
            
            % find out what is the right force plate
            plate = step_info.plate;
            
            % get the COP from this forceplate
            cut_COP = trial.COP.("plate_" + plate);
            
            % get the IC and the OIC of this step
            IC_index = step_info.events.IC.forceplate_index;
            OIC_index = step_info.events.OIC.forceplate_index;

            % cut the COP according to the IC and OIC
            cut_COP.x=cut_COP.x(IC_index:OIC_index);
            cut_COP.y=cut_COP.y(IC_index:OIC_index);
            cut_COP.z=cut_COP.z(IC_index:OIC_index);

            is_in = ~isoutlier(cut_COP.x) & ~isoutlier(cut_COP.z);

            added_IC = find(is_in, 1, 'first');
            if isempty(added_IC)
                added_IC = 0;
                Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info.step_quality = "bad";
                warning('Participant %s, condition %d, trial %d: Step %d was reported as good, but no CoP initial contact detected', participant_ID, c, t, 1);
            else
                % change the IC of this good step:
                new_forceplate_IC = IC_index + added_IC - 1;
                Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info.events.IC.forceplate_index = new_forceplate_IC;
                IC_new_time = forceplate_time_vector(new_forceplate_IC);
                IC_new_time = round(round_by*(IC_new_time))/round_by;
                Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info.events.IC.time = IC_new_time;
                new_trajectory_IC = PROST.utils.find_index_from_value(trajectory_time_vector, IC_new_time);
                Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info.events.IC.trajectory_index = new_trajectory_IC;
            end
            if ~(mod(step_info.events.IC.forceplate_index, 1) == 0) || ~(mod(step_info.events.IC.trajectory_index, 1) == 0)
                error("IC index not an integer.\n" + ...
                      "Forceplate index: %d. Trajectory index: %d", step_info.events.IC.forceplate_index, step_info.events.IC.trajectory_index)
            end
        end

        %                                                            -------------
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / trajectories
        %                                                            -------------
        % ---------------------------------
        % which markers do we want to save:
        % ---------------------------------
        trajectories.unit = "mm";
        trajectories.sampling_freq = s.KinFreq; % [Hz]
        for idx=1:n_markers
            marker_name = strtrim(s.MarkerVarName(idx, :));
            trajectories.(marker_name(2:end)).(lower(marker_name(1))) = markers_3d_location_data(idx, :)*1000; % [mm]
        end
        right_ST_above_knee = ST_data([markers_guide.reference_guide{"Right Lateral Femoral Epicondyle"}{2:end}]); % RxLatCon
        left_ST_above_knee = ST_data([markers_guide.reference_guide{"Left Lateral Femoral Epicondyle"}{2:end}]); % LxLatCon
        right_ST_below_knee = ST_data([markers_guide.reference_guide{"Right Fibular Head"}{2:end}]); % RxFH
        left_ST_below_knee = ST_data([markers_guide.reference_guide{"Left Fibular Head"}{2:end}]); % LxFH
        trajectories.(markers_guide.reference_guide{"Right Lateral Knee"}{1}) = ...
            PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Right Fibular Head"}{1}), ...
                            trajectories.(markers_guide.reference_guide{"Right Lateral Ankle"}{1}), ...
                            right_ST_below_knee, right_ST_above_knee);
        trajectories.(markers_guide.reference_guide{"Left Lateral Knee"}{1}) = ...
            PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Left Fibular Head"}{1}), ...
                            trajectories.(markers_guide.reference_guide{"Left Lateral Ankle"}{1}), ...
                            left_ST_below_knee, left_ST_above_knee);

        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).trajectories = trajectories;

        %                                                            ------------------
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / walking_direction
        %                                                            ------------------
        % we will check the walking direction by checking if the direction
        % that the Psis marker is moving is +x (+1) or -x (-1)
        psis_x = trajectories.(markers_guide.reference_guide{"Walking Direction Marker"}{1}).x;
        walking_direction = sign(psis_x(end) - psis_x(1));
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value = walking_direction;
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.explenation = "\n1 - the walking was in the direction from plate 1 to plate 2." + ... 
                                                                                                          "\n-1 - the walking was in the direction from plate 2 to plate 1.";
        %                                                            ------
        % Dataset_3 / Data / participant_# / processed_original_data / trial(#) / speed
        %                                                            ------
        % get the speed from the data:
        speed = walking_data(trial_number).speed;
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).speed.value = PROST.utils.convert_units(PROST.utils.convert_units(speed, "m", "km"), "hour", "second");
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).speed.unit = "km/hour";
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).speed.method = ...
            "Provided.\n" + ...
            "Converted from [m/second] to [km/hour].";
        Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).speed.speed_category = "Self selected speed";

        %                              ---------------
        % Dataset_3 / Data / participant_# / uniform_data
        %                              ---------------
        
        % reminder: the frame of reference of the processed_original data:
        %           -------------------------------------------------
        % x - the direction (in the lab) from Force_Plate_1 to Force_Plate_2
        % y - up
        % z - in the direction that completes a right handed coordinate system. (right if FP1 was stepped on first)
        %                                                                       (left if FP2 was stepped on first)

        % drawing of the coordinate system:
        %
        %    y          
        %    ^              ________________
        %    |             /               /
        %    |            / force_plate_1 /
        %    | _ _ _> x  /_______________/
        %    /
        %   /
        %  v 
        % z

        % and the frame of reference of the uniform data:
        % ---------------------------------------------
        % x - the walking direction (+x or -x)
        % y - to the left (of the body)
        % z - up

        % summery of needed transformation:
        % ---------------------------------
        % new z = old y
        % new x = direction * old x
        % new y = -direction * old z

        % summary of temporal alignment:
        % -------------------------
        % the GRF should be temporally aligned (to n_temporal_alignment points) in the stance phase (SP) -> from initial contact to toe off 
        % while the COP, markers, and ROS should be temporally aligned (to n_temporal_alignment points) in the single support phase (SS) -> from initial contact to opposite initial contact 

        %                                               ---------------------
        % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#)
        %                                               ---------------------
        step_info = Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).step_1_info;
        if (step_info.step_quality == "good")
            side = step_info.foot; %side: right or left
            if side == "right"
                right_steps_counter = right_steps_counter + 1;
                relevant_index = right_steps_counter;
                foot = "Right";
            else
                left_steps_counter = left_steps_counter + 1;
                relevant_index = left_steps_counter;
                foot = "Left";
            end

            %                                                                      ---------
            % Dataset_3 / Data / participant_# / uniform_data / right,left / step(#) / source /
            %                                                                      ---------
              %                                                                             ---------------
            %                                                                               / original trial
            %                                                                               ---------------
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_trial = string(trial_number);
            %                                                                               ---------------------
            %                                                                               / step number in trial
            %                                                                               ---------------------
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.step_number = 1;
            %                                                                               -------------
            %                                                                               / plate number
            %                                                                               -------------
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.plate_number = step_info.plate;
            
            % original IC,OIC,and TO: index and time
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.forceplate_index = step_info.events.IC.forceplate_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.forceplate_index = step_info.events.OIC.forceplate_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.forceplate_index = step_info.events.TO.forceplate_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.trajectory_index = step_info.events.IC.trajectory_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.trajectory_index = step_info.events.OIC.trajectory_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.trajectory_index = step_info.events.TO.trajectory_index;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.time = step_info.events.IC.time;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.time = step_info.events.OIC.time;
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.time = step_info.events.TO.time;
            %-----------------------------------------
            % Get event indices of the force plate measurements
            IC_index = step_info.events.IC.forceplate_index;
            TO_index = step_info.events.TO.forceplate_index;
            OIC_index = step_info.events.OIC.forceplate_index;
            
            % Get the walking direction of the trial
            walking_direction = Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value;
            
            % Size of temporal alignment. We want 101 points so data is in
            % percentage of stance phase \ single support phase.
            n_temporal_alignment = 101;

            %                                                                      ----------------------------
            % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#) / COP   -  temporally aligned  
            %                                                                      ----------------------------
            % get data (get the COP):
            COP = Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).COP;
            tmp_COP.x = walking_direction*COP.plate_1.x;
            tmp_COP.y = -walking_direction*COP.plate_1.z;
            % tmp_COP.z = COP.plate_1.y;
            % % cut the COP from IC to OIC filter it and temporally align to to n_temporal_alignment points
            interpolated_COP.x = interp1(IC_index:OIC_index, tmp_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index - 0.0001, n_temporal_alignment)); % NOTE: why -0.0001?????
            interpolated_COP.y = interp1(IC_index:OIC_index, tmp_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index - 0.0001, n_temporal_alignment)); % NOTE: why -0.0001?????
            interpolated_COP.z = zeros(size(interpolated_COP.x)); 
            % interpolated_COP.z = interp1(IC_index:OIC_index, tmp_COP.z(IC_index:OIC_index), linspace(IC_index, OIC_index - 0.0001, n_temporal_alignment)); % NOTE: why -0.0001?????
            interpolated_COP.unit = "mm";
            interpolated_COP.temporal_alignment = "Initial contact to opposite initial contact.";

            % and place into the database:
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).COP = interpolated_COP;

            %                                                                      ----                           ------------
            % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#) / GRF   -  temporally aligned to stance phase 
            %                                                                      ----                           ------------
            % get data:
            GRF = Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).GRF;
            tmp_GRF.x = walking_direction*GRF.plate_1.x;
            tmp_GRF.y = -walking_direction*GRF.plate_1.z;
            tmp_GRF.z = GRF.plate_1.y;
            % cut from IC to TO and temporally align to to n_temporal_alignment points
            interpolated_GRF.x = interp1(IC_index:TO_index, tmp_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
            interpolated_GRF.y = interp1(IC_index:TO_index, tmp_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
            interpolated_GRF.z = interp1(IC_index:TO_index, tmp_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
            interpolated_GRF.unit = "N";
            interpolated_GRF.temporal_alignment = "Initial contact to toe off (stance phase).";

            % OIC event after temporal alignment
            interpolated_GRF.OIC.time = round((n_temporal_alignment - 1)*(OIC_index - IC_index)/(TO_index - IC_index));
            interpolated_GRF.OIC.index = interpolated_GRF.OIC.time + 1;

            % and place into the database:
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).GRF = interpolated_GRF;

            %                                                                      --------                           --------------
            % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#) / markers   -  temporally aligned to single support
            %                                                                      --------                           --------------
            % Get event indices of the trajectory measurements
            IC_index = step_info.events.IC.trajectory_index;
            TO_index = step_info.events.TO.trajectory_index;
            OIC_index = step_info.events.OIC.trajectory_index;
            % --------------------------------------------------
            % first we need to decide what markers interest us:
            % LatMal - external ankle
            % LatVirtualKnee - external knee
            % We don't have internal markers here.
            % --------------------------------------------------
            % get the markers data :
              % For the ankle:
            one_step_Markers.Ankle.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).x;
            one_step_Markers.Ankle.lateral.y = -walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).z;
            one_step_Markers.Ankle.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).y;
            one_step_Markers.Ankle.medial = [];
              % For the knee:
            one_step_Markers.Knee.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).x;
            one_step_Markers.Knee.lateral.y = -walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).z;
            one_step_Markers.Knee.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).y;
            one_step_Markers.Knee.medial = [];

            % Cut the markers data from IC to OIC and temporally align it to n_temporal_alignment points :
            one_step_Markers.Ankle.lateral.x = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
            one_step_Markers.Ankle.lateral.y = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
            one_step_Markers.Ankle.lateral.z = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

                    % We don't have medial markers so the mean is empty
            one_step_Markers.Ankle.mean = [];

            one_step_Markers.Knee.lateral.x = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
            one_step_Markers.Knee.lateral.y = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
            one_step_Markers.Knee.lateral.z = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
            
                    % We don't have medial markers so the mean is empty
            one_step_Markers.Knee.mean = [];

            one_step_Markers.unit = "mm";
            one_step_Markers.temporal_alignment = "Initial contact to opposite initial contact.";

                % And place into the database:
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).Markers = one_step_Markers;

            %                                                                       ------
            % Dataset_3 / Data / participant_# / uniform_data / Right,Left / step(#) / speed 
            %                                                                       ------ 
            Dataset_3.Data.(participant_name).uniform_data.(side).step(relevant_index).speed = ...
            Dataset_3.Data.(participant_name).processed_original_data.trial(trial_number).speed;
        end
    end
end

Dataset_3.Experiment_protocol.num_steps = Dataset_3.Experiment_protocol.num_trials;

save("..\Dataset_3.mat","Dataset_3")
