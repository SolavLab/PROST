%% ------------------------------------------------------------------
%  build a matlab structure containing the second dataset data
%  Created by Dani Feal
%  Edited by Chen Reichsbouscher, 11.06.2025
% -------------------------------------------------------------------
%
clearvars -except -regexp ^Dataset_\d+$ good_trials
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = ".\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

% Add ezc3d package
addpath(fullfile(toolbox_root, "lib-ext", "ezc3d_matlab"));

%% -----------------------------
%  General Database info:
% ------------------------------
%       -------------
% Dataset_2 / article_data :
%       -------------
article_data.article_name = "A multimodal dataset of human gait at different walking speeds established on injury-free adult participants";
article_data.authors = "Céline Schreiber & Florent Moissenet";
article_data.link_to_paper = "https://doi.org/10.1038/s41597-019-0124-4";
article_data.link_to_dataset = "https://doi.org/10.6084/m9.figshare.7734767.v8";
article_data.published_year = 2019;

Dataset_2.Article_data = article_data;

%       -------------
% Dataset_2 / marker_names :
%       -------------
markers_guide.explanation_txt = "The field reference_guide containes a dictionary that maps our naming of important markers to the names and indices in the original dataset.\n" + ...
                                "The keys: our naming of important markers for cohesiveness between the different datasets.\n" + ...
                                "The values: a cell array with the names and indices of each marker in the original dataset.\n" + ...
                                "Column 1: the name they gave each marker in the article / original dataset.\n" + ...
                                "Column 2: the index number in the original trajectories dataset of the X, Y and Z coordinates." + ...
                                "----------------------------------------------------------- \n";
% Important markers reference guide
keys = ["Right Lateral Ankle"; ...
        "Right Medial Ankle"; ...
        "Right Lateral Knee"; ...
        "Right Medial Knee"; ...
        "Right Lateral Femoral Epicondyle"; ...
        "Right Medial Femoral Epicondyle"; ...
        "Right Fibular Head"; ...
        "Right Tibial Tuberosity"; ...
        "Right ASIS"; ...
        "Left Lateral Ankle"; ...
        "Left Medial Ankle"; ...
        "Left Lateral Knee"; ...
        "Left Medial Knee"; ...
        "Left Lateral Femoral Epicondyle"; ...
        "Left Medial Femoral Epicondyle"; ...
        "Left Fibular Head"; ...
        "Left Tibial Tuberosity"; ...
        "Left ASIS"; ...
        "Walking Direction Marker"];
values = {{"R_FAL",  21}; ...
          {"R_TAM",  22}; ...
          {"R_LatVirtualKnee", NaN}; ...
          {"R_MedVirtualKnee", NaN}; ...
          {"R_FLE",  17}; ...
          {"R_FME",  18}; ...
          {"R_FAX",  19}; ...
          {"R_TTC",  20}; ...
          {"R_IAS",  16}; ...
          {"L_FAL",  10}; ...
          {"L_TAM",  11}; ...
          {"L_LatVirtualKnee"}; ...
          {"L_MedVirtualKnee"}; ...
          {"L_FLE",  6}; ...
          {"L_FME",  7}; ...
          {"L_FAX",  8}; ...
          {"L_TTC",  9}; ...
          {"L_IAS",  5}; ...
          {"SXS",  29}};
markers_guide.reference_guide = dictionary(keys, values);
% markers_guide.virtual_markers = dictionary(["Right Lateral Knee" "Right Medial Knee" "Left Lateral Knee" "Left Medial Knee"], ...
%                                 ["R_LatVirtualKnee"   "R_MedVirtualKnee"  "L_LatVirtualKnee"  "L_MedVirtualKnee"]);

Dataset_2.Markers_guide = markers_guide;

%       --------------------
% Dataset_2 / Lab_system :
%       --------------------
Lab_system.lab_frame = ...
    "X Direction: \n" + ...
    "The x direction is the direction in the lab from the first force-plate to the second force-plate.\n" + ...
    "(this is the walking direction for trials where the first force-plate was stepped on first,\n" + ...
    "and minus the walking direction for trials where the second force-plate was stepped on first).\n" + ...
    "Y Direction: \n" + ...
    "The y direction is pointing in the direction that completes a right handed coordinate system \n" + ...
    "(this is towards the left (of the body) for trials where the first force-plate was stepped on first,\n" + ...
    "and towards the right (of the body) for trials where the second force-plate was stepped on first).\n" + ...
    "Z Direction: \n" + ...
    "The z direction is pointing up.";
Lab_system.num_forceplates = 2;

Dataset_2.Lab_system = Lab_system;

%       ---------------------
% Dataset_2 / Experiment_protocol :
%       ---------------------

% Explanation for how the experiment was conducted generally.
Experiment_protocol.explanation_txt = ...
    "Relevant text taken from Schreiber and Moissenet:\n\n" + ...
    "For each participant, the entire data collection was acquired in a single session which lasted approximately 2 hours.\n" + ...
    "All the sessions were managed by the same experienced operator.\n" + ...
    "The following procedure was adopted: calibration of the systems, introduction to the participant, interview, preparation of the participant, static record, walking trials and session ending.\n\n" + ...
    "The calibration was performed following the instructions available in the manufacturer’s documentation, including the definition of the inertial coordinate system, the dynamic calibration of the cameras, and the zeroing of force-plates.\n\n" + ...
    "The participant was asked to change clothes to tight-fitting clothes or underwear, including removing shoes and socks as the acquisition was barefoot, and tied up their hair if necessary.\n\n" + ...
    "In the static record, the participant was standing upright with lower and upper limbs outstretched, palms facing forward, right head with straight eyes.\n" + ...
    "Five seconds without any movement were recorded.\n" + ...
    "The record was verified by the operator.\n" + ...
    "A new standing trial was performed if any marker was missing or movements perturbed the record.\n\n" + ...
    "During the walking trials, the participant was asked to walk back and forth on a 10-m straight level walkway.\n" + ...
    "The instruction given was ""to walk as naturally as possible, looking forward"".\n" + ...
    "No directive was given about the force-plates to avoid a conscious adaptation of the walk.\n" + ...
    "A minimum of 3 trials were recorded for each condition.\n" + ...
    "All trials were rapidly verified by the operator.\n" + ...
    "Five conditions of walking speed were recorded: C1, C2, C3, C4, C5.\n" + ...
    "Conditions C1, C2 and C3 were induced by a metronome and correspond to the three groups described by Perry (i.e. household ambulators, limited community ambulators and community ambulators).\n" + ...
    "An adaptation time to the imposed cadence was foreseen for these 3 conditions and the velocity of the first trial was checked to be in the expected range of speed.\n" + ...
    "C4 and C5 were self-selected conditions in response to the instructions to walk respectively ""as usual"" and ""fast but not running"".";
Experiment_protocol.speed_categories = "C1 is a speed between 0 and 0.4 m.s−1.\n" + ...
                                       "C2 is a speed between 0.4 and 0.8 m.s−1.\n" + ...
                                       "C3 is a speed between 0.8 and 1.2 m.s−1.\n" + ...
                                       "C4 is a self-selected spontaneous speed.\n" + ...
                                       "C5 is a self-selected fast speed.";
Experiment_protocol.num_participants = 50;

Dataset_2.Experiment_protocol = Experiment_protocol;

