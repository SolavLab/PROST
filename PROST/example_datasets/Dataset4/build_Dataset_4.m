%% ------------------------------------------------------------------
%  build a matlab structure containing the fourth dataset data
%  Created by Chen Reichsbouscher, 11.12.2025
% -------------------------------------------------------------------
%
clearvars -except -regexp ^Dataset_\d+$ good_trials raw_data all_metadata
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
% Dataset_4 / article_data :
%       -------------
article_data.article_name = "A full-body motion capture gait dataset of 138 able-bodied adults across the life span and 50 stroke survivors";
article_data.authors = "Tamaya Van Criekinge, Wim Saeys, Steven Truijen, Luc Vereeck, Lizeth H. Sloot & Ann Hallemans";
article_data.link_to_paper = "https://doi.org/10.1038/s41597-023-02767-y";
article_data.link_to_dataset = "https://doi.org/10.6084/m9.figshare.c.6503791.v1";
article_data.published_year = 2023;

Dataset_4.Article_data = article_data;

%       -------------
% Dataset_4 / marker_names :
%       -------------
markers_guide.explanation_txt = "The field reference_guide containes a dictionary that defines the names and indices of important markers in the original dataset.\n" + ...
                                "The keys: which part each marker is reffering to for cohesiveness between the different datasets.\n" + ...
                                "The values: a cell array with the data of that marker in the original dataset.\n" + ...
                                "Column 1: the name they gave this marker in the article / original dataset.\n" + ...
                                "Column 2: the number of the column in the original trajectories database for the X, Y and Z coordinates." + ...
                                "The field virtual_reference_guide contains a dictionary that defines the names of the virtual markers we estimate from the markers in the original dataset." + ...
                                "The keys: which part each marker is reffering to for cohesiveness between the different datasets.\n" + ...
                                "The values: the name of each virtual marker.\n" + ...
                                "----------------------------------------------------------- \n";
% Important markers reference guide
keys = ["Right Lateral Ankle"; ...
        "Right Lateral Knee"; ...
        "Right ASIS"; ...
        "Left Lateral Ankle"; ...
        "Left Lateral Knee"; ...
        "Left ASIS"; ...
        "Walking Direction Marker"];
values = {{"RANK"};...
          {"RKNE"};...
          {"RASI"};...
          {"LANK"};...
          {"LKNE"};...
          {"LASI"};...
          {"C7"}};
markers_guide.reference_guide = dictionary(keys, values);
markers_guide.virtual_reference_guide = dictionary;
Dataset_4.Markers_guide = markers_guide;

%       --------------------
% Dataset_4 / Lab_system :
%       --------------------
Lab_system.lab_frame = ...
    "X Direction: \n" + ...
    "The x direction is the direction in the lab from the first force-plate to the last force-plate.\n" + ...
    "(this is the walking direction for trials where the first force-plate was stepped on first,\n" + ...
    "and minus the walking direction for trials where the second force-plate was stepped on first).\n" + ...
    "Y Direction: \n" + ...
    "The y direction completes a right-handed system.\n" + ...
    "Z Direction: \n" + ...
    "The z direction is pointing up.";
Lab_system.num_forceplates = 4;

Dataset_4.Lab_system = Lab_system;

%       ---------------------
% Dataset_4 / Experiment_protocol :
%       ---------------------

% Explanation for how the experiment was conducted generally.
Experiment_protocol.explanation_txt = ...
    "Relevant text taken from Van Criekinge et. al.:\n\n" + ...
    "In total, 138 able-bodied individuals (21–86 years) and 50 stroke survivors (19–85 years, not used) were included in the datasets.\n" + ...
    "Able-bodied participants were excluded from the study if they had self-reported visual impairments, an antalgic gait pattern, abnormal mobility in the lower limbs or any known neurological or orthopaedic disorder that could influence motor performance and balance.\n" + ...
    "No medical records were obtained from these volunteers.\n\n" + ...
    "They were asked to change into tight-fitting shorts and short sleeve t-shirts without shoes, to ensure all markers were placed on the skin and not covered by clothes.\n" + ...
    "Nor did they wear a safety harness or were otherwise restrained during data collection.\n\n" + ...
    "First, the following anthropometric measurements were taken: body mass, height, and leg length (measured as the longitudinal distance between spina iliaca anterior superior and malleoli medialis in supine).\n\n" + ...
    "Reflective markers were attached to bony anatomical landmarks according to the standard Plug-In Gait full body model.\n" + ...
    "Bony landmarks were located by manual palpation by the same investigator who underwent extensive training.\n" + ...
    "Reflective markers were firmly affixed to the skin twice (double-sided tape and skin-sensitive tape).\n\n" + ...
    "When subject preparation was completed, a static calibration was performed with the knee alignment device which aids in defining the flexion axis of the knee.\n" + ...
    "Participants were asked to stand still in the middle of one force platform with arms fully extended to the sides and thumbs facing down (i.e. base pose defined by the Vicon user guide).\n" + ...
    "The static trial was checked for full marker visibility and repeated if needed.\n\n" + ...
    "Subsequently, participants walked over a 12-meter walkway at a self-selected speed.\n" + ...
    "Participants walked without walking aids or orthoses.\n" + ...
    "Participants were instructed 'to walk as usual, not to mind the markers on their body, to look forward and not to interact with anyone during the walking trials'.\n" + ...
    "No information was provided concerning the purpose of the ground-embedded force plates to avoid any targeting.\n\n" + ...
    "The aim was to record a minimum of six walking trials during steady-state walking phase without gait initiation and termination, and with three ‘correct’ heel strikes on the force plates from the right and three from the left stride without contact of the other foot on the force plate.\n" + ...
    "A detailed description per participant of how many clean strikes were retrieved and the need for assistance can be found in the data records paragraph.";
Experiment_protocol.speed_categories = "";
Experiment_protocol.num_participants = 138;

Dataset_4.Experiment_protocol = Experiment_protocol;

%% Read List of Good Trials
if ~exist("good_trials", "var")
    good_trials = read_good_trials_table(data_path);
end

%% Load Data Files
% load raw data
if ~exist("raw_data", "var")
    load(fullfile(data_path, "raw_data.mat"));
end

% load metadata
if ~exist("all_metadata", "var")
    all_metadata = read_metadata_table(data_path);
end

%% -----------------------------
%  participant specific info:
% ------------------------------
% Number of participants
n_participants = numel(good_trials);

% Get relevant marker names in original dataset
markers_guide = Dataset_4.Markers_guide;