%% Create List of Trials to Keep
% Bad trials are missing crucial info so we only keep those that aren't.
% ignore_trials = ["2015002_C5_02";
%                  "2015002_C5_03";
%                  "2015002_C5_04";
%                  "2015026_C1_01";
%                  "2015026_C1_02";
%                  "2015026_C1_03";
%                  "2015026_C1_04";
%                  "2015026_C2_01";
%                  "2015026_C2_02";
%                  "2015026_C2_03";
%                  "2015026_C2_04";
%                  "2015026_C2_05";
%                  "2015026_C3_01";
%                  "2015026_C3_02";
%                  "2015026_C3_03";
%                  "2015026_C3_04";
%                  "2015026_C4_01";
%                  "2015026_C4_02";
%                  "2015026_C4_03";
%                  "2015026_C4_04";
%                  "2015026_C5_01";
%                  "2015026_C5_02";
%                  "2015026_C5_03";
%                  "2015030_C5_01";
%                  "2015030_C5_02";
%                  "2015030_C5_03";
%                  "2015032_C3_01";
%                  "2015032_C3_02";
%                  "2015032_C3_03";
%                  "2015032_C3_04";
%                  "2015032_C4_01";
%                  "2015032_C4_02";
%                  "2015032_C4_03";
%                  "2015032_C5_01";
%                  "2015032_C5_02";
%                  "2015032_C5_03";
%                  "2015032_C5_04";
%                  "2015032_C5_05"];
% [ignore_trials, ignore_participants] = make_ignore_list(data_path, Dataset_2.Markers_guide.reference_guide);
if ~exist("good_trials")
    good_trials = get_good_trials(data_path, Dataset_2.Markers_guide.reference_guide);
end

%% -----------------------------
%  participant specific info:
% ------------------------------
% Number of participants
good_participants = unique(good_trials(:, 1));
n_participants = length(good_participants);

% Get relevant marker names in original dataset
markers_guide = Dataset_2.Markers_guide;

for participant_number=1:n_participants
    % Get participant name and original ID from number
    participant_ID = string(good_participants(participant_number));
    participant_name = "participant_" + string(participant_number);
    
    good_trials_indices = find(good_trials(:, 1) == participant_ID);
    good_trials_file_name = join(good_trials(good_trials_indices, :), "_") + ".c3d";
    good_trials_condition_number = good_trials(good_trials_indices, 2);
    good_trials_trial_number = good_trials(good_trials_indices, 3);

    % Initializing counters for right and left steps of all trials
    right_steps_counter = 0; left_steps_counter = 0;

    %                              -------------------------------------
    % Dataset_2 / Data / participant_# / participant_ID_in_original_structure :
    %                              -------------------------------------
    % the participant ID in the original data structure:
    Dataset_2.Data.(participant_name).participant_ID_in_original_structure = participant_ID;

    %                              ---------
    % Dataset_2 / Data / participant_# / metadata :
    %                              ---------

    % Get participant trial data path
    trial_path = fullfile(data_path, participant_ID, good_trials_file_name(1));

    % Get standing trial path
    standing_trial_file = participant_ID + "_ST.c3d";
    standing_trial_path = fullfile(data_path, participant_ID, standing_trial_file);
    
    % Get metadata
    [metadata, standing_trial] = get_metadata(trial_path, standing_trial_path, markers_guide);
    Dataset_2.Data.(participant_name).metadata = metadata;
    
    %                                               ---------------------
    % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#)
    %                                               ---------------------
    % Prepping uniform data database
    Dataset_2.Data.(participant_name).uniform_data.right.step = [];
    Dataset_2.Data.(participant_name).uniform_data.left.step = [];

    % Get the number of trials
    n_trials = length(good_trials_indices);
    
    for trial_number=1:n_trials
        %                               ---------------- -----------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#)
        %                               ---------------- -----------
        
        % Get the signals:
        % Condition and trial numbers in original dataset
        original_category_number = good_trials_condition_number(trial_number);
        original_trial_number = good_trials_trial_number(trial_number);

        % Get the data of this trial
        trial_path = fullfile(data_path, participant_ID, good_trials_file_name(trial_number));

        [marker_data, forceplate_data, event_data] = get_trial_data(trial_path, markers_guide.reference_guide);
        n_steps = forceplate_data.n_forceplates;
        steps_info = save_steps_info(event_data, forceplate_data, marker_data, n_steps);
        
        % Fix event times:
        % if the step is good,
        % we will change the initial contact and toe-off that we saved
        % according to the GRF (check where the GRF is not 0)
        steps_info = fix_event_times(steps_info, forceplate_data, marker_data);

        % Save data into easier to store format
        [GRF, COP] = save_forceplate_data(forceplate_data);
        trajectories = save_marker_data(marker_data, standing_trial, markers_guide);

        %                                                            -------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / origin
        %                                                            -------
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).origin.catagory = original_category_number;
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).origin.trial_number = original_trial_number;

        %                                                            ----------------------------------------------------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / step_#_info / events , step_quality , foot , plate
        %                                                            ----------------------------------------------------        
        for step_number=1:n_steps
            Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).("step_" + step_number + "_info") = steps_info(step_number);
        end

        %                                                            --------------------------------------------------------------------------------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / GRF / n_forceplates , n_samples , time_vector , sampling_freq , plate_# ,  unit
        %                                                            --------------------------------------------------------------------------------
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).GRF = GRF;

        %                                                            --------------------------------------------------------------------------------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / COP / n_forceplates , n_samples , time_vector , sampling_freq , plate_# ,  unit
        %                                                            --------------------------------------------------------------------------------
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).COP = COP;

        %                                                            -------------------------------------------------------------------------------------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / trajectories / n_markers , n_samples , time_vector , sampling_freq , markers ,  unit
        %                                                            -------------------------------------------------------------------------------------
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).trajectories = trajectories;

        %                                                            ------------------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / walking_direction
        %                                                            ------------------
        % we will check the walking direction by checking if the direction
        % that the SXS marker is moving is +x (+1) or -x (-1)
        direction_marker = trajectories.(markers_guide.reference_guide{"Walking Direction Marker"}{1}).x;
        walking_direction = sign(direction_marker(end) - direction_marker(1));
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value = walking_direction;
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.explenation=...
        "1 - the walking was in the direction from plate 1 to plate 2.\n" + ... 
        "-1 - the walking was in the direction from plate 2 to plate 1.\n";

        %                                                            ------
        % Dataset_2 / Data / participant_# / processed_original_data / trial(#) / speed
        %                                                            ------
        % get the data from steps files:
        speed = calculate_speed(trajectories, event_data, markers_guide.reference_guide{"Walking Direction Marker"}{1});  
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.value = speed;
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.unit = "m/sec";
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.method = ...
        "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
        "Then calculated the mean speed of both feet.";
        
        speed_km_per_hr = PROST.utils.convert_units(PROST.utils.convert_units(speed, "m", "km"), "hour", "second");
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.value = speed_km_per_hr;
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.unit = "km/hour";
        Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.method = ...
        "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
        "Then calculated the mean speed of both feet.\n" + ...
        "Converted from [m/sec] to [km/hr]";

        %                              ---------------
        % Dataset_2 / Data / participant_# / uniform_data
        %                              ---------------

        % reminder: the frame of reference of the processed_original data:
        %           -------------------------------------------------
        % x - the direction (in the lab) from Force_Plate_1 to Force_Plate_2
        % y - in the direction that completes a right handed coordinate system. (left if FP1 was stepped on first)
        %                                                                      (right if FP2 was stepped on first)
        % z - up

        % drawing of the coordinate system:
        %
        %   z          
        %   ^   y          ________________    ________________
        %   |  ^          /               /   /               /
        %   | /          / force_plate_1 /   / force_plate_2 /
        %   |/_ _ _> x  /_______________/   /_______________/

        % and the frame of reference of the uniform data:
        % ---------------------------------------------
        % x - the walking direction (+x or -x)
        % y - to the left (of the body)
        % z - up

        % summery of needed transformation:
        % ---------------------------------
        % new z = old z
        % new x = direction * old x
        % new y = direction * old y

        % summery of temporal alignment:
        % -------------------------
        % the GRF should be temporally aligned (to 101 points) in the stance phase (SP) -> from initial contact to toe off 
        % while the COP and Markers should be temporally aligned (to 101 points) from initial contact to opposite initial contact 

        %                                               ---------------------
        % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#)
        %                                               ---------------------
        n_steps = length(steps_info);
        for step_number=1:n_steps
            if (steps_info(step_number).step_quality == "bad")
                continue;
            end
            side = steps_info(step_number).foot; %side: right or left
            if side == "right"
                right_steps_counter = right_steps_counter + 1;
                step_index = right_steps_counter;
            else
                left_steps_counter = left_steps_counter + 1;
                step_index = left_steps_counter;
            end

            %                                                                      -------
            % Dataset_2 / Data / participant_# / uniform_data / right,left / step(#) / source
            %                                                                      -------
            %                                                                               ---------------
            %                                                                               / original trial
            %                                                                               ---------------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.original_trial = original_category_number + "_" + original_trial_number;
            %                                                                               ----------------------------------
            %                                                                               / original trial number in database
            %                                                                               ----------------------------------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.original_trial_number_in_database = trial_number;
            %                                                                               ---------------------
            %                                                                               / step number in trial
            %                                                                               ---------------------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.step_number = step_number;
            %                                                                               -------------
            %                                                                               / plate number
            %                                                                               -------------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.plate_number = steps_info(step_number).plate;
            %                                                                               ------------------------------------------
            %                                                                               / original_IC , original_OIC , original_TO
            %                                                                               ------------------------------------------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.original_IC = steps_info(step_number).events.IC;
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.original_OIC = steps_info(step_number).events.OIC;
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).source.original_TO = steps_info(step_number).events.TO;

            % Get the walking direction of the trial
            walking_direction = Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value;

            % Size of temporal alignment. We want 101 points so data is
            % in percentage of stance phase \ single support phase.
            n_temporal_alignment = 101;

            %                                                                      ----------------------------
            % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#) / COP   -  temporally aligned
            %                                                                      ----------------------------
            interpolated_COP = interpolate_COP(COP, steps_info(step_number), walking_direction, n_temporal_alignment);
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).COP = interpolated_COP;

            %                                                                      ----------------------------
            % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#) / GRF   -  temporally aligned
            %                                                                      ----------------------------
            % get data:
            interpolated_GRF = interpolate_GRF(GRF, steps_info(step_number), walking_direction, n_temporal_alignment);
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).GRF = interpolated_GRF;

            %                                                                      --------------------------------
            % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#) / Markers   -  temporally aligned
            %                                                                      --------------------------------

            interpolated_Markers = interpolate_trajectories(trajectories, steps_info(step_number), markers_guide, walking_direction, n_temporal_alignment);
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).Markers = interpolated_Markers;


            %                                                                       ------
            % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#) / speed
            %                                                                       ------
            Dataset_2.Data.(participant_name).uniform_data.(side).step(step_index).speed = ...
                Dataset_2.Data.(participant_name).processed_original_data.trial(trial_number).speed;
        end
    end