for participant_number=1:n_participants
    % Get participant name and original ID from number
    participant_ID = good_trials(participant_number).SubjID;
    original_participant_number =  good_trials(participant_number).SubjNum;
    participant_name = "participant_" + string(participant_number);
   
    % Initializing counters for right and left steps of all trials
    right_steps_counter = 0; left_steps_counter = 0;

    % Get participant metadata and standing trial data
    standing_trial_data = raw_data(original_participant_number).standing_trial;
    participant_metadata = all_metadata(original_participant_number);

    %                              -------------------------------------
    % Dataset_4 / Data / participant_# / participant_ID_in_original_structure :
    %                              -------------------------------------
    % the participant ID in the original data structure:
    Dataset_4.Data.(participant_name).participant_ID_in_original_structure = participant_ID;

    %                              ---------
    % Dataset_4 / Data / participant_# / metadata :
    %                              ---------

    % Get metadata
    [metadata, standing_trial] = get_metadata(participant_metadata, standing_trial_data, markers_guide);
    Dataset_4.Data.(participant_name).metadata = metadata;

    %                                               ---------------------
    % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#)
    %                                               ---------------------
    % Prepping uniform data database
    Dataset_4.Data.(participant_name).uniform_data.right.step = [];
    Dataset_4.Data.(participant_name).uniform_data.left.step = [];

    % Get the number of trials
    n_trials = numel(good_trials(participant_number).trials);

    for trial_number=1:n_trials
        try
        %                               ---------------- -----------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#)
        %                               ---------------- -----------
        
        % Get the signals:
        % trial number in original dataset
        original_trial_number = good_trials(participant_number).trials(trial_number).trial_num;
        
        % Raw data of trial
        trial_data = raw_data(original_participant_number).trial(original_trial_number == [raw_data(original_participant_number).trial.trial_num]);
        good_forceplates = good_trials(participant_number).trials(trial_number).forceplates;
        good_segments = good_trials(participant_number).trials(trial_number).segments;
        [marker_data, forceplate_data, event_data] = get_trial_data(trial_data, markers_guide.reference_guide);
        % Number of steps in a trial
        n_steps = 3; % There should be 3 full steps at each trial (IC to TO of the same foot)

        % Save information for each step
        steps_info = save_steps_info(event_data, forceplate_data, marker_data, n_steps, good_forceplates, good_segments);

        % Fix event times:
        % if the step is good,
        % we will change the initial contact and toe-off that we saved
        % according to the GRF (check where the GRF is not 0)
        steps_info = fix_event_times(steps_info, forceplate_data, marker_data);

        % Save data into easier to store format
        [GRF, COP] = save_forceplate_data(forceplate_data);
            trajectories = save_marker_data(marker_data);

        %                                                            -------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / origin
        %                                                            -------
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).origin.trial_number = original_trial_number;

        %                                                            ----------------------------------------------------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / step_#_info / events , step_quality , foot , plate
        %                                                            ----------------------------------------------------        
        for step_number=1:n_steps
            Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).("step_" + step_number + "_info") = steps_info(step_number);
        end

        %                                                            --------------------------------------------------------------------------------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / GRF / n_forceplates , n_samples , time_vector , sampling_freq , plate_# ,  unit
        %                                                            --------------------------------------------------------------------------------
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).GRF = GRF;

        %                                                            --------------------------------------------------------------------------------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / COP / n_forceplates , n_samples , time_vector , sampling_freq , plate_# ,  unit
        %                                                            --------------------------------------------------------------------------------
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).COP = COP;

        %                                                            -------------------------------------------------------------------------------------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / trajectories / n_markers , n_samples , time_vector , sampling_freq , markers ,  unit
        %                                                            -------------------------------------------------------------------------------------
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).trajectories = trajectories;

        %                                                            ------------------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / walking_direction
        %                                                            ------------------
        % we will check the walking direction by checking if the direction
        % that the SXS marker is moving is +x (+1) or -x (-1)
        direction_marker = trajectories.(markers_guide.reference_guide{"Walking Direction Marker"}{1}).x;
        direction_marker = direction_marker(~isnan(direction_marker));
        if isempty(direction_marker)
            error("PROST:OnlyNaNs", "Direction marker contains only NaNs.")
        end
        walking_direction = sign(direction_marker(end) - direction_marker(1));
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value = walking_direction;
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.explenation=...
        "1 - the walking was in the direction from plate 1 to plate 4.\n" + ... 
        "-1 - the walking was in the direction from plate 4 to plate 1.\n";

        %                                                            ------
        % Dataset_4 / Data / participant_# / processed_original_data / trial(#) / speed
        %                                                            ------
        % get the data from steps files:
        speed = calculate_speed(trajectories, event_data, markers_guide.reference_guide{"Walking Direction Marker"}{1});  
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.value = speed;
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.unit = "m/sec";
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.m_per_sec.method = ...
        "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
        "Then calculated the mean speed of both feet.";
        
        speed_km_per_hr = PROST.utils.convert_units(PROST.utils.convert_units(speed, "m", "km"), "hour", "second");
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.value = speed_km_per_hr;
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.unit = "km/hour";
        Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed.km_per_hour.method = ...
        "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
        "Then calculated the mean speed of both feet.\n" + ...
        "Converted from [m/sec] to [km/hr]";

        %                              ---------------
        % Dataset_4 / Data / participant_# / uniform_data
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
        %   ^   y          ________________    ________________    ________________
        %   |  ^          /               /   /               /   /               /
        %   | /          / force_plate_1 /   / force_plate_2 /   / force_plate_4 /
        %   |/_ _ _> x  /_______________/   /_______________/   /_______________/
        %                          ________________
        %                         /               /
        %                        / force_plate_3 / 
        %                       /_______________/
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
        % while the COP and Markers should be temporally aligned (to 101 points) in the weight acceptance + single support phase (SS) -> from initial contact to opposite initial contact 

        %                                               ---------------------
        % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#)
        %                                               ---------------------
        n_steps = length(steps_info);
        for step_number=1:n_steps
            if (steps_info(step_number).step_quality == "bad")
                continue;
            end
            side = steps_info(step_number).foot; % side: right or left
            if side == "right"
                right_steps_counter = right_steps_counter + 1;
                step_index = right_steps_counter;
            else
                left_steps_counter = left_steps_counter + 1;
                step_index = left_steps_counter;
            end

            %                                                                      -------
            % Dataset_4 / Data / participant_# / uniform_data / right,left / step(#) / source
            %                                                                      -------
            %                                                                               ---------------
            %                                                                               / original trial
            %                                                                               ---------------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.original_trial = string(original_trial_number);
            %                                                                               ----------------------------------
            %                                                                               / original trial number in database
            %                                                                               ----------------------------------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.original_trial_number_in_database = trial_number;
            %                                                                               ---------------------
            %                                                                               / step number in trial
            %                                                                               ---------------------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.step_number = step_number;
            %                                                                               -------------
            %                                                                               / plate number
            %                                                                               -------------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.plate_number = steps_info(step_number).plate;
            %                                                                               ------------------------------------------
            %                                                                               / original_IC , original_OIC , original_TO
            %                                                                               ------------------------------------------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.original_IC = steps_info(step_number).events.IC;
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.original_OIC = steps_info(step_number).events.OIC;
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).source.original_TO = steps_info(step_number).events.TO;

            % Get the walking direction of the trial
            walking_direction = Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction.value;

            % Size of temporal alignment. We want 101 points so data is
            % in percentage of stance phase \ single support phase.
            n_temporal_alignment = 101;

            %                                                                      ----------------------------
            % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#) / COP   -  temporally aligned
            %                                                                      ----------------------------
            interpolated_COP = interpolate_COP(COP, steps_info(step_number), walking_direction, n_temporal_alignment);
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).COP = interpolated_COP;

            %                                                                      ----------------------------
            % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#) / GRF   -  temporally aligned
            %                                                                      ----------------------------
            % get data:
            interpolated_GRF = interpolate_GRF(GRF, steps_info(step_number), walking_direction, n_temporal_alignment);
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).GRF = interpolated_GRF;

            %                                                                      --------------------------------
            % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#) / Markers   -  temporally aligned
            %                                                                      --------------------------------
            interpolated_Markers = interpolate_trajectories(trajectories, steps_info(step_number), markers_guide, walking_direction, n_temporal_alignment);
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).Markers = interpolated_Markers;


            %                                                                       ------
            % Dataset_4 / Data / participant_# / uniform_data / Right,Left / step(#) / speed
            %                                                                       ------
            Dataset_4.Data.(participant_name).uniform_data.(side).step(step_index).speed = ...
                Dataset_4.Data.(participant_name).processed_original_data.trial(trial_number).speed;

        end
        catch ME
            disp(participant_name + ", " + trial_number + " (" + good_trials(participant_number).trials(trial_number).file_name + "): " + ME.identifier + ":" + ME.message)
            continue
        end
    end
end

save("..\Dataset_4.mat","Dataset_4")

%% ----------------------------
%  Auxiliary Functions
% -----------------------------
function [metadata, standing_trial] = get_metadata(participant_metadata, standing_trial_raw, markers_guide)
%GET_METADATA reads anthropometric data from the data files of the participant.
% Also gets the standing trial data and calculates missing data from it 
% (leg length, shank length, thigh length etc).
% Input :
%   participant_metadata - anthropometric data of the participant given by the 
%                          dataset.
%   standing_trial_raw - raw data of the standing trial for calculating missing 
%                        data.
%   markers_guide - the reference guide for all the important markers.
% Output :
%   metadata - the anthropometric data of the participant.
%   standing_trial - the standing trial measurement data.

    
    % Get standing trial
    standing_trial.data = standing_trial_raw.c3d.data.points;
    standing_trial.marker_names = string(standing_trial_raw.c3d.parameters.POINT.LABELS.DATA);
    standing_trial.n_markers = numel(standing_trial.marker_names);
    assert(standing_trial.n_markers == size(standing_trial.data, 2))
    assert(3 == size(standing_trial.data, 1))
    standing_trial.unit = string(standing_trial_raw.c3d.parameters.POINT.UNITS.DATA);
    
    important_markers = [markers_guide.reference_guide{"Right Lateral Ankle"}{1}, ...
                         markers_guide.reference_guide{"Left Lateral Ankle"}{1}, ...
                         markers_guide.reference_guide{"Right Lateral Knee"}{1}, ...
                         markers_guide.reference_guide{"Left Lateral Knee"}{1}, ...
                         markers_guide.reference_guide{"Right ASIS"}{1}, ...
                         markers_guide.reference_guide{"Left ASIS"}{1}];
    if ~all(ismember(important_markers, standing_trial.marker_names))
        missing_markers = important_markers(~ismember(important_markers, standing_trial.marker_names));
        error("PROST:BadTrial", "Bad Trial: missing %s", join(missing_markers, ", "))
    end

    % age
    metadata.Age.value = participant_metadata.Age.value;
    metadata.Age.unit = "years";
    metadata.Age.method = "given";
    
    % gender
    if strcmp(participant_metadata.Gender.value, 'M')
        metadata.Gender.value = "Male";
    else
        metadata.Gender.value = "Female";
    end
    metadata.Gender.unit = "Male/Female";
    metadata.Gender.method = "given";
    
    % height
    metadata.Height.value = PROST.utils.convert_units(participant_metadata.Height.value, participant_metadata.Height.unit, "m");
    metadata.Height.unit = "m";
    metadata.Height.method = "given";
    
    % mass
    metadata.Mass.value = PROST.utils.convert_units(participant_metadata.Mass.value, participant_metadata.Mass.unit, "kg");
    metadata.Mass.unit = "kg";
    metadata.Mass.method = "given";
    
    % Is_shod
    metadata.Is_shod.value = "No";
    metadata.Is_shod.unit = "Yes/No";
    metadata.Is_shod.method = "given";
    
    % Calculate missing metadata from standing trial
    % Marker names:
    % ankle - Lateral Ankle (ANK)
    % knee - Lateral Knee (KNE)
    % asis - ASIS (ASI)
    i_right_ankle = matches(standing_trial.marker_names, markers_guide.reference_guide{"Right Lateral Ankle"}{1}); % RANK
    right_ankle = standing_trial.data(:, i_right_ankle, :); % RANK
    right_ankle = mean(squeeze(right_ankle), 2, "omitmissing");

    i_left_ankle = matches(standing_trial.marker_names, markers_guide.reference_guide{"Left Lateral Ankle"}{1}); % LANK
    left_ankle = standing_trial.data(:, i_left_ankle, :); % LANK
    left_ankle = mean(squeeze(left_ankle), 2, "omitmissing");
    
    i_right_knee = matches(standing_trial.marker_names, markers_guide.reference_guide{"Right Lateral Knee"}{1}); % RKNE
    right_knee = standing_trial.data(:, i_right_knee, :); % RKNE
    right_knee = mean(squeeze(right_knee), 2, "omitmissing");
    
    i_left_knee = matches(standing_trial.marker_names, markers_guide.reference_guide{"Left Lateral Knee"}{1}); % LKNE
    left_knee = standing_trial.data(:, i_left_knee, :); % LKNE
    left_knee = mean(squeeze(left_knee), 2, "omitmissing");

    i_right_asis = matches(standing_trial.marker_names, markers_guide.reference_guide{"Right ASIS"}{1}); % RASI
    right_asis = standing_trial.data(:, i_right_asis, :); % RASI
    right_asis = mean(squeeze(right_asis), 2, "omitmissing");

    i_left_asis = matches(standing_trial.marker_names, markers_guide.reference_guide{"Left ASIS"}{1}); % LASI
    left_asis = standing_trial.data(:,  i_left_asis, :); % LASI
    left_asis = mean(squeeze(left_asis), 2, "omitmissing");

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