end

save("..\Dataset_2.mat","Dataset_2")

%% ----------------------------
%  Auxiliary Functions
% -----------------------------
function [metadata, standing_trial] = get_metadata(trial_path, standing_trial_path, markers_guide)
%GET_METADATA reads anthropometric data from the data files of the participant.
% Also gets the standing trial data and calculates missing data from it 
% (leg length, shank length, thigh length etc).
% Input :
%   trial_path - path to the data file of a trial containing the participant 
%                metadata (anthropometric data).
%   standing_trial_path - path to the data file of the standing trial for
%                         calculating missing data.
%   markers_guide - the reference guide for all the important markers.
% Output :
%   metadata - the anthropometric data of the participant.
%   standing_trial - the standing trial measurement data.

    % Get participant metadata
    trial_data_for_metadata = ezc3dRead(convertStringsToChars(trial_path));
    
    % Get standing trial
    data = ezc3dRead(convertStringsToChars(standing_trial_path));
    standing_trial.data = data.data.points;
    standing_trial.unit = string(data.parameters.POINT.UNITS.DATA);
    
    
    % Get given data
    % age
    idx = matches(trial_data_for_metadata.parameters.SUBJECT.LABELS.DATA, "age");
    metadata.Age.value = trial_data_for_metadata.parameters.SUBJECT.VALUES.DATA(idx);
    metadata.Age.unit = "years";
    metadata.Age.method = "given";
    
    % gender
    idx = matches(trial_data_for_metadata.parameters.SUBJECT.LABELS.DATA, "gender");
    if trial_data_for_metadata.parameters.SUBJECT.VALUES.DATA(idx)
        metadata.Gender.value = "Male";
    else
        metadata.Gender.value = "Female";
    end
    metadata.Gender.unit = "Male/Female";
    metadata.Gender.method = "given";
    
    % height
    idx = matches(trial_data_for_metadata.parameters.SUBJECT.LABELS.DATA, "height");
    metadata.Height.value = trial_data_for_metadata.parameters.SUBJECT.VALUES.DATA(idx);
    metadata.Height.unit = "m";
    metadata.Height.method = "given";
    
    % mass
    idx = matches(trial_data_for_metadata.parameters.SUBJECT.LABELS.DATA, "weight");
    metadata.Mass.value = trial_data_for_metadata.parameters.SUBJECT.VALUES.DATA(idx);
    metadata.Mass.unit = "kg";
    metadata.Mass.method = "given";
    
    % Is_shod
    metadata.Is_shod.value = "No";
    metadata.Is_shod.unit = "Yes/No";
    metadata.Is_shod.method = "given";
    
    % Calculate missing metadata from standing trial
    % Marker names:
    % ankle - Lateral Ankle (FAL)
    % knee - Virtual marker calculated from Lateral Femoral Epicondyle (FLE) and
    %        Fibular Head (FAX)
    % asis - ASIS (FTC)
    
    right_ankle = standing_trial.data(:, markers_guide.reference_guide{"Right Lateral Ankle"}{2}); % R_FAL
    left_ankle = standing_trial.data(:, markers_guide.reference_guide{"Left Lateral Ankle"}{2}); % L_FAL
    
    right_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Lateral Femoral Epicondyle"}{2}); % R_FLE
    left_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Lateral Femoral Epicondyle"}{2}); % L_FLE
    right_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Fibular Head"}{2}); % R_FAX
    left_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Fibular Head"}{2}); % L_FAX
    
    right_virtual_knee = PROST.utils.get_knee_marker(right_below_knee, right_ankle, right_below_knee, right_above_knee);
    right_knee = [right_virtual_knee.x; right_virtual_knee.y; right_virtual_knee.z];
    left_virtual_knee = PROST.utils.get_knee_marker(left_below_knee, left_ankle, left_below_knee, left_above_knee);
    left_knee = [left_virtual_knee.x; left_virtual_knee.y; left_virtual_knee.z];
    
    right_asis = standing_trial.data(:, markers_guide.reference_guide{"Right ASIS"}{2}); % R_FTC
    left_asis = standing_trial.data(:,  markers_guide.reference_guide{"Left ASIS"}{2}); % L_FTC
    
    % leg length - from ASIS to lateral ankle
    metadata.Leg_length.right = PROST.utils.convert_units(norm(right_asis - right_ankle), standing_trial.unit, "m");
    metadata.Leg_length.left = PROST.utils.convert_units(norm(left_asis - left_ankle), standing_trial.unit, "m");
    metadata.Leg_length.unit = "m";
    metadata.Leg_length.method = "calculated by distance between ASIS and lateral ankle markers in the standing trial";

    % thigh length - from ASIS to lateral knee
    metadata.Thigh_length.right = PROST.utils.convert_units(norm(right_asis - right_knee), standing_trial.unit, "m");
    metadata.Thigh_length.left = PROST.utils.convert_units(norm(left_asis - left_knee), standing_trial.unit, "m");
    metadata.Thigh_length.unit = "m";
    metadata.Thigh_length.method = "calculated by distance between ASIS and lateral knee markers in the standing trial";
    
    % shank length - from lateral knee to lateral ankle
    metadata.Shank_length.right = PROST.utils.convert_units(norm(right_knee - right_ankle), standing_trial.unit, "m");
    metadata.Shank_length.left = PROST.utils.convert_units(norm(left_knee - left_ankle), standing_trial.unit, "m");
    metadata.Shank_length.unit = "m";
    metadata.Shank_length.method = "calculated by distance between lateral knee and lateral ankle markers in the standing trial";
end

function [marker_data, forceplate_data, event_data] = get_trial_data(trial_path, reference_guide)
%GET_TRIAL_DATA reads the marker and force plate measurements and event 
% information from the data file of a trial.
% Input :
%   trial_path - path to the data file of a trial containing the trial 
%                measurements.
%   markers_guide - the reference guide for all the important markers.
% Output :
%   marker_data - marker trajectory measurements.
%   forceplate_data - force plate measurements.
%   event_data - information of events during the trial (foot strikes and foot
%                offs).

    % get the data of this trial:
    [c3d, fp] = ezc3dRead(convertStringsToChars(trial_path));

    % Get trajectory data
    marker_data.n_samples = size(c3d.data.points, 3); % Number of samples in trial
    marker_data.freq = c3d.parameters.POINT.RATE.DATA; % Sampling frequency. Should be 100 Hz
    marker_data.time_vector = (0:marker_data.n_samples - 1) / marker_data.freq; % Time vector of trial
    marker_data.unit = string(c3d.parameters.POINT.UNITS.DATA); % Trajectory measurement units
    marker_data.n_markers = size(c3d.parameters.POINT.LABELS.DATA, 1); % Number of markers
    marker_data.marker_names = string(c3d.parameters.POINT.LABELS.DATA); % Names of the markers
    marker_data.data = c3d.data.points; % Trial trajectory measurements
    
    if marker_data.n_markers ~= 52
        important_markers = string(cellfun(@(x) x{1}, reference_guide.values, 'UniformOutput', false));
        important_markers(contains(important_markers, "Virtual")) = [];
        if ~all(ismember(important_markers, marker_data.marker_names))
            error("Bad Trial: " + trial_path)
        end
    end

    % Get forceplate data
    forceplate_data.n_samples = size(fp(1).force, 2); % Number of samples in trial
    forceplate_data.n_forceplates = size(fp, 1); % Number of force plates
    % The force-plates were sampled at the same frequency as the EMG
    forceplate_data.freq = c3d.parameters.ANALOG.RATE.DATA; % Sampling frequency. Should be 1500 Hz
    forceplate_data.time_vector = (0:forceplate_data.n_samples - 1) / forceplate_data.freq; % Time vector of trial
    forceplate_data.grf_unit = string(fp(1).unit_force); % GRF measurement units
    forceplate_data.cop_unit = string(fp(1).unit_position); % CoP measurement units
   
    % Trial measurements
    forceplate_data.plate(forceplate_data.n_forceplates) = struct("grf", [], "cop", []); % Preallocate
    for k = 1:forceplate_data.n_forceplates
        forceplate_data.plate(k).grf = fp(k).force; % Copy each vector
        forceplate_data.plate(k).cop = fp(k).center_of_pressure; % Copy each vector
    end

    % Get event data
    event_data.times = c3d.parameters.EVENT.TIMES.DATA(2, :);
    event_data.names = string(c3d.parameters.EVENT.LABELS.DATA)';
    event_data.feet = string(c3d.parameters.EVENT.CONTEXTS.DATA)';

    % Sort event by timeline
    [~, idx] = sort(event_data.times);
    event_data.times = event_data.times(idx);
    event_data.names = event_data.names(idx);
    event_data.feet = event_data.feet(idx);
end