function [marker_data, forceplate_data, event_data] = get_trial_data(trial_data, reference_guide)
%GET_TRIAL_DATA reads the marker and force plate measurements and event 
% information from the data of a trial.
% Input :
%   trial_data - the data of a trial containing the trial measurements.
%   reference_guide - the reference guide for all the important markers.
% Output :
%   marker_data - marker trajectory measurements.
%   forceplate_data - force plate measurements.
%   event_data - information of events during the trial (foot strikes and foot
%                offs).

    % get the data of this trial:
    c3d = trial_data.c3d;
    fp = trial_data.fp;

    % Get trajectory data
    marker_data.n_samples = size(c3d.data.points, 3); % Number of samples in trial
    marker_data.freq = c3d.parameters.POINT.RATE.DATA; % Sampling frequency. Should be 100 Hz
    assert(marker_data.freq == 100)
    marker_data.time_vector = (0:marker_data.n_samples - 1) / marker_data.freq; % Time vector of trial
    marker_data.unit = string(c3d.parameters.POINT.UNITS.DATA); % Trajectory measurement units
    
    % Some markers were saved with the participant identifier so we need to
    % change that.
    data_labels = c3d.parameters.POINT.LABELS.DATA;
    function s_new = takeout_subject_name(s_old)
        s_idx = strfind(s_old, ":");
        if isempty(s_idx)
            s_idx = 0;
        end
        s_new = s_old(s_idx+1:end);
    end
    data_labels = cellfun(@takeout_subject_name, data_labels, 'UniformOutput', false);

    marker_data.n_markers = length(data_labels); % Number of markers
    marker_data.marker_names = convertCharsToStrings(matlab.lang.makeValidName(data_labels)); % Names of the markers
    marker_data.data = c3d.data.points; % Trial trajectory measurements

    assert(marker_data.n_markers == size(marker_data.data, 2))
    assert(3 == size(marker_data.data, 1))
    if marker_data.n_markers ~= 191
        important_markers = string(cellfun(@(x) x{1}, reference_guide.values, 'UniformOutput', false));
        important_markers(contains(important_markers, "Virtual")) = [];
        if ~all(ismember(important_markers, marker_data.marker_names))
            missing_markers = important_markers(~ismember(important_markers, marker_data.marker_names));
            error("PROST:BadTrial", "Bad Trial: missing %s", join(missing_markers, ", "))
        end
    end

    % Get forceplate data
    forceplate_data.n_samples = size(fp(1).force, 2); % Number of samples in trial
    forceplate_data.n_forceplates = size(fp, 1); % Number of force plates
    % The force-plates were sampled at the same frequency as the EMG
    forceplate_data.freq = c3d.parameters.ANALOG.RATE.DATA; % Sampling frequency. Should be 1000 Hz
    assert(forceplate_data.freq == 1000)
    forceplate_data.time_vector = (0:forceplate_data.n_samples - 1) / forceplate_data.freq; % Time vector of trial
    forceplate_data.grf_unit = string(fp(1).unit_force); % GRF measurement units
    forceplate_data.cop_unit = string(fp(1).unit_position); % CoP measurement units
   
    % Trial forceplate measurements
    forceplate_data.plate(forceplate_data.n_forceplates) = struct("grf", [], "cop", []); % Preallocate
    for k = 1:forceplate_data.n_forceplates
        forceplate_data.plate(k).grf =  fp(k).force; % Copy each vector after filtering
        forceplate_data.plate(k).cop = fp(k).center_of_pressure; % Copy each vector after filtering
        assert(3 == size(forceplate_data.plate(k).grf, 1))
        assert(3 == size(forceplate_data.plate(k).cop, 1))
    end
    
    % Clean up force plate data and marker data
    [forceplate_data, marker_data] = clean_data(forceplate_data, marker_data);
    
    % Get event data
    assert(ismatrix(c3d.parameters.EVENT.TIMES.DATA));
    assert(all(c3d.parameters.EVENT.TIMES.DATA(1, :) == 0));
    start_time = c3d.parameters.TRIAL.ACTUAL_START_FIELD.DATA(1) ./ marker_data.freq;
    event_data.times = c3d.parameters.EVENT.TIMES.DATA(2, :) - start_time;
    event_data.names = string(c3d.parameters.EVENT.LABELS.DATA)';
    event_data.feet = string(c3d.parameters.EVENT.CONTEXTS.DATA)';

    % Sort events by timeline
    [~, idx] = sort(event_data.times);
    event_data.times = event_data.times(idx);
    event_data.names = event_data.names(idx);
    event_data.feet = event_data.feet(idx);
end