function steps_info = save_steps_info(event_data, forceplate_data, marker_data, n_steps)
%GET_STEPS_INFO saves the step information of all steps in a single trial to our 
% preferred structure format for easier access later.
% Input :
%   event_data - information of events during the trial (foot strikes and foot
%                offs).
%   forceplate_data - force plate measurements.
%   marker_data - marker trajectory measurements. 
%   n_steps - number of steps in the trial.
% Output :
%   steps_info - a struct array with the step information of each step. Includes
%                event (IC, OIC, TO) times and indices in the force plate time
%                vector and trajectory time vector, the foot, the plate and step 
%                quality ("good" or "bad").
    
    % By what frequency to round?
    round_by = max(forceplate_data.freq, marker_data.freq);

    % Indices of events in events vectors for first steps.
    base_IC_index = 1;
    base_OIC_index = 3;
    base_TO_index = 4;
    steps_info(n_steps) = struct("events", [], "step_quality", [], "plate", [], "foot", []);
    feet = strings(n_steps, 1);
    for step_number=1:n_steps
        shift_index = 2*(step_number - 1); % Shift indices of events for each step

        % initial contact
        steps_info(step_number).events.IC.time = event_data.times(base_IC_index + shift_index);
        steps_info(step_number).events.IC.time = round(round_by*(steps_info(step_number).events.IC.time))/round_by;
        [~, steps_info(step_number).events.IC.forceplate_index] = min(abs(steps_info(step_number).events.IC.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.IC.trajectory_index] = min(abs(steps_info(step_number).events.IC.time - marker_data.time_vector));

        % opposite initial contact
        steps_info(step_number).events.OIC.time = event_data.times(base_OIC_index + shift_index);
        steps_info(step_number).events.OIC.time = round(round_by*(steps_info(step_number).events.OIC.time))/round_by;
        [~, steps_info(step_number).events.OIC.forceplate_index] = min(abs(steps_info(step_number).events.OIC.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.OIC.trajectory_index] = min(abs(steps_info(step_number).events.OIC.time - marker_data.time_vector));

        % toe off
        steps_info(step_number).events.TO.time = event_data.times(base_TO_index + shift_index);
        steps_info(step_number).events.TO.time = round(round_by*(steps_info(step_number).events.TO.time))/round_by;
        [~, steps_info(step_number).events.TO.forceplate_index] = min(abs(steps_info(step_number).events.TO.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.TO.trajectory_index] = min(abs(steps_info(step_number).events.TO.time - marker_data.time_vector));

        % foot
        feet(step_number) = lower(event_data.feet(base_IC_index + shift_index));
    end
    steps_info = check_step(steps_info, forceplate_data, feet);
end

function steps_info = check_step(steps_info, forceplate_data, feet)
%CHECK_STEP checks the quality of the step and updates the step information
% accordingly. A "bad" step is one that either started or ended on a force
% plate, had both feet on the plate or had the foot on both steps at the same
% time.
% Input :
%   steps_info - the information of the steps. 
%   forceplate_data - force plate measurements of all plates.
%   feet - the foot of each step according to the data files.
% Output :
%   steps_info - the information of each step updated with the step quality, the 
%                relevant plate and foot (if "good").

    % Tolerance value for time difference.
    tol = 0.1;
    
    % Set default values of steps_info to "bad" steps
    [steps_info.step_quality] = deal("bad");
    [steps_info.plate] = deal(NaN);
    [steps_info.foot] = deal("bad");

    % Get activation and deactivation force plate times
    fp_times = get_forceplate_times(forceplate_data);
    
    % Get event times of IC and TO for each step
    times_IC = arrayfun(@(s) s.events.IC.time, steps_info);
    times_TO = arrayfun(@(s) s.events.TO.time, steps_info);
    
    % Get rid of plates with bad steps
    plates = 1:forceplate_data.n_forceplates;
    idx1 = isnan(fp_times(:, 1)) | isnan(fp_times(:, 2)); % Plates with no activation or deactivation time
    idx2 = [abs(diff(fp_times(:, 1))) < tol; 0] | [abs(diff(fp_times(:, 2))) < tol; 0]; % Plates where foot was on both plates
    plates(idx1 | idx2) = [];

    % Check which step belongs to which plate
    for fp_num=plates
        [~, step_number_IC] = min(abs(times_IC - fp_times(fp_num, 1)));
        [~, step_number_TO] = min(abs(times_TO - fp_times(fp_num, 2)));

        if step_number_IC == step_number_TO 
            step_IC_time = steps_info(step_number_IC).events.IC.time;
            step_TO_time = steps_info(step_number_IC).events.TO.time;
            step_plate = steps_info(step_number_IC).plate;
            step_quality = steps_info(step_number_IC).step_quality;
            if abs(step_IC_time - fp_times(fp_num, 1)) < tol && ...
               abs(step_TO_time - fp_times(fp_num, 2)) < tol && ...
               (step_quality == "bad" || ...
               (abs(step_IC_time - fp_times(step_plate, 1) > abs(step_IC_time - fp_times(fp_num, 1)) && ...
                abs(step_TO_time - fp_times(step_plate, 2)) > abs(step_TO_time - fp_times(fp_num, 2)))))
                % cop_x = forceplate_data.plate(fp_num).cop(1, :);
                % x = cop_x(~isnan(cop_x));
                % dx = diff(x);
                % zero_cross_idx = find(diff(sign(dx)) ~= 0);
                % if ~isempty(zero_cross_idx) && any(diff(zero_cross_idx) > 300)
                %     disp(evalin('base', 'participant_ID') + ", " + evalin('base', 'original_category_number') + "_" + evalin('base', 'original_trial_number') + ": plate = " + fp_num + " step = " + step_number_IC)
                % end
                steps_info(step_number_IC).step_quality = "good";
                steps_info(step_number_IC).plate = fp_num;
                steps_info(step_number_IC).foot = feet(step_number_IC);
            end
        end
    end
end

function [activation_time, deactivation_time] = get_plate_activation_deactivation_times(plate_data, time_vector)
%GET_PLATE_ACTIVATION_DEACTIVATION_TIMES calculates the activation and
% deactivation times of a given force plate. These are the first and last times
% when normal ground reaction force is measured. Default times: NaN.
% Input :
%   plate_data - the measurement data of a single force plate.
%   time_vector - the time vector of the force plate.
% Output :
%   activation_time - the activation time of the force plate.
%   deactivation_time - the deactivation time of the force plate.

    Fz = plate_data.grf(3, :);
    start_index = find(Fz ~= 0 & ~isnan(Fz), 1, 'first');
    end_index = find(Fz ~= 0 & ~isnan(Fz), 1, 'last');
    if isempty(start_index) || start_index == 1
        activation_time = NaN;
    else
        activation_time = time_vector(start_index);
    end
    if isempty(end_index) || end_index == length(Fz)
        deactivation_time = NaN;
    else
        deactivation_time = time_vector(end_index);
    end
end

function fp_times = get_forceplate_times(forceplate_data)
%GET_FORCEPLATE_TIMES calculates the activation and deactivation times of all
% force plates.
% Input :
%   forceplate_data - measurement data of all force plates.
% Output :
%   fp_times - a nx2 array with the activation (column 1) and deactivation
%              (column 2) of each force plate. n is the number of force plates.

    fp_times = zeros(forceplate_data.n_forceplates, 2);
    for fp_number=1:forceplate_data.n_forceplates
        [activation_time, deactivation_time] = get_plate_activation_deactivation_times(forceplate_data.plate(fp_number), forceplate_data.time_vector);
        fp_times(fp_number, 1) = activation_time;
        fp_times(fp_number, 2) = deactivation_time;
    end
end

function steps_info = fix_event_times(steps_info, forceplate_data, marker_data)
%FIX_EVENT_TIMES For each step in the trial, if the step is good, changes the 
% initial contact and toe-off that we saved according to the GRF (checks where 
% the GRF is not 0). If no GRF signal is found changes that step to "bad".
% Input :
%   steps_info - step information of all steps in the trial. 
%   forceplate_data - force plate measurements. 
%   marker_data - marker trajectory measurements. 
% Output :
%   steps_info - the information of all steps updated with the fixed event times 
%                and the step quality.


    for step_num=1:length(steps_info)
        if steps_info(step_num).step_quality == "good"
            % find out what is the right force plate
            fp_num = steps_info(step_num).plate;

            % get the GRF from this force plate
            GRF = forceplate_data.plate(fp_num).grf;

            % get the IC, OIC and TO of this step
            IC_index = steps_info(step_num).events.IC.forceplate_index;
            OIC_index = steps_info(step_num).events.OIC.forceplate_index;
            TO_index = steps_info(step_num).events.TO.forceplate_index;
            
            % Fixing IC Index
            % cut the GRF according to the IC and OIC
            cut_GRF.x = GRF(1, IC_index:OIC_index);
            cut_GRF.y = GRF(2, IC_index:OIC_index);
            cut_GRF.z = GRF(3, IC_index:OIC_index);
            
            % Find data that is in IC:OIC that is not an outlier and has no
            % "inactive" constant value (0 for GRF).
            % is_in = (~isoutlier(cut_GRF.x)) & (~isoutlier(cut_GRF.y)) & (~isoutlier(cut_GRF.z)) & (cut_GRF.z > 0);
            is_in = (cut_GRF.z > 0);
            added_IC = find(is_in, 1, 'first'); 
            
            % Now add the new IC index to the old one
            if isempty(added_IC)
                steps_info(step_num).step_quality = "bad";
                % warning("Bad step because of IC.")
                % warning('Participant %s, condition %d, trial %d: Step %d was reported as good, but no GRF initial contact detected', participant_ID, c, t, step_num);
            else
                % change the IC of this good step:
                new_forceplate_IC_index = IC_index + added_IC - 1;
                [~, new_trajectory_IC_index] = min(abs(forceplate_data.time_vector(new_forceplate_IC_index) - marker_data.time_vector));
                steps_info(step_num).events.IC.forceplate_index = new_forceplate_IC_index;
                steps_info(step_num).events.IC.time = forceplate_data.time_vector(new_forceplate_IC_index);
                steps_info(step_num).events.IC.trajectory_index = new_trajectory_IC_index;
            end
            if ~(mod(steps_info(step_num).events.IC.forceplate_index, 1) == 0) || ~(mod(steps_info(step_num).events.IC.trajectory_index, 1) == 0)
                error("IC index not an integer.\n" + ...
                    "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.IC.forceplate_index, steps_info(step_num).events.IC.trajectory_index)
            end
            
            % Fixing TO Index
            % cut the GRF according to the OIC and TO
            cut_GRF.x = GRF(1, OIC_index:TO_index);
            cut_GRF.y = GRF(2, OIC_index:TO_index);
            cut_GRF.z = GRF(3, OIC_index:TO_index);
            
            % Find data that is in OIC:TO that is not an outlier and has no
            % "inactive" constant value (0 for GRF).
            is_in = (cut_GRF.z > 0);
            added_OIC = find(is_in, 1, 'last'); 
            
            % Now add the new IC index to the old one
            if isempty(added_OIC)
                steps_info(step_num).step_quality = "bad";
                % warning("Bad step because of TO.")
                % warning('Participant %s, condition %d, trial %d: Step %d was reported as good, but no GRF toe-off detected', participant_ID, c, t, step_num);
            else
                % change the IC of this good step:
                new_forceplate_TO_index = OIC_index + added_OIC - 1;
                [~, new_trajectory_TO_index] = min(abs(forceplate_data.time_vector(new_forceplate_TO_index) - marker_data.time_vector));
                steps_info(step_num).events.TO.forceplate_index = new_forceplate_TO_index;
                steps_info(step_num).events.TO.time = forceplate_data.time_vector(new_forceplate_TO_index);
                steps_info(step_num).events.TO.trajectory_index = new_trajectory_TO_index;
            end
            if ~(mod(steps_info(step_num).events.TO.forceplate_index, 1) == 0) || ~(mod(steps_info(step_num).events.TO.trajectory_index, 1) == 0)
                error("TO index not an integer.\n" + ...
                      "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.TO.forceplate_index, steps_info(step_num).events.TO.trajectory_index)
            end
        end
    end
end

function trajectories = save_marker_data(marker_data, standing_trial, markers_guide)
%SAVE_MARKER_DATA saves the measurement data of a single trial from the markers 
% to our preferred structure format for easier access later. Also saves virtual 
% knee trajectories from the given markers.
% Input :
%   marker_data - the measurement data from the markers that we saved from the 
%                 data files.
%   standing_trial - the measurement data from the standing trial. Used for
%                    calculating virtual markers.
%   markers_guide - the reference guide for all the important markers.
% Output :
%   trajectories - trajectory measurements. Includes also units, sampling 
%         frequency, time vector, number of samples and number of markers.

    trajectories.unit = "mm";
    trajectories.time_vector.value = marker_data.time_vector;
    trajectories.time_vector.unit = "second";
    trajectories.sampling_freq.value = marker_data.freq;
    trajectories.sampling_freq.unit = "Hz";
    trajectories.n_markers = marker_data.n_markers;
    trajectories.n_samples = marker_data.n_samples;
    for idx=1:marker_data.n_markers
        marker_name = marker_data.marker_names(idx);
        trajectories.(marker_name).x = squeeze(marker_data.data(1, idx, :))';
        trajectories.(marker_name).y = squeeze(marker_data.data(2, idx, :))';
        trajectories.(marker_name).z = squeeze(marker_data.data(3, idx, :))';
    end

    % Lateral Virtual Knee calculated from Fibula Head (FAX) and
    % Lateral Femoral Epicondyle (FLE)
    right_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Lateral Femoral Epicondyle"}{2}); % R_FLE
    left_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Lateral Femoral Epicondyle"}{2}); % L_FLE
    right_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Fibular Head"}{2}); % R_FAX
    left_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Fibular Head"}{2}); % L_FAX
    trajectories.(markers_guide.reference_guide{"Right Lateral Knee"}{1}) = ...
        PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Right Fibular Head"}{1}), ... % R_FAX
                        trajectories.(markers_guide.reference_guide{"Right Lateral Ankle"}{1}), ...      % R_FAL
                        right_ST_below_knee, right_ST_above_knee);
    trajectories.(markers_guide.reference_guide{"Left Lateral Knee"}{1}) = ...
        PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Left Fibular Head"}{1}), ... % L_FAX
                        trajectories.(markers_guide.reference_guide{"Left Lateral Ankle"}{1}), ...      % L_FAL
                        left_ST_below_knee, left_ST_above_knee);

    % Medial Virtual Knee calculated from Tibial Tuberosity (TTC) and
    % Medial Femoral Epicondyle (FME)
    right_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Medial Femoral Epicondyle"}{2}); % R_FME
    left_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Medial Femoral Epicondyle"}{2}); % L_FME
    right_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Tibial Tuberosity"}{2}); % R_TTC
    left_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Tibial Tuberosity"}{2}); % L_TTC
    trajectories.(markers_guide.reference_guide{"Right Medial Knee"}{1}) = ...
    PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Right Tibial Tuberosity"}{1}), ... % R_TTC
                    trajectories.(markers_guide.reference_guide{"Right Medial Ankle"}{1}), ...      % R_TAM
                    right_ST_below_knee, right_ST_above_knee);
    trajectories.(markers_guide.reference_guide{"Left Medial Knee"}{1}) = ...
    PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Left Tibial Tuberosity"}{1}), ...  % L_TTC
                    trajectories.(markers_guide.reference_guide{"Left Medial Ankle"}{1}), ...       % L_TAM
                    left_ST_below_knee, left_ST_above_knee);
end

function [GRF, COP] = save_forceplate_data(forceplate_data)
%SAVE_FORCEPLATE_DATA saves the measurement data of a single trial from the 
% force plates of to our preferred structure format for easier access later.
% Input :
%   forceplate_data - the measurement data from the force plates that we saved 
%                     from the data files.
% Output :
%   GRF - ground reaction force measurements. Includes also units, sampling 
%         frequency, time vector, number of samples and number of force plates.
%   COP - center of pressure measurements. Includes also units, sampling 
%         frequency, time vector, number of samples and number of force plates.

     % -------------------------------------------
     % the x direction is the direction of walking.
     % the y direction is pointing to the left (of the body).
     % the z direction is pointing up.
     % -------------------------------------------
     for fp_num=1:forceplate_data.n_forceplates
         GRF.("plate_" + fp_num).x = forceplate_data.plate(fp_num).grf(1, :);
         GRF.("plate_" + fp_num).y = forceplate_data.plate(fp_num).grf(2, :);
         GRF.("plate_" + fp_num).z = forceplate_data.plate(fp_num).grf(3, :);

         COP.("plate_" + fp_num).x = forceplate_data.plate(fp_num).cop(1, :);
         COP.("plate_" + fp_num).y = forceplate_data.plate(fp_num).cop(2, :);
         COP.("plate_" + fp_num).z = forceplate_data.plate(fp_num).cop(3, :);
     end
     GRF.unit = "N";
     GRF.sampling_freq.value = forceplate_data.freq;
     GRF.sampling_freq.unit = "Hz";
     GRF.time_vector.value = forceplate_data.time_vector;
     GRF.time_vector.unit = "second";
     GRF.n_forceplates = forceplate_data.n_forceplates;
     GRF.n_samples = forceplate_data.n_samples;

     COP.unit = "mm";
     COP.sampling_freq.value = forceplate_data.freq;
     COP.sampling_freq.unit = "Hz";
     COP.time_vector.value = forceplate_data.time_vector;
     COP.time_vector.unit = "second";
     COP.n_forceplates = forceplate_data.n_forceplates;
     COP.n_samples = forceplate_data.n_samples;
end

function speed = calculate_speed(trajectories, events, walking_marker_name)
%CALCULATE_SPEED estimates the mean walking speed of both steps of the trial 
% from the trajectory measurement data and the times of the foot strikes.
% Here the events are all those of the trial for both steps.
% Input :
%   trajectories - the trajectory measurement data.
%   events - all events of the trial (not the same as step_info), includes all
%            foot strikes of both feet.
%   walking_marker_name - the name of the marker used for estimating the
%                         distance walked during the trial.
% Output :
%   speed - the estimated speed of the trial in [m/sec].

    % Find foot strike times
    n_events = length(events.names);
    strike_times = struct("Left", [], "Right", []);
    for idx=1:n_events
        if strcmp(events.names(idx), "Foot Strike1") || strcmp(events.names(idx), "Foot Strike2")
            foot = events.feet(idx);
            time = events.times(idx);
            strike_times.(foot) = [strike_times.(foot) time];
        end
    end

    % Calculate speed
    sides = string(fields(strike_times));
    n_sides = length(sides);
    speed = nan(1, n_sides);
    for side_num=1:n_sides     
        % Get strike times and indices of the side
        strikes = strike_times.(sides(side_num));
        if length(strikes) ~= 2
            continue
        end
        time_start = strikes(1);
        time_end = strikes(2);
        [~, index_start] = min(abs(time_start - trajectories.time_vector.value));
        [~, index_end] = min(abs(time_end - trajectories.time_vector.value));

        % we chose to calculate the distance using the marker for the walking
        % direction (the SXS marker)
        distance_marker = [trajectories.(walking_marker_name).x; 
                           trajectories.(walking_marker_name).y];
        distance = norm([distance_marker(1, index_end) - distance_marker(1, index_start);...
                         distance_marker(2, index_end) - distance_marker(2, index_start)]); % [mm]
        distance = PROST.utils.convert_units(distance, trajectories.unit, "m"); % [m]
        
        % Calculate speed of the side
        duration = time_end - time_start;
        if trajectories.time_vector.unit ~= "second"
            duration = PROST.utils.convert_units(duration, trajectories.time_vector.unit, "second");
        end
        speed(side_num) = distance/duration; % [m/sec]
    end
    speed = mean(speed, 'omitnan');
end

function interpolated_COP = interpolate_COP(COP, step_info, walking_direction, n_temporal_alignment)
%INTERPOLATE_COP converts the center of pressure (COP) measurements to our 
% coordinate system and interpolates into n_temporal_alignment points from 
% initial contact to opposite initial contact.
% By default n_temporal_alignment is 101 points thus the trajectories are 
% aligned to a percent of the phase.
% Input :
%   COP - the center of pressure measurement data.
%   step_info - the information on the step to align. Includes event times and
%               indices.
%   walking_direction - the walking direction.
%   n_temporal_alignment - the number of points to interpolate into.
% Output :
%   interpolated_COP - the transformed and interpolated measurements.
    
    % Default size of temporal alignment. We want 101 points so data is
    % in percentage of stance phase \ single support phase.
    if nargin < 4
        n_temporal_alignment = 101;
    end

    % Force plate number
    fp_num = step_info.plate;

    % Get event indices of the force plate measurements
    IC_index = step_info.events.IC.forceplate_index;
    OIC_index = step_info.events.OIC.forceplate_index;

    % get data (get the COP of the fitting plate:
    interpolated_COP.x = walking_direction*COP.("plate_" + fp_num).x;
    interpolated_COP.y = walking_direction*COP.("plate_" + fp_num).y;
    interpolated_COP.z = COP.("plate_" + fp_num).z;

    % % cut the COP from IC to OIC filter it and temporally align to 101 points
    interpolated_COP.x = interp1(IC_index:OIC_index, interpolated_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_COP.y = interp1(IC_index:OIC_index, interpolated_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_COP.z = interp1(IC_index:OIC_index, interpolated_COP.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

    interpolated_COP.unit = "mm";
    interpolated_COP.temporal_alignment = "Initial contact to opposite initial contact.";
end

function interpolated_GRF = interpolate_GRF(GRF, step_info, walking_direction, n_temporal_alignment)
%INTERPOLATE_GRF converts the ground reaction force (GRF) measurements to our 
% coordinate system and interpolates into n_temporal_alignment points of the 
% stance phase (from initial contact to toe off).
% By default n_temporal_alignment is 101 points thus the trajectories are 
% aligned to a percent of the phase.
% Input :
%   GRF - the ground reaction force measurement data.
%   step_info - the information on the step to align. Includes event times and
%               indices.
%   walking_direction - the walking direction.
%   n_temporal_alignment - the number of points to interpolate into.
% Output :
%   interpolated_GRF - the transformed and interpolated measurements.

    % Default size of temporal alignment. We want 101 points so data is
    % in percentage of stance phase \ single support phase.
    if nargin < 4
        n_temporal_alignment = 101;
    end
    
    % Force plate number
    fp_num = step_info.plate;

    % Get event indices of the force plate measurements
    IC_index = step_info.events.IC.forceplate_index;
    OIC_index = step_info.events.OIC.forceplate_index;
    TO_index = step_info.events.TO.forceplate_index;

    % get data (get the GRF of the fitting plate:
    interpolated_GRF.x = walking_direction*GRF.("plate_" + fp_num).x;
    interpolated_GRF.y = walking_direction*GRF.("plate_" + fp_num).y;
    interpolated_GRF.z = GRF.("plate_" + fp_num).z;

    % % cut the GRF from IC to TO filter it and temporally align to 101 points
    interpolated_GRF.x = interp1(IC_index:TO_index, interpolated_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
    interpolated_GRF.y = interp1(IC_index:TO_index, interpolated_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
    interpolated_GRF.z = interp1(IC_index:TO_index, interpolated_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));

    interpolated_GRF.unit = "N";
    interpolated_GRF.temporal_alignment = "Initial contact to toe off (stance phase).";

    % OIC event after temporal alignment
    interpolated_GRF.OIC.time = round((n_temporal_alignment - 1)*(OIC_index - IC_index)/(TO_index - IC_index));
    interpolated_GRF.OIC.index = interpolated_GRF.OIC.time + 1;
end

function interpolated_Markers = interpolate_trajectories(trajectories, step_info, markers_guide, walking_direction, n_temporal_alignment)
%INTERPOLATE_TRAJECTORIES converts the trajectory measurements to our coordinate 
% system and interpolates into n_temporal_alignment points of the weight 
% acceptance + single support phase (from initial contact to opposite initial 
% contact). 
% By default n_temporal_alignment is 101 points thus the trajectories are 
% aligned to a percent of the phase.
% Input :
%   trajectories - the trajectory measurement data.
%   step_info - the information on the step to align. Includes event times and
%               indices.
%   markers_guide - the reference guide for all the important markers.
%   walking_direction - the walking direction.
%   n_temporal_alignment - the number of points to interpolate into.
% Output :
%   interpolated_Markers - the transformed and interpolated measurements.

    % Default size of temporal alignment. We want 101 points so data is
    % in percentage of stance phase \ single support phase.
    if nargin < 4
        n_temporal_alignment = 101;
    end
    % Foot of the step
    foot = PROST.utils.capitalize(step_info.foot);

    % Get event indices of the trajectory measurements
    IC_index = step_info.events.IC.trajectory_index;
    OIC_index = step_info.events.OIC.trajectory_index;
    
    % --------------------------------------------------
    % first we need to decide what markers interest us:
    % FAL - external ankle
    % TAM - internal ankle
    % LatVirtualKnee - external knee
    % MedVirtualKnee - internal ankle
    % we should also calculate the mean between the internal and
    % the external markers.
    % --------------------------------------------------
    % get the markers data :
    % For the ankle:
    interpolated_Markers.Ankle.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).x;
    interpolated_Markers.Ankle.lateral.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).y;
    interpolated_Markers.Ankle.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).z;
    interpolated_Markers.Ankle.medial.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).x;
    interpolated_Markers.Ankle.medial.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).y;
    interpolated_Markers.Ankle.medial.z = trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).z;

    % For the knee:
    interpolated_Markers.Knee.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).x;
    interpolated_Markers.Knee.lateral.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).y;
    interpolated_Markers.Knee.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).z;
    interpolated_Markers.Knee.medial.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).x;
    interpolated_Markers.Knee.medial.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).y;
    interpolated_Markers.Knee.medial.z = trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).z;

    % Cut the ankle markers data from IC to OIC and temporally align it to 101 points :
    interpolated_Markers.Ankle.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.medial.x = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.medial.y = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.medial.z = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

    % Calculate mean ankle marker from medial and lateral
    interpolated_Markers.Ankle.mean.x = (interpolated_Markers.Ankle.lateral.x + interpolated_Markers.Ankle.medial.x)/2;
    interpolated_Markers.Ankle.mean.y = (interpolated_Markers.Ankle.lateral.y + interpolated_Markers.Ankle.medial.y)/2;
    interpolated_Markers.Ankle.mean.z = (interpolated_Markers.Ankle.lateral.z + interpolated_Markers.Ankle.medial.z)/2;

    % Cut the knee markers data from IC to OIC and temporally align it to 101 points :
    interpolated_Markers.Knee.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.medial.x = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.medial.y = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.medial.z = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

    % Calculate mean knee marker from medial and lateral
    interpolated_Markers.Knee.mean.x = (interpolated_Markers.Knee.lateral.x + interpolated_Markers.Knee.medial.x)/2;
    interpolated_Markers.Knee.mean.y = (interpolated_Markers.Knee.lateral.y + interpolated_Markers.Knee.medial.y)/2;
    interpolated_Markers.Knee.mean.z = (interpolated_Markers.Knee.lateral.z + interpolated_Markers.Knee.medial.z)/2;

    interpolated_Markers.unit = "mm";
    interpolated_Markers.temporal_alignment = "Initial contact to opposite initial contact.";
end

function good_trials = get_good_trials(data_path, reference_guide)
%GET_GOOD_TRIALS Returns a list of the file names of good trials. Good trials 
% are defined as trials that exist in the dataset and include all the important 
% markers needed for our dataset.
% Input : 
%   data_path - the path to the data files.
%   reference_guide - the reference guide for all the important markers in the 
%                     dataset.
% Output :
%   good_trials - an nx3 array with the participant IDs, speed condition and
%                 trial number of good trials.
% Note : the virtual markers for the knees in the markers guide are are not
%        needed and screened out.


    % Get all participant IDs
    folders = dir(data_path); % List all items
    folders = folders([folders.isdir]); % Keep only directories
    participant_IDs = setdiff({folders.name}, {'.','..'}); % Remove '.' and '..'
    
    % Number of participants
    n_participants = length(participant_IDs);

    % Initialize lists of good files and good participants
    good_trials = strings(n_participants*25, 3);
    
    % Check who to keep
    counter = 1;
    for participant_number=1:n_participants
        participant_ID = string(participant_IDs(participant_number));

        % find which of the trials exist and are good for this participant
        % Some of the participants have less than the maximum amount of trials.
        % Some trials are missing markers that are needed.
        % good_trials = strings(25, 1);    
        
        for condition_num = ["C1" "C2" "C3" "C4" "C5"]
            for trial_num = ["01" "02" "03" "04" "05"]
                file_name = participant_ID + "_" + condition_num + "_" + trial_num + ".c3d";
                file_path = fullfile(data_path, participant_ID, file_name);
                if (isfile(file_path))
                    c3d = ezc3dRead(convertStringsToChars(file_path));

                    % Get trajectory data
                    n_samples = size(c3d.data.points, 3); % Number of samples in trial
                    n_markers = size(c3d.parameters.POINT.LABELS.DATA, 1); % Number of markers
                    data = c3d.data.points; % Trial measurements
                    marker_names = string(c3d.parameters.POINT.LABELS.DATA);
                    important_markers = string(cellfun(@(x) x{1}, reference_guide.values, 'UniformOutput', false));
                    important_markers(contains(important_markers, "Virtual")) = [];

                    if n_samples == size(data, 3) && n_markers == size(data, 2) && 3 == size(data, 1)
                        if n_markers ~= 52
                            if ~all(ismember(important_markers, marker_names))
                                continue
                            end
                        end
                        good_trials(counter, 1) = participant_ID;
                        good_trials(counter, 2) = condition_num;
                        good_trials(counter, 3) = trial_num;
                        counter = counter + 1;
                    end
                end
            end
        end
    end
    good_trials = good_trials(1:counter-1, :);

    % Filter trials manually
    % good_trials(good_trials(:, 1) == "2014040" & good_trials(counter, 2) == "C5" & ismember(good_trials(counter, 3), ["03" "04" "05"])) = [];
end

function tf = is_good_trial(c3d, reference_guide)
    % Get trajectory data
    data = c3d.data.points; % Trial measurements
    n_samples = size(data, 3); % Number of samples in trial
    n_markers = size(c3d.parameters.POINT.LABELS.DATA, 1); % Number of markers
    marker_names = string(c3d.parameters.POINT.LABELS.DATA);
    important_markers = string(cellfun(@(x) x{1}, reference_guide.values, 'UniformOutput', false));

    if n_markers == size(data, 2) && 3 == size(data, 1)
        if n_markers ~= 52
            if ~all(ismember(important_markers, marker_names))
                tf = false;
            end
        end
    else
        tf = false;
    end
end