function steps_info = save_steps_info(event_data, forceplate_data, marker_data, n_steps, good_forceplates, good_segments)
%GET_STEPS_INFO saves the step information of all steps in a single trial to our 
% preferred structure format for easier access later.
% Input :
%   event_data - information of events during the trial (foot strikes and foot
%                offs).
%   forceplate_data - force plate measurements.
%   marker_data - marker trajectory measurements. 
%   n_steps - number of steps in the trial.
%   good_forceplates - list of force plates where a single good step was
%                      measured.
%   good_segments - the corresponding foot of each good step.
% Output :
%   steps_info - a struct array with the step information of each step. Includes
%                event (IC, OIC, TO) times and indices in the force plate time
%                vector and trajectory time vector, the foot, the plate and step 
%                quality ("good" or "bad").
    
    % By what frequency to round?
    round_by = max(forceplate_data.freq, marker_data.freq);
    
    % Indices of events in events vectors for first steps.
    ICindices = find(strcmpi(event_data.names, "Foot Strike"));
    OICindices = [ICindices(2:end) ICindices(end)];
    TOindices = find(strcmpi(event_data.names, "Foot Off"));

    % To find TO indices that match IC indices, we need to find the first TO
    % index. This is the first Foot Off index that matches the first IC foot
    % who's time is larger than the first IC.
    first_TO_condition = strcmp(event_data.feet(TOindices), event_data.feet(ICindices(1))) & ...
                         event_data.times(TOindices) > event_data.times(ICindices(1));
    i_first_TO = find(first_TO_condition, 1, "first");
    TOindices = [TOindices(i_first_TO:end) TOindices(end) TOindices(end)];
    
    % Initialize steps info parameters
    steps_info(n_steps) = struct("events", [], "step_quality", [], "plate", [], "foot", []);
    event_struct = struct("time", NaN, "forceplate_index", NaN, "trajectory_index", NaN);
    [steps_info.step_quality] = deal("bad");
    [steps_info.plate] = deal(NaN);
    [steps_info.foot] = deal("bad");
    for step_number=1:n_steps
        steps_info(step_number).events.IC = event_struct;
        steps_info(step_number).events.OIC = event_struct;
        steps_info(step_number).events.TO = event_struct;
    end
    feet = strings(n_steps, 1);

    % Identify activation of the force plate
    fp_times = get_forceplate_times(forceplate_data);
    [~, fp_order] = sort(fp_times(:, 1), MissingPlacement="last");
    
    % Match events to step
    step_IC_times = 0.*(1:n_steps);
    for step_number=1:n_steps
        activation_time = fp_times(fp_order(step_number), 1);
        [~, event_idx] = min(abs(activation_time - event_data.times(ICindices)));

        % Set step feet
        feet(step_number) = lower(event_data.feet(ICindices(event_idx)));

        % Initial contact
        steps_info(step_number).events.IC.time = event_data.times(ICindices(event_idx));
        steps_info(step_number).events.IC.time = round(round_by*(steps_info(step_number).events.IC.time))/round_by;
        [~, steps_info(step_number).events.IC.forceplate_index] = min(abs(steps_info(step_number).events.IC.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.IC.trajectory_index] = min(abs(steps_info(step_number).events.IC.time - marker_data.time_vector));
        step_IC_times(step_number) = steps_info(step_number).events.IC.time;

        % Opposite initial contact
        steps_info(step_number).events.OIC.time = event_data.times(OICindices(event_idx));
        steps_info(step_number).events.OIC.time = round(round_by*(steps_info(step_number).events.OIC.time))/round_by;
        [~, steps_info(step_number).events.OIC.forceplate_index] = min(abs(steps_info(step_number).events.OIC.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.OIC.trajectory_index] = min(abs(steps_info(step_number).events.OIC.time - marker_data.time_vector));

        % Toe off
        steps_info(step_number).events.TO.time = event_data.times(TOindices(event_idx));
        steps_info(step_number).events.TO.time = round(round_by*(steps_info(step_number).events.TO.time))/round_by;
        [~, steps_info(step_number).events.TO.forceplate_index] = min(abs(steps_info(step_number).events.TO.time - forceplate_data.time_vector));
        [~, steps_info(step_number).events.TO.trajectory_index] = min(abs(steps_info(step_number).events.TO.time - marker_data.time_vector));
    end

    % Check good forceplates
    for idx=1:length(good_forceplates)
        good_fp_num = good_forceplates(idx);
        good_segment = good_segments(idx);
        [~, step_number] = min(abs(fp_times(good_fp_num, 1) - step_IC_times));
        steps_info(step_number).plate = good_fp_num;
        steps_info(step_number).foot = feet(step_number);
        steps_info(step_number).step_quality = "good";
        assert((steps_info(step_number).foot == "right" && good_segment == "R") || ...
               (steps_info(step_number).foot == "left" && good_segment == "L"))
    end
end

% function steps_info = check_step(steps_info, forceplate_data, feet, good_forceplates, good_segments)
% %CHECK_STEP checks the quality of the step and updates the step information
% % accordingly. A "bad" step is one that either started or ended on a force
% % plate, had both feet on the plate or had the foot on both steps at the same
% % time.
% % Input :
% %   steps_info - the information of the steps. 
% %   forceplate_data - force plate measurements of all plates.
% %   feet - the foot of each step according to the data files.
% %   good_forceplates - list of force plates where a single good step was
% %                      measured.
% %   good_segments - the corresponding foot of each good step.
% % Output :
% %   steps_info - the information of each step updated with the step quality, the 
% %                relevant plate and foot (if "good").
% 
%     % Set default values of steps_info to "bad" steps
%     step_numbers = 1:numel(steps_info);
% 
%     % Get IC indices of all steps
%     events = [steps_info.events];
%     foot_strikes = [events.IC];
%     ICindices = [foot_strikes.forceplate_index];
% 
%     % Find force plate of each step for good steps
%     for idx=1:length(good_forceplates)
%         fp_num = good_forceplates(idx);
%         segment = good_segments(idx);
%         if strcmp(segment, "L")
%             side = "left";
%         else
%             side = "right";
%         end
% 
%         [~, iPeak] = max(forceplate_data.plate(fp_num).grf(3, :));
%         [~, iIC] = min(abs(iPeak - ICindices(strcmpi(feet, side)' & ICindices <= iPeak)));
% 
%         step_number = step_numbers(strcmpi(feet, side)' & ICindices <= iPeak);
%         step_number = step_number(iIC);
%         steps_info(step_number).plate = fp_num;
%         steps_info(step_number).step_quality = "good";
%         steps_info(step_number).foot = side;
%     end
% end

function [activation_time, deactivation_time, activation_index, deactivation_index] = get_plate_activation_deactivation(Fz, time, Fs, threshold)
%GET_PLATE_ACTIVATION_DEACTIVATION calculates the activation and deactivation 
% times and indices of a given force plate. These are the first and last times
% when normal ground reaction force is measured above a given threshold. 
% Input :
%   Fz - the GRF measurement data in the z direction of a single force plate.
%   time - the time vector of the force plate.
%   Fs - the sampling frequency of the force plate.
%   threshold - the threshold force measurement in [N] above which we identify
%               activation. Default: 0 [N].
% Output :
%   activation_time - the activation time of the force plate. Default: NaN.
%   deactivation_time - the deactivation time of the force plate. Default: NaN.
%   activation_index - the activation index of the force plate. Default: 0.
%   deactivation_index - the deactivation index of the force plate. Default: 0.

    if nargin < 4
        threshold = 0; % [N]
    end
    if nargin < 3 || isempty(Fs)
        Fs = 1./(time(2) - time(1));
    end
    Fz_filtered = filter_data(Fz, Fs);
    dFz = diff(Fz_filtered);
    dFz = [dFz dFz(end)];

    activation_index = find(Fz_filtered > threshold & ~isnan(Fz), 1, 'first');
    deactivation_index = find(Fz_filtered > threshold & ~isnan(Fz), 1, 'last');

    if isempty(activation_index) || activation_index == 1
        [~, activation_index] = max(dFz, [], 'omitmissing');
        if activation_index == 1
            activation_index = 0;
            activation_time = NaN;
        else
            activation_time = time(activation_index);
        end
    else
        activation_time = time(activation_index);
    end
    if isempty(deactivation_index) || deactivation_index == length(Fz)
        [~, deactivation_index] = min(dFz, [], 'omitmissing');
        if deactivation_index == 1
            deactivation_index = 0;
            deactivation_time = NaN;
        else
            deactivation_time = time(deactivation_index);
        end
    else
        deactivation_time = time(deactivation_index);
    end
end

function fp_times = get_forceplate_times(forceplate_data)
%GET_FORCEPLATE_TIMES calculates the activation and deactivation times of all
% force plates.
% Input :
%   forceplate_data - measurement data of all force plates.
% Output :
%   fp_times - a nx2 array with the activation (column 1) and deactivation
%              (column 2) times of each force plate. n is the number of force 
%              plates.

    fp_times = zeros(forceplate_data.n_forceplates, 2);
    for fp_num=1:forceplate_data.n_forceplates
        [activation_time, deactivation_time] = get_plate_activation_deactivation( ...
            forceplate_data.plate(fp_num).grf(3, :), ...
            forceplate_data.time_vector, ...
            forceplate_data.freq, ...
            20);
        fp_times(fp_num, 1) = activation_time;
        fp_times(fp_num, 2) = deactivation_time;
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
            COP = forceplate_data.plate(fp_num).cop;

            % get the IC, OIC and TO of this step
            IC_index = steps_info(step_num).events.IC.forceplate_index;
            OIC_index = steps_info(step_num).events.OIC.forceplate_index;
            TO_index = steps_info(step_num).events.TO.forceplate_index;
            
            % Fixing IC Index
            % cut the GRF and COP according to the IC and OIC
            cut_GRF.x = GRF(1, IC_index:OIC_index);
            cut_GRF.y = GRF(2, IC_index:OIC_index);
            cut_GRF.z = GRF(3, IC_index:OIC_index);
            cut_COP.x = COP(1, IC_index:OIC_index);
            cut_COP.y = COP(2, IC_index:OIC_index);
            cut_COP.z = COP(3, IC_index:OIC_index);

            % Find data that is in IC:OIC that is not an outlier and has no
            % "inactive" constant value (0 for GRF).
            % is_in = (~isoutlier(cut_GRF.x)) & (~isoutlier(cut_GRF.y)) & (~isoutlier(cut_GRF.z)) & (cut_GRF.z > 0);
            threshold = 20;
            is_in = (cut_GRF.z > threshold & ~isnan(cut_COP.x) & ~isnan(cut_COP.y) & ~isnan(cut_COP.z));
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
                error("PROST:NonIntegerIndex", "IC index not an integer.\n" + ...
                    "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.IC.forceplate_index, steps_info(step_num).events.IC.trajectory_index)
            end
            
            % Fixing TO Index
            % cut the GRF according to the OIC and TO
            cut_GRF.x = GRF(1, OIC_index:TO_index);
            cut_GRF.y = GRF(2, OIC_index:TO_index);
            cut_GRF.z = GRF(3, OIC_index:TO_index);
            cut_COP.x = COP(1, OIC_index:TO_index);
            cut_COP.y = COP(2, OIC_index:TO_index);
            cut_COP.z = COP(3, OIC_index:TO_index);
            
            % Find data that is in OIC:TO that is not an outlier and has no
            % "inactive" constant value (0 for GRF).
            threshold = 20;          
            is_in = (cut_GRF.z > threshold & ~isnan(cut_COP.x) & ~isnan(cut_COP.y) & ~isnan(cut_COP.z));
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
                error("PROST:NonIntegerIndex", "TO index not an integer.\n" + ...
                      "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.TO.forceplate_index, steps_info(step_num).events.TO.trajectory_index)
            end
        end
    end
end

function trajectories = save_marker_data(marker_data)
%SAVE_MARKER_DATA saves the measurement data of a single trial from the markers 
% to our preferred structure format for easier access later. Also saves virtual 
% knee trajectories from the given markers.
% Input :
%   marker_data - the measurement data from the markers that we saved from the 
%                 data files.
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
        if strcmp(events.names(idx), "Foot Strike")
            foot = events.feet(idx);
            time = events.times(idx);
            strike_times.(foot) = [strike_times.(foot) time];
        end
    end

    % Calculate speed
    sides = string(fields(strike_times));
    n_sides = length(sides);
    n_strilkes = numel(strike_times.(sides(1))) - 1;
    if 2 == n_sides
        n_strilkes = n_strilkes + numel(strike_times.(sides(2))) -1;
    end
    speed = nan(1, n_strilkes);
    speed_idx = 0;
    for side_num=1:n_sides     
        % Get strike times and indices of the side
        strikes = strike_times.(sides(side_num));
        if length(strikes) < 2
            continue
        end
        for i=1:length(strikes)-1
            speed_idx = speed_idx + 1;

            time_start = strikes(i);
            time_end = strikes(i + 1);
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
            speed(speed_idx) = distance / duration; % [m/sec]
        end
    end
    speed = mean(speed, 'omitnan');
end

function interpolated_COP = interpolate_COP(COP, step_info, walking_direction, n_temporal_alignment)
%INTERPOLATE_COP converts the center of pressure (COP) measurements to our 
% coordinate system and interpolates into n_temporal_alignment points of the 
% weight acceptance + single support phase (from initial contact to opposite 
% initial contact).
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
    % interpolated_COP.z = COP.("plate_" + fp_num).z;

    % % cut the COP from IC to OIC filter it and temporally align to 101 points
    interpolated_COP.x = interp1(IC_index:OIC_index, interpolated_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_COP.y = interp1(IC_index:OIC_index, interpolated_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_COP.z = zeros(size(interpolated_COP.x));
    % interpolated_COP.z = interp1(IC_index:OIC_index, interpolated_COP.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

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
    interpolated_Markers.Ankle.medial = [];

        % For the knee:
    interpolated_Markers.Knee.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).x;
    interpolated_Markers.Knee.lateral.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).y;
    interpolated_Markers.Knee.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).z;
    interpolated_Markers.Knee.medial = [];

        % Cut the ankle markers data from IC to OIC and temporally align it to 101 points :
    interpolated_Markers.Ankle.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Ankle.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    
    % We don't have medial markers so the mean equals the lateral
    interpolated_Markers.Ankle.mean = interpolated_Markers.Ankle.lateral;

    if any(isnan(interpolated_Markers.Ankle.lateral.x) | ...
            isnan(interpolated_Markers.Ankle.lateral.y) | ...
            isnan(interpolated_Markers.Ankle.lateral.z))
        error("PROST:ContainsNaNs", "Ankle marker contains NaNs.")
    end

    % Cut the knee markers data from IC to OIC and temporally align it to 101 points :
    interpolated_Markers.Knee.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
    interpolated_Markers.Knee.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
   
    % Calculate mean knee marker from medial and lateral
    interpolated_Markers.Knee.mean = interpolated_Markers.Knee.lateral;

    if any(isnan(interpolated_Markers.Knee.lateral.x) | ...
           isnan(interpolated_Markers.Knee.lateral.y) | ...
           isnan(interpolated_Markers.Knee.lateral.z))
        error("PROST:ContainsNaNs", "Knee marker contains NaNs.")
    end

    interpolated_Markers.unit = "mm";
    interpolated_Markers.temporal_alignment = "Initial contact to opposite initial contact.";
end

function good_trials = read_good_trials_table(data_path)
%READ_GOOD_TRIALS_TABLE Returns a list of the file names of good trials. Good 
% trials are defined as trials that exist in the dataset and include all the 
% important markers needed for our dataset with steps completely on a single 
% force plate.
% Input : 
%   data_path - the path to the data files.
%   reference_guide - the reference guide for all the important markers in the 
%                     dataset.
% Output :
%   good_trials - an nx3 array with the participant IDs, speed condition and
%                 trial number of good trials.
% Note : the virtual markers for the knees in the markers guide are are not
%        needed and screened out.
    
    good_trials_path = fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx");
    opts = detectImportOptions(good_trials_path, "Sheet", "Table 3", "ReadVariableNames", false);
    Tgood = readtable(good_trials_path, opts);
    
    unsorted_good_trials = struct([]);
    subjCounter = 0;
    
    % Column definitions
    subjCols = [1 7]; % Columns with subject ID
    fpCols   = {[3 4 6], [9 10 12]}; % FP blocks per subject (not including FP 3)
    fp_nums = [1 2 4]; % Valid force plate numbers

    for r = 1:height(Tgood)
        for s = 1:2   % two subjects per row
            rawID = string(Tgood{r, subjCols(s)});
            if ~startsWith(rawID, "SUBJ")
                continue
            end
    
            subjCounter = subjCounter + 1;
            numID = sscanf(rawID,"SUBJ %d");
    
            unsorted_good_trials(subjCounter).SubjNum = numID;
            unsorted_good_trials(subjCounter).SubjID = sprintf("SUBJ%02d", numID);
            unsorted_good_trials(subjCounter).standing_trial.file_name = sprintf("SUBJ%d (0)", numID);
            unsorted_good_trials(subjCounter).standing_trial.trial_num = 0;

            trialMap = configureDictionary("double", "struct");
    
            % Parse FP columns
            for f = 1:numel(fpCols{s})
                fp = fp_nums(f);
                col = fpCols{s}(f);
                cellTxt = string(Tgood{r, col});
    
                if cellTxt == "X" || ismissing(cellTxt)
                    continue
                end
    
                entries = splitlines(cellTxt);
                tok = regexp(entries, '([RL])\s*\((\d+)\)','tokens','once', 'forcecelloutput');
    
                for e = 1:numel(entries)
                    if isempty(tok{e})
                        continue
                    end
    
                    seg = tok{e}(1);
                    trial = str2double(tok{e}(2));
    
                    if ~isKey(trialMap, trial)
                        trialMap(trial) = struct( ...
                            'forceplates', [], ...
                            'segments', string.empty);
                    end
    
                    tmp = trialMap(trial);
                    tmp.forceplates(end+1) = fp;
                    tmp.segments(end+1) = seg;
                    trialMap(trial) = tmp;
                end
            end
    
            % Build filenames + trials
            trialNums = sort((keys(trialMap)));
    
            for iTrial = 1:numel(trialNums)
                tr = trialNums(iTrial);
    
                unsorted_good_trials(subjCounter).trials(iTrial).file_name = ...
                    sprintf("SUBJ%d (%d)", numID, tr);
    
                unsorted_good_trials(subjCounter).trials(iTrial).trial_num = tr;
    
                unsorted_good_trials(subjCounter).trials(iTrial).forceplates = ...
                    trialMap(tr).forceplates;

                unsorted_good_trials(subjCounter).trials(iTrial).segments = ...
                    trialMap(tr).segments;
            end
        end
    end
    [~, order] = sort([unsorted_good_trials.SubjNum]);
    good_trials = unsorted_good_trials(order);

    % Manual corrections to good trials list due to record mistakes
    good_trials([good_trials.SubjNum] == 9).trials([good_trials([good_trials.SubjNum] == 9).trials.trial_num] == 3).segments = "L"; % Wrong Segments
    good_trials([good_trials.SubjNum] == 10).trials([good_trials([good_trials.SubjNum] == 10).trials.trial_num] == 2) = []; % Bad trial
    good_trials([good_trials.SubjNum] == 19).trials([good_trials([good_trials.SubjNum] == 19).trials.trial_num] == 3).segments = "L"; % Wrong Segments
    good_trials([good_trials.SubjNum] == 20).trials([good_trials([good_trials.SubjNum] == 20).trials.trial_num] == 3).segments = ["L" "R" "L"]; % Wrong Segments
    good_trials([good_trials.SubjNum] == 37) = []; % Missing markers in standing trial
    good_trials([good_trials.SubjNum] == 44).trials([good_trials([good_trials.SubjNum] == 44).trials.trial_num] == 5) = []; % Bad trial
    good_trials([good_trials.SubjNum] == 63).trials([good_trials([good_trials.SubjNum] == 63).trials.trial_num] == 2) = []; % Bad trial
    good_trials([good_trials.SubjNum] == 66).trials([good_trials([good_trials.SubjNum] == 66).trials.trial_num] == 1) = []; % Bad trial
    good_trials([good_trials.SubjNum] == 79).trials([good_trials([good_trials.SubjNum] == 79).trials.trial_num] == 2) = []; % Bad trial
    good_trials([good_trials.SubjNum] == 84).trials([good_trials([good_trials.SubjNum] == 84).trials.trial_num] == 1).segments = ["R" "L" "R"]; % Wrong Segments
    good_trials([good_trials.SubjNum] == 84).trials([good_trials([good_trials.SubjNum] == 84).trials.trial_num] == 4).segments = ["R" "L" "R"]; % Wrong Segments
    good_trials([good_trials.SubjNum] == 95).trials([good_trials([good_trials.SubjNum] == 95).trials.trial_num] == 3).segments = ["R" "L" "R"]; % Wrong Segments
    good_trials([good_trials.SubjNum] == 100) = [];  % Missing markers in standing trial
    good_trials([good_trials.SubjNum] == 108).trials([good_trials([good_trials.SubjNum] == 108).trials.trial_num] == 2).forceplates = [1, 2]; % Wrong Force plates
    good_trials([good_trials.SubjNum] == 108).trials([good_trials([good_trials.SubjNum] == 108).trials.trial_num] == 2).segments = ["L" "R"]; % Wrong Segments
    good_trials([good_trials.SubjNum] == 136).trials([good_trials([good_trials.SubjNum] == 136).trials.trial_num] == 2).segments = ["R" "L"]; % Wrong Segments
end

function metadata = read_metadata_table(data_path)
    % Get given data
    metadata_path = fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx");
    opts = detectImportOptions(metadata_path, "Sheet", "Table 1", "ReadVariableNames", false);
    Tmetadata = readtable(metadata_path, opts);
    unsorted_metadata = struct([]);
    subjCounter = 0;

    % Column definitions
    subjCols = [1 7];
    ageCols = [2 8];
    genderCols = [3 9];
    massCols = [4 10];
    heightCols = [5 11];

    for r = 1:height(Tmetadata)
        for s = 1:2 % two subjects per row
            rawID = string(Tmetadata{r, subjCols(s)});
            if ~startsWith(rawID, "SUBJ")
                continue
            end

            subjCounter = subjCounter + 1;
            numID = sscanf(rawID,"SUBJ%d");

            unsorted_metadata(subjCounter).SubjNum = numID;
            unsorted_metadata(subjCounter).SubjID = sprintf("SUBJ%02d", numID);
            unsorted_metadata(subjCounter).Age.value = Tmetadata{r, ageCols(s)};
            unsorted_metadata(subjCounter).Age.unit = "year";
            unsorted_metadata(subjCounter).Gender.value = Tmetadata{r, genderCols(s)};
            unsorted_metadata(subjCounter).Gender.unit = "M\F";
            unsorted_metadata(subjCounter).Mass.value = Tmetadata{r, massCols(s)};
            unsorted_metadata(subjCounter).Mass.unit = "kg";
            unsorted_metadata(subjCounter).Height.value = Tmetadata{r, heightCols(s)};
            unsorted_metadata(subjCounter).Height.unit = "mm";
        end
    end

    [~, order] = sort([unsorted_metadata.SubjID]);
    metadata = unsorted_metadata(order);
end

function data_filtered = filter_data(data, Fs, order, Fc)
%FILTER_DATA filters the data using a 4th order reverse Butterworth filter with 
% 10 Hz cutoff frequency (the same as used in Van Criekinge et. al.).
% Input : 
%   data - the data to filter.
%   Fs - sampling frequency (Hz) for creating the Butterworth filter. 
%        Default: 1000 Hz.
% Output :
%   data_filtered - the filtered data.

    % Filter parameters
    if nargin < 4 || isempty(Fc)
        Fc = 10;            % Low-pass cutoff frequency (Hz)
    end
    if nargin < 3 || isempty(order)
        order = 4;          % Filter order
    end
    if nargin < 2 || isempty(Fs)
        Fs = 1000;
    end


    % Normalize cutoff frequency
    Wn = Fc / (Fs/2);

    % Design Butterworth filter
    [b, a] = butter(order, Wn, 'low');

    % Apply zero-phase (forward-backward) filtering
    is_transposed = false;
    if size(data, 1) < order*3
        data = data';
        is_transposed = true;
    end
    data_filtered = filtfilt(b, a, data);
    if is_transposed
        data_filtered = data_filtered';
    end
end

function data_offseted = offset_data(data, start_index, end_index)
%OFFSET_DATA offsets the data to 0 (no signal) from offset.
% Input : 
%   data - the data to pre-process
%   start_index, end_index - the start and end indices for the signal. We ignore
%                            this part of the data since we want to calibrate
%                            to 0.

    calibration_data = [data(:, 1:start_index) data(:, end_index:end)];
    [~, dim] = max(size(calibration_data));
    assert(dim == 2);
    zero_offset = mean(calibration_data, dim, 'omitnan');
    data_offseted = data - zero_offset;
end

function filtered_event_data = filter_events_by_forceplate_activation(forceplate_data, event_data)
    fp_times = get_forceplate_times(forceplate_data);
    fp_times(3, :) = [];

    first_activation_time = min(fp_times(:, 1));
    last_deactivation_time = max(fp_times(:, 2));

    start_cut = find(event_data.times <= first_activation_time & strcmp(event_data.names, "Foot Strike"), 1, "last");
    if isempty(start_cut)
        start_cut = 1;
    end
    end_cut = find(event_data.times >= last_deactivation_time & strcmp(event_data.names, "Foot Off"), 1, "first");
    if isempty(end_cut)
        end_cut = numel(event_data.times);
    end

    filtered_event_data.times = event_data.times(start_cut:end_cut);
    filtered_event_data.names = event_data.names(start_cut:end_cut);
    filtered_event_data.feet = event_data.feet(start_cut:end_cut);
end

function [clean_forceplate_data, clean_marker_data] = clean_data(forceplate_data, marker_data)
    clean_forceplate_data = forceplate_data;
    clean_marker_data = marker_data;
    filter_order = 4;

    % Clean force plate 3 data. Since we are not using it we don't want to save
    % any signal from it.
    clean_forceplate_data.plate(3).grf = 0.*clean_forceplate_data.plate(3).grf;
    clean_forceplate_data.plate(3).cop = NaN.*clean_forceplate_data.plate(3).cop;

    time_vector = clean_forceplate_data.time_vector;
    sampling_freq = clean_forceplate_data.freq;
    signal_threshold = 20; % [N]
    for fp_num=[1 2 4]
        % clean_forceplate_data.plate(fp_num).grf = filter_data(clean_forceplate_data.plate(fp_num).grf, sampling_freq, filter_order);
        Fz = clean_forceplate_data.plate(fp_num).grf(3, :);
        [~, ~, signal_start_index, signal_end_index] = get_plate_activation_deactivation(Fz, time_vector, sampling_freq, signal_threshold);
        clean_forceplate_data.plate(fp_num).grf = offset_data(clean_forceplate_data.plate(fp_num).grf, signal_start_index, signal_end_index); 
        clean_forceplate_data.plate(fp_num).cop(:, 1:signal_start_index-1) = NaN;
        clean_forceplate_data.plate(fp_num).cop(:, signal_end_index+1:end) = NaN;
        % for dim=1:3
        %     not_nan_idx = ~isnan(clean_forceplate_data.plate(fp_num).cop(dim, :));
        %     clean_forceplate_data.plate(fp_num).cop(dim, not_nan_idx) = filter_data(clean_forceplate_data.plate(fp_num).cop(dim, not_nan_idx), sampling_freq, filter_order);
        % end
    end
    % for marker_num=1:clean_marker_data.n_markers
    %     squeezed_marker_data = squeeze(clean_marker_data.data(:, marker_num, :));
    %     not_nan_idx = ~isnan(squeezed_marker_data);
    %     if sum(not_nan_idx) < 3*filter_order
    %         continue
    %     end
    %     clean_marker_data.data(:, marker_num, not_nan_idx) = filter_data(squeezed_marker_data(not_nan_idx), sampling_freq, filter_order);
    % end
end

% TODO: Check up on bad trials
% participant_95, 3 (SUBJ95 (3)): :Event side and segment side do not match!
% participant_108, 2 (SUBJ108 (2)): :Event side and segment side do not match!
% participant_119, 1 (SUBJ119 (1)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_119, 3 (SUBJ119 (3)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_123, 2 (SUBJ123 (2)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 4.
% participant_123, 3 (SUBJ123 (3)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 4.
% participant_124, 1 (SUBJ124 (1)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 4.
% participant_124, 2 (SUBJ124 (3)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 2.
% participant_124, 4 (SUBJ124 (5)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 2.
% participant_125, 1 (SUBJ125 (1)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_125, 3 (SUBJ125 (3)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 4.
% participant_127, 2 (SUBJ127 (2)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 2.
% participant_131, 1 (SUBJ131 (1)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_133, 2 (SUBJ133 (2)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_133, 4 (SUBJ133 (4)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 4.
% participant_136, 1 (SUBJ136 (2)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 2.
% participant_136, 4 (SUBJ136 (5)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_137, 1 (SUBJ137 (1)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.
% participant_137, 3 (SUBJ137 (4)): MATLAB:badsubscript:Index exceeds the number of array elements. Index must not exceed 3.