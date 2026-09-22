%% ------------------------------------------------------------------
%  build a matlab structure containing the first dataset data
%  Created by Dani Feal
%  Edited by Chen Reichsbouscher, 11.06.2025
% -------------------------------------------------------------------
%
%  METADATA SOURCE CHANGE (17.09.2026) - anthropometrics now come from
%  "Data Files/anthropometric_data.csv" instead of the per-participant
%  "Data Files/Participant<N>/Metadata.txt" files.
%
%  Reason - a defect in the published source files:
%    Participant8, Participant9 and Participant10 shipped BYTE-IDENTICAL
%    Metadata.txt files, all three reading "ID: Subject8". Their Raw_Data.mat
%    files are distinct, so participants 9 and 10 had their own genuine gait
%    measurements bound to Subject8's anthropometrics. Nothing errored: the
%    parser read exactly what the files contained, so the only symptom was in
%    the statistics. This was found during the 09.2026 metadata-linkage audit
%    that followed the Dataset-4 sort bug, and is the same class of defect
%    (right measurements, wrong provided anthropometrics) arriving through the
%    data rather than through the code.
%
%  Why the CSV is now authoritative:
%    It carries distinct, plausible records for participants 9 and 10
%    (1.80 m / 83.7 kg / 26 y and 1.82 m / 76.8 kg / 25 y, against Subject8's
%    1.72 m / 75.8 kg / 23 y), so it RESOLVES the duplication rather than
%    working around it by excluding two participants. Verified against all 16
%    Metadata.txt files: 14 agree exactly on Age, Sex, Height, Mass, leg length
%    and foot length; the only differences are participants 9 and 10 above, and
%    participant 5's height (1.80 m in the text file, 1.79 m in the CSV). The
%    CSV was taken as authoritative for participant 5 too, so that one source
%    of truth governs the whole dataset.
%
%  Effect on results: Age/Height/Mass change for participants 5, 9 and 10
%    (6 of 467 IPD rows). Sex is unchanged for all participants. Leg, thigh and
%    shank lengths are unaffected because they are computed from each
%    participant's own markers, as are all ROS and arc responses. Dataset 1's
%    Age/Height/Mass mean+-SD DO change, because Subject8 is no longer counted
%    three times - the previously reported Dataset 1 demographics were wrong.
%
%  The Metadata.txt files are deliberately left in place for provenance; this
%  script no longer reads them. Guarded by
%  tests/test_Dataset1_metadata_linkage.m.
% -------------------------------------------------------------------

clearvars -except -regexp ^Dataset_(?!1$)\d+$
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
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

%% -----------------------------
%  General Database info:
% ------------------------------
%             -------------
% Dataset_1 / article_data :
%             -------------
Article_data.article_name = "Lower limb kinematic, kinetic, and EMG data from young healthy humans during walking at controlled speeds";
Article_data.authors = "Luís Moreira, Joana Figueiredo, Pedro Fonseca, João P. Vilas-Boas & Cristina P. Santos";
Article_data.link_to_paper = "https://doi.org/10.1038/s41597-021-00881-3";
Article_data.link_to_dataset = "https://doi.org/10.6084/m9.figshare.c.4923162.v1";
Article_data.published_year = 2021;

Dataset_1.Article_data = Article_data;

%             -------------
% Dataset_1 / marker_names :
%             -------------
Markers_guide.explanation_txt = "The field reference_guide containes a dictionary that maps our naming of important markers to the names and indices in the original dataset.\n" + ...
                                "The keys: our naming of important markers for cohesiveness between the different datasets.\n" + ...
                                "The values: a cell array with the names and indices of each marker in the original dataset.\n" + ...
                                "Columns 1, 2, 3: the name of the variable in the original trajectories dataset for the X, Y and Z coordinates.\n" + ...
                                "Columns 4, 5, 6: the number of the column in the original trajectories dataset for the X, Y and Z coordinates.\n" + ...
                                "-----------------------------------------------------------";

% Important markers reference guide
keys = ["Right Lateral Ankle"; ...
        "Right Medial Ankle"; ...
        "Right Lateral Knee"; ...
        "Right Medial Knee"; ...
        "Right ASIS"; ...
        "Right Walking Direction Marker"; ...
        "Left Lateral Ankle"; ...
        "Left Medial Ankle"; ...
        "Left Lateral Knee"; ...
        "Left Medial Knee"; ...
        "Left ASIS"; ...
        "Left Walking Direction Marker"];
values = {{"RLA", "RLAX", "RLAY", "RLAZ"}; ...
          {"RMA", "RMAX", "RMAY", "RMAZ"}; .....
          {"RLK", "RLKX", "RLKY", "RLKZ"}; ...
          {"RMK", "RMKX", "RMKY", "RMKZ"}; ...
          {"RASIS", "RASISX", "RASISY", "RASISZ"}; ...
          {"RPSIS", "RPSISX", "RPSISY", "RPSISZ"}; ...
          {"LLA", "LLAX", "LLAY", "LLAZ"}; ...
          {"LMA", "LMAX", "LMAY", "LMAZ"}; ...
          {"LLK", "LLKX", "LLKY", "LLKZ"}; ...
          {"LMK", "LMKX", "LMKY", "LMKZ"}; ...
          {"LASIS", "LASISX", "LASISY", "LASISZ"}; ...
          {"LPSIS", "LPSISX", "LPSISY", "LPSISZ"}};
Markers_guide.reference_guide = dictionary(keys, values);
Dataset_1.Markers_guide = Markers_guide;

%       --------------------
% Dataset_1 / Lab_system :
%       --------------------
Lab_system.lab_frame = ...
    "X Direction: \n" + ...
    "For CoP and marker trajectories: pointing in the direction that completes a right handed coordinate system.\n" + ...
    "for GRF data: the direction in the lab from the first forceplate to the last forceplate (walking direction).\n" + ...
    "Y Direction: \n" + ...
    "For CoP and marker trajectories: the direction in the lab from the first forceplate to the last forceplate (walking direction).\n" + ...
    "For GRF data: pointing in the direction that completes a right handed coordinate system.\n" + ...
    "Z Direction: \n" + ...
    "For GRF, CoP and marker trajectories the z direction is pointing up.";
Lab_system.num_forceplates = 6;

Dataset_1.Lab_system = Lab_system;

%             ---------------------
% Dataset_1 / Experiment_protocol :
%             ---------------------
% Explanation for how the experiment was conducted generally
Experiment_protocol.explanation_txt = ...
    "Relevant text taken from Moreira et al.:\n\n" + ...
    "The participants were asked to wear tight shorts and a standard type of tennis shoes that properly fits the user’s feet.\n\n" + ...
    "A standing static calibration trial was performed with the arms crossed in front of the chest, looking forward, and with the feet in a comfortable position, aligned with the shoulders.\n\n" + ...
    "All participants were instructed to perform ten rectilinear walking trials on a 10-meter flat surface with six embedded force platforms, at seven different speeds (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, and 4.0 km/h) controlled with a metronome.\n" + ...
    "The participants walked comfortably, looking ahead, and taking steps according to the sound of the metronome.\n\n" + ...
    "For coherency during the data collection, only trials in which the participants step on the first force platform with the right foot were admissible.\n" + ...
    "Additionally, every time that the participant performed two contacts in the same force platform, the trial was also rejected.\n" + ...
    "Each participant performed 10 valid walking trials at the controlled gait speed.\n\n" + ...
    "During a single trial, the right and left leg performed two and one strides, respectively, since the participants step the first force platform with the right foot.\n" + ...
    "Overall, 1120 trials were collected, containing 1120 and 2240 strides for the left and right leg, respectively.\n\n" + ...
    "Note: this dataset only uses the raw data that was aquired.";
Experiment_protocol.speed_categories = ["V1 is a speed of 1.0 km/hour.", ...
                                        "V15 is a speed of 1.5 km/hour.", ...
                                        "V2 is a speed of 2.0 km/hour.", ...
                                        "V25 is a speed of 2.5 km/hour.", ...
                                        "V3 is a speed of 3.0 km/hour.", ...
                                        "V35 is a speed of 3.5 km/hour.", ...
                                        "V4 is a speed of 4.0 km/hour."];
Experiment_protocol.num_participants = 16;
Experiment_protocol.num_trials = 0;
Experiment_protocol.num_steps = 0;
Experiment_protocol.num_markers = 24;

Dataset_1.Experiment_protocol = Experiment_protocol;

%% -----------------------------
%  participant specific info:
% ------------------------------
% Number of participants
n_participants = 16;

% load metadata (see the METADATA SOURCE CHANGE note at the top of this file)
all_metadata = read_metadata_table(data_path);
assert(numel(all_metadata) == n_participants, 'Dataset1:MetadataCountMismatch', ...
    "anthropometric_data.csv has %d records but there are %d participants.", ...
    numel(all_metadata), n_participants);

% Get relevant marker names in original dataset
markers_guide = Dataset_1.Markers_guide;
for participant_number=1:n_participants
    % Initialize counters
    trial_number = 0;
    left_steps_counter = 0;
    right_steps_counter = 0;

    % load data files:
    participant_ID = "Participant" + participant_number;
    participant_name = "participant_" + participant_number;
    participant_data = load(fullfile(data_path, participant_ID, "Raw_Data.mat"));
    participant_raw_data = participant_data.("Subject" + participant_number + "_raw");

    % Bind metadata by subject ID rather than by folder position.
    metadata_idx = find([all_metadata.SubjNum] == participant_number, 1);
    assert(~isempty(metadata_idx), 'Dataset1:MissingMetadata', ...
        "No metadata record for %s.", participant_ID);
    participant_metadata = all_metadata(metadata_idx);

    %                                    -------------------------------------
    % Dataset_1 / Data / participant_# / participant_ID_in_original_structure :
    %                                    -------------------------------------
    % the participant ID in the original data structure:
    Dataset_1.Data.(participant_name).participant_ID_in_original_structure = string(participant_ID);

    %                                    ---------
    % Dataset_1 / Data / participant_# / metadata :
    %                                    ---------
    metadata = read_participant_characteristics(participant_metadata, participant_raw_data, markers_guide);
    Dataset_1.Data.(participant_name).metadata = metadata;

    %                                                   ---------------------
    % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#)
    %                                                   ---------------------
    % Prepping uniform data
    Dataset_1.Data.(participant_name).uniform_data.right.step = [];
    Dataset_1.Data.(participant_name).uniform_data.left.step = [];

    % Get available speed categories
    available_speed_categories = get_available_speed_categories(participant_raw_data);

    %                                    -----------------
    % Dataset_1 / Data / participant_# / processed_original_data
    %                                    -----------------
    % Run of the available speeds for this participant:
    for speed_category=available_speed_categories
        % Get data
        COP_data = participant_raw_data.(speed_category).COP;
        marker_data = participant_raw_data.(speed_category).Trajectories;
        GRF_data = participant_raw_data.(speed_category).GRF;
        available_trials = length(COP_data);

        for available_trial_number=1:available_trials
            trial_number = trial_number + 1;
            
            % Read single trial data
            single_trial_COP_data = COP_data{available_trial_number, 2};
            single_trial_GRF_data = GRF_data{available_trial_number, 2};
            single_trial_marker_data = marker_data{available_trial_number, 2};

            % ------------------------------------------------------------------------------------
            %                            processed_original_data
            % ------------------------------------------------------------------------------------
            %                                                              -----------------
            % Dataset_1 / Data / participant_# / processed_original_data / trial(#) / origin
            %                                                              -----------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).origin.speed_category = speed_category;
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).origin.trial_number = available_trial_number;
            %                                                              -----------------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / walking_direction
            %                                                              -----------------------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).walking_direction = "+y in CoP and tragectories data. +x in GRF data";

            %                                                              ----------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / first_foot
            %                                                              ----------------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).first_foot = "right";

            %                                                              ---------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / GRF
            %                                                              ---------------
            n_forceplates = Dataset_1.Lab_system.num_forceplates;
            GRF = save_grf_data(single_trial_GRF_data, n_forceplates);
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).GRF = GRF;

            %                                                              ---------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / COP
            %                                                              ---------------
            COP = save_cop_data(single_trial_COP_data, GRF);
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).COP = COP;

            %                                                              -----------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / step_x_info
            %                                                              --------------- -------           
            % Keep in mind force plates 1 and 6 are (almost) always empty so 
            % data is largely noise so we only save forceplates 2, 3, 4 ,5.
            n_steps = 4;
            relevant_forceplates = [2 3 4 5];
            steps_info = save_step_data(COP, n_steps, relevant_forceplates);
            for step_number = 1:n_steps
                Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).("step_" + step_number + "_info") = ...
                    steps_info(step_number);
            end

            %                                                              ------------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / trajectories
            %                                                              ------------------------
            trajectories = save_marker_data(single_trial_marker_data);
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).trajectories = trajectories;

            %                                                              ----------------
            % Dataset_1 / Data / participant_# / processed_original_data / trial(#) / speed
            %                                                              ----------------
            speed = calculate_speed(single_trial_marker_data, steps_info, markers_guide);
            speed_km_per_hr = PROST.utils.convert_units(PROST.utils.convert_units(speed, "m", "km"), "hour", "second");
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).speed.value = speed_km_per_hr;
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).speed.unit = "km/hour";
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).speed.method = ...
                "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
                "Then calculated the mean speed of both feet.\n" + ...
                "Converted from [m/sec] to [km/hr]";
            Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).speed.speed_category = speed_category;

            % -----------------------------------------------------------------------------------
            %                            uniform_data
            % -----------------------------------------------------------------------------------
            %                              ---------------- --------------- --------
            % Dataset_1 / Data / participant_# / uniform_data / right or left / step(#)
            %                              ---------------- --------------- --------
            % reminder:
            % the frame of reference of the given (original) markers and CoP:
            % x - right direction
            % y - walking direction
            % z - up
            % the frame of reference of the given (original) GRF:
            % x - walking direction
            % y - the medial direction?
            % z - up
            % ---------------------------------------------
            % in uniform data, the markers and CoP data should be transformed so that:
            % x - walking direction
            % y - to the left (of the body)
            % z - up
            % ---------------------------------------------
            % so: (for markers and CoP)
            % summery of needed transformation:
            % ---------------------------------
            % new_x =  old_y
            % new_y = - old_x
            % new_z =  old_z

            % also we are normalizing each step to only 101 points
            % summery of temporal alignment:
            % -------------------------
            % the GRF should be temporally aligned (to 101 points) in the stance phase (SP) -> from initial contact to toe off
            % while the CoP and markers should be temporally aligned (to 101 points) in the weight acceptance + single support phase (SS) -> from initial contact to opposite initial contact

            % Saving data of 3 steps
            % We have the data of 4 steps per trial but since OIC isn't known,
            % we use the IC time of the subsequent step.
            for step_number=1:(n_steps - 1)
                % Skip bad steps
                if steps_info(step_number).step_quality == "bad"
                    continue
                end

                % Get forceplate number
                fp_number = steps_info(step_number).plate;
                
                % Get foot
                foot = steps_info(step_number).foot;

                if steps_info(step_number).foot == "left"
                    left_steps_counter = left_steps_counter + 1;
                    relevant_index = left_steps_counter;
                    foot_capitalized = PROST.utils.capitalize(foot);
                else
                    right_steps_counter = right_steps_counter + 1;
                    relevant_index = right_steps_counter;
                    foot_capitalized = PROST.utils.capitalize(foot);
                end
                

                % Get event indices and times
                IC_index = steps_info(step_number).events.IC.index;
                IC_time = steps_info(step_number).events.IC.time;
                TO_index = steps_info(step_number).events.TO.index;
                TO_time = steps_info(step_number).events.TO.time;
                OIC_index = steps_info(step_number).events.OIC.index;
                OIC_time = steps_info(step_number).events.OIC.time;

                %                                                                          -------
                % Dataset_1 / Data / participant_# / uniform_data / right,left / step(#) / source
                %                                                                          -------
                %                                                                               ---------------
                %                                                                              / original_trial
                %                                                                               ---------------
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_trial = speed_category + "_" + available_trial_number;
                %                                                                               ------------
                %                                                                              / step_number
                %                                                                               ------------
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.step_number = step_number;
                %                                                                               -------------
                %                                                                              / Plate_number
                %                                                                               -------------
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.plate_number = step_number + 1;

                % original IC,OIC,and TO: index and time
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_IC.forceplate_index = IC_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_OIC.forceplate_index = OIC_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_TO.forceplate_index = TO_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_IC.trajectory_index = IC_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_OIC.trajectory_index = OIC_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_TO.trajectory_index = TO_index;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_IC.time = IC_time;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_OIC.time = OIC_time;
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).source.original_TO.time = TO_time;
                % --------------------------------------------------------------

                % Size of temporal alignment. We want 101 points so data is in
                % percentage of stance phase \ single support phase.
                n_temporal_alignment = 101;

                %                                                                         ----------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / COP   -  temporally aligned
                %                                                                         ----------------------------

                % transform the original y to be x now (so x will be the walking direction)
                % and the original x to be the new -y (so the z direction will still point up)
                one_step_COP.x = PROST.utils.convert_units(COP.("plate_" + fp_number).y, COP.unit, "mm");
                one_step_COP.y = -PROST.utils.convert_units(COP.("plate_" + fp_number).x, COP.unit, "mm");
                % one_step_COP.z = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(step_number).z;

                % cut the CoP data from IC to OIC (weight acceptance + single support) and interpolate it to 101 points
                interpolated_COP.x = interp1(IC_index:OIC_index, one_step_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.y = interp1(IC_index:OIC_index, one_step_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.z = zeros(size(interpolated_COP.x));
                interpolated_COP.unit = "mm";
                interpolated_COP.temporal_alignment = "Initial contact to opposite initial contact.";

                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).COP = interpolated_COP;

                %                                                                          ----------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / GRF   -  temporally aligned
                %                                                                          ----------------------------

                % the original x axis stays as x as this is the walking direction
                one_step_GRF.x = GRF.(foot_capitalized).x;

                % the original z axis stays as z as this is the direction pointing up
                one_step_GRF.z = GRF.(foot_capitalized).z;

                % y on the other hand, was always pointing inwards in the original data.
                % in the other hand in order to comply with the right hand rule
                %                          Z * X = Y
                % and with the directions of the x axis and z axis
                % the y axis should be pointing to the left.
                % so for steps 1 and 3 (right foot), the GRF should stay the same
                % but for steps 2 and 4 (left foot), the direction of the GRF needs to be flipped.
                one_step_GRF.y = (-1)^(step_number + 1) .* GRF.(foot_capitalized).y;

                % cut the GRF data from IC to TO and interpolate it to 101 points :
                interpolated_GRF.x = interp1(IC_index:TO_index, one_step_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.y = interp1(IC_index:TO_index, one_step_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.z = interp1(IC_index:TO_index, one_step_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.unit = "N";
                interpolated_GRF.temporal_alignment = "Initial contact to toe off (stance phase).";
                
                % OIC event after temporal alignment
                interpolated_GRF.OIC.time = round((n_temporal_alignment - 1)*(OIC_index - IC_index)/(TO_index - IC_index));
                interpolated_GRF.OIC.index = interpolated_GRF.OIC.time + 1;

                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).GRF = interpolated_GRF;

                %                                                                          --------------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / Markers   -  temporally aligned
                %                                                                          --------------------------------
                % first we need to decide what markers interest us:
                % we will store the data of the medial and lateral ankle markers
                %                    and of the medial and lateral knee markers
                % and the mean between the medial and lateral markers (for the center of the ankle and the knee)
                % get the markers data
                
                % For the ankle
                one_step_Markers.Ankle.lateral.x = trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Ankle"}{1}).y;
                one_step_Markers.Ankle.lateral.y = -trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Ankle"}{1}).x;
                one_step_Markers.Ankle.lateral.z = trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Ankle"}{1}).z;
                one_step_Markers.Ankle.medial.x = trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Ankle"}{1}).y;
                one_step_Markers.Ankle.medial.y = -trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Ankle"}{1}).x;
                one_step_Markers.Ankle.medial.z = trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Ankle"}{1}).z;

                % For the knee
                one_step_Markers.Knee.lateral.x = trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Knee"}{1}).y;
                one_step_Markers.Knee.lateral.y = -trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Knee"}{1}).x;
                one_step_Markers.Knee.lateral.z = trajectories.(markers_guide.reference_guide{foot_capitalized + " Lateral Knee"}{1}).z;
                one_step_Markers.Knee.medial.x = trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Knee"}{1}).y;
                one_step_Markers.Knee.medial.y = -trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Knee"}{1}).x;
                one_step_Markers.Knee.medial.z = trajectories.(markers_guide.reference_guide{foot_capitalized + " Medial Knee"}{1}).z;

                % Cut the ankle markers data from IC to OIC and interpolate in to 101 points
                interpolated_Markers.Ankle.lateral.x = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Ankle.lateral.y = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Ankle.lateral.z = interp1(IC_index:OIC_index, one_step_Markers.Ankle.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Ankle.medial.x = interp1(IC_index:OIC_index, one_step_Markers.Ankle.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Ankle.medial.y = interp1(IC_index:OIC_index, one_step_Markers.Ankle.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Ankle.medial.z = interp1(IC_index:OIC_index, one_step_Markers.Ankle.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

                % Calculate virtual ankle marker from medial and lateral
                interpolated_Markers.Ankle.mean.x = (interpolated_Markers.Ankle.lateral.x + interpolated_Markers.Ankle.medial.x) / 2;
                interpolated_Markers.Ankle.mean.y = (interpolated_Markers.Ankle.lateral.y + interpolated_Markers.Ankle.medial.y) / 2;
                interpolated_Markers.Ankle.mean.z = (interpolated_Markers.Ankle.lateral.z + interpolated_Markers.Ankle.medial.z) / 2;

                % Cut the knee markers data from IC to OIC and interpolate in to 101 points
                interpolated_Markers.Knee.lateral.x = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Knee.lateral.y = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Knee.lateral.z = interp1(IC_index:OIC_index, one_step_Markers.Knee.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Knee.medial.x = interp1(IC_index:OIC_index, one_step_Markers.Knee.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Knee.medial.y = interp1(IC_index:OIC_index, one_step_Markers.Knee.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_Markers.Knee.medial.z = interp1(IC_index:OIC_index, one_step_Markers.Knee.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));

                % Calculate virtual knee marker from medial and lateral
                interpolated_Markers.Knee.mean.x = (interpolated_Markers.Knee.lateral.x + interpolated_Markers.Knee.medial.x) / 2;
                interpolated_Markers.Knee.mean.y = (interpolated_Markers.Knee.lateral.y + interpolated_Markers.Knee.medial.y) / 2;
                interpolated_Markers.Knee.mean.z = (interpolated_Markers.Knee.lateral.z + interpolated_Markers.Knee.medial.z) / 2;

                interpolated_Markers.unit = "mm";
                interpolated_Markers.temporal_alignment = "Initial contact to opposite initial contact.";
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).Markers = interpolated_Markers;

                %                                                                       ------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / speed
                %                                                                       ------
                Dataset_1.Data.(participant_name).uniform_data.(foot).step(relevant_index).speed = ...
                    Dataset_1.Data.(participant_name).processed_original_data.trial(trial_number).speed;
            end
        end
    end

    % Add up total number of trials
    Dataset_1.Experiment_protocol.num_trials = Dataset_1.Experiment_protocol.num_trials + trial_number;
end
Dataset_1.Experiment_protocol.num_steps = Dataset_1.Experiment_protocol.num_trials .* 3;

save("..\Dataset_1.mat","Dataset_1")


%% ----------------------------
%  Auxiliary Functions
% -----------------------------
function available_speed_categories = get_available_speed_categories(participant_raw_data)
%GET_AVAILABLE_SPEED_CATEGORIES returns the list of speed categories that are
% available and were measured for the participant.
% Input :
%   participant_raw_data - the raw data of trial measurements
% Output :
%   available_speed_categories - list of available speed categories.

    available_speed_categories = strings(1, 7);
    counter = 0;
    for speed_category=("V" + [1 15 2 25 3 35 4])
        if length(fieldnames(participant_raw_data.(speed_category))) > 1
            counter = counter + 1;
            available_speed_categories(counter) = speed_category;
        end
    end
    available_speed_categories = available_speed_categories(1:counter);
end

function [median_right_leg_length, ...
          median_left_leg_length, ...
          median_right_thigh_length, ...
          median_left_thigh_length, ...
          median_right_shank_length, ...
          median_left_shank_length] = get_lengths(participant_raw_data, markers_guide)
%GET_LENGTHS gives the lengths of the leg, thigh and shank of each side by
% calculating the median distance between the relevant markers for all
% trials.
% Input:
%   participant_data - the raw data struct object of the participant.
%   markers_guide - the reference guide to the marker names.

    % get available speeds
    available_speed_categories = get_available_speed_categories(participant_raw_data);
    
    % run on all the available speeds:
    trials_counter = 0;
    right_leg_lengths_vector = zeros(1, length(available_speed_categories)*10);
    left_leg_lengths_vector = zeros(1, length(available_speed_categories)*10);
    right_thigh_lengths_vector = zeros(1, length(available_speed_categories)*10);
    left_thigh_lengths_vector = zeros(1, length(available_speed_categories)*10);
    right_shank_lengths_vector = zeros(1, length(available_speed_categories)*10);
    left_shank_lengths_vector = zeros(1, length(available_speed_categories)*10);
    for speed_category=available_speed_categories
        marker_data = participant_raw_data.(speed_category).Trajectories;
        available_num_trials = length(marker_data);
        for num_trial=1:available_num_trials
            trials_counter = trials_counter + 1;

            % get the data of this single trial:
            single_trial_marker_data = marker_data{num_trial, 2};

            % calculate the lengths:
            % left_ankle  -  left lateral ankle
            % left_knee   -  left lateral knee
            % left_asis   -  left ASIS
            % right_ankle -  right lateral ankle
            % right_knee  -  right lateral knee
            % right_asis  -  right ASIS
            right_asis = [single_trial_marker_data.(markers_guide.reference_guide{"Right ASIS"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right ASIS"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right ASIS"}{4})'];
            left_asis = [single_trial_marker_data.(markers_guide.reference_guide{"Left ASIS"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left ASIS"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left ASIS"}{4})'];
            right_ankle = [single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Ankle"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Ankle"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Ankle"}{4})'];
            left_ankle = [single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Ankle"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Ankle"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Ankle"}{4})'];
            right_knee = [single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Knee"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Knee"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Right Lateral Knee"}{4})'];
            left_knee = [single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Knee"}{2})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Knee"}{3})'; ...
                single_trial_marker_data.(markers_guide.reference_guide{"Left Lateral Knee"}{4})'];

            right_leg_length = vecnorm(right_asis - right_ankle);
            left_leg_length = vecnorm(left_asis - left_ankle);
            right_thigh_length = vecnorm(right_asis - right_knee);
            left_thigh_length = vecnorm(left_asis - left_knee);
            right_shank_length = vecnorm(right_knee - right_ankle);
            left_shank_length = vecnorm(left_knee - left_ankle);

            % save medians
            right_leg_lengths_vector(trials_counter) = median(right_leg_length);
            left_leg_lengths_vector(trials_counter) = median(left_leg_length);
            right_thigh_lengths_vector(trials_counter) = median(right_thigh_length);
            left_thigh_lengths_vector(trials_counter) = median(left_thigh_length);
            right_shank_lengths_vector(trials_counter) = median(right_shank_length);
            left_shank_lengths_vector(trials_counter) = median(left_shank_length);
        end
    end

    right_leg_lengths_vector = right_leg_lengths_vector(1:trials_counter);
    left_leg_lengths_vector = left_leg_lengths_vector(1:trials_counter);
    right_thigh_lengths_vector = right_thigh_lengths_vector(1:trials_counter);
    left_thigh_lengths_vector = left_thigh_lengths_vector(1:trials_counter);
    right_shank_lengths_vector = right_shank_lengths_vector(1:trials_counter);
    left_shank_lengths_vector = left_shank_lengths_vector(1:trials_counter);

    % calculate median of all trials
    median_right_leg_length = PROST.utils.convert_units(median(right_leg_lengths_vector), "mm", "m");
    median_left_leg_length = PROST.utils.convert_units(median(left_leg_lengths_vector), "mm", "m");
    median_right_thigh_length = PROST.utils.convert_units(median(right_thigh_lengths_vector), "mm", "m");
    median_left_thigh_length = PROST.utils.convert_units(median(left_thigh_lengths_vector), "mm", "m");
    median_right_shank_length = PROST.utils.convert_units(median(right_shank_lengths_vector), "mm", "m");
    median_left_shank_length = PROST.utils.convert_units(median(left_shank_lengths_vector), "mm", "m");
end

function metadata = read_metadata_table(data_path)
%READ_METADATA_TABLE Read the Dataset-1 anthropometric table, keyed by ID.
% Columns are addressed BY NAME, so a reordered or extended file cannot
% silently shift a value - which was the failure mode of the fixed
% token-position parsing of Metadata.txt that this replaces. Note the CSV's
% column order is not the order of the old text files (Age is 5th here, 2nd
% there). See the METADATA SOURCE CHANGE note at the top of this file.
% Input :
%   data_path - the path to the data files.
% Output :
%   metadata - struct array of anthropometric records, one per participant,
%              carrying SubjNum for ID-based binding.

    metadata_path = fullfile(data_path, "anthropometric_data.csv");
    T = readtable(metadata_path, "VariableNamingRule", "preserve", "TextType", "string");

    required = ["ID", "Gender", "Body Height (m)", "Body Mass (kg)", "Age (years)"];
    absent = required(~ismember(required, string(T.Properties.VariableNames)));
    assert(isempty(absent), 'Dataset1:MissingMetadataColumn', ...
        "anthropometric_data.csv is missing column(s): %s.", strjoin(cellstr(absent), ", "));

    metadata = struct([]);
    for r = 1:height(T)
        metadata(r).SubjNum      = T.("ID")(r);
        metadata(r).Age.value    = T.("Age (years)")(r);
        metadata(r).Age.unit     = "years";
        metadata(r).Sex.value    = T.("Gender")(r);
        metadata(r).Sex.unit     = "Male/Female";
        metadata(r).Height.value = T.("Body Height (m)")(r);
        metadata(r).Height.unit  = "m";
        metadata(r).Mass.value   = T.("Body Mass (kg)")(r);
        metadata(r).Mass.unit    = "kg";
    end

    % The participant loop binds on SubjNum, so a duplicate would make the
    % match order-dependent and silently wrong.
    subj_nums = [metadata.SubjNum];
    assert(numel(unique(subj_nums)) == numel(subj_nums), 'Dataset1:DuplicateMetadataIDs', ...
        "Duplicate ID in anthropometric_data.csv.");
end

function metadata = read_participant_characteristics(participant_metadata, participant_raw_data, markers_guide)
%READ_PARTICIPANT_CHARACTERISTICS reads anthropometric data from the data files
% of the participant. Also gets the trial data and calculates missing data from
% it (leg length, shank length, thigh length) by computing medians of all trials.
% Input :
%   participant_metadata - one record from read_metadata_table, holding this
%                          participant's anthropometric data.
%   participant_raw_data - the participant's raw data of all trials for
%                          calculating missing data.
%   markers_guide - the reference guide for all the important markers.
% Output :
%   metadata - the anthropometric data of the participant.

    metadata.Age.value = participant_metadata.Age.value;
    metadata.Age.unit = "years";
    metadata.Age.method = "provided";

    % Sex
    sex_value = strtrim(string(participant_metadata.Sex.value));
    if strcmpi(sex_value, "Male") || strcmpi(sex_value, "M")
        metadata.Sex.value = "Male";
    elseif strcmpi(sex_value, "Female") || strcmpi(sex_value, "F")
        metadata.Sex.value = "Female";
    else
        error('Dataset1:UnrecognisedSex', ...
            "Unrecognised Gender '%s' in anthropometric_data.csv.", sex_value);
    end
    metadata.Sex.unit = "Male/Female";
    metadata.Sex.method = "provided";

    % Height
    metadata.Height.value = participant_metadata.Height.value;
    metadata.Height.unit = "m";
    metadata.Height.method = "provided";

    % Mass
    metadata.Mass.value = participant_metadata.Mass.value;
    metadata.Mass.unit = "kg";
    metadata.Mass.method = "provided";

    % Footwear condition
    metadata.Footwear_condition.value = "Shod";
    metadata.Footwear_condition.unit = "Shod/Barefoot";
    metadata.Footwear_condition.method = "provided";

    % Calculate leg length, thigh length and shank length
    [right_leg_length, left_leg_length, right_thigh_length, left_thigh_length, right_shank_length, left_shank_length] = get_lengths(participant_raw_data, markers_guide); % [m]

    % Leg length - distance between anterior superior iliac spine (ASIS) and lateral ankle (LA)
    metadata.Leg_length.right = right_leg_length; % [m]
    metadata.Leg_length.left = left_leg_length; % [m]
    metadata.Leg_length.unit = "m";
    metadata.Leg_length.method = "calculated by median distance between ASIS and lateral ankle markers.";

    % Thigh length - distance between lateral knee (LK) and anterior superior iliac spine (ASIS)
    metadata.Thigh_length.right = right_thigh_length; % [m]
    metadata.Thigh_length.left = left_thigh_length; % [m]
    metadata.Thigh_length.unit = "m";
    metadata.Thigh_length.method = "calculated by median distance between ASIS and lateral knee markers.";

    % Shank length - distance between lateral knee (LK) and lateral ankle (LA)
    metadata.Shank_length.right = right_shank_length; % [m]
    metadata.Shank_length.left = left_shank_length; % [m]
    metadata.Shank_length.unit = "m";
    metadata.Shank_length.method = "calculated by median distance between lateral knee and lateral ankle markers.";
end


function GRF = save_grf_data(single_trial_GRF_data, n_forceplates)
    GRF.Left.x = single_trial_GRF_data.L_GRF_X; % walking direction
    GRF.Left.y = single_trial_GRF_data.L_GRF_Y; % always points medially for some reason
    GRF.Left.z = single_trial_GRF_data.L_GRF_Z; % up
    GRF.Right.x = single_trial_GRF_data.R_GRF_X; % walking direction
    GRF.Right.y = single_trial_GRF_data.R_GRF_Y; % always points medially for some reason
    GRF.Right.z = single_trial_GRF_data.R_GRF_Z; % up
    GRF.sampling_freq.value = 200;
    GRF.sampling_freq.unit = "Hz";
    GRF.time_vector.value = single_trial_GRF_data.Time;
    GRF.time_vector.unit = "second";
    GRF.n_forceplates = n_forceplates;
    GRF.right_forceplates = [1 2 4];
    GRF.left_forceplates = [3 5 6];
    GRF.n_samples = length(single_trial_GRF_data.Time);
    GRF.unit = "N";
end

function COP = save_cop_data(single_trial_COP_data, GRF)
    [left_activation_index, left_deactivation_index] = find_forceplate_activation_deactivation(GRF.Left.z);
    [right_activation_index, right_deactivation_index] = find_forceplate_activation_deactivation(GRF.Right.z);
    for fp_num=1:GRF.n_forceplates
        % Get CoP data
        x_cop = single_trial_COP_data.("FP" + fp_num + "_X"); % [mm]
        y_cop = single_trial_COP_data.("FP" + fp_num + "_Y"); % [mm]
        z_cop = single_trial_COP_data.("FP" + fp_num + "_Z"); % [mm]

        % Process the CoP data to get rid of noisy points and save step
        % foot
        if ismember(fp_num, GRF.left_forceplates) % left foot
            non_active_idx = true(1, length(x_cop));
            if fp_num == GRF.left_forceplates(1)
                non_active_idx(left_activation_index(1):left_deactivation_index(1)) = false;
            else
                non_active_idx(left_activation_index(2):left_deactivation_index(2)) = false;
            end
            x_cop(non_active_idx) = nan;
            y_cop(non_active_idx) = nan;
            z_cop(non_active_idx) = nan;
        else % right foot ismember(fp_num, GRF.right_forceplates)
            non_active_idx = true(1, length(x_cop));
            if fp_num == GRF.right_forceplates(2)
                non_active_idx(right_activation_index(1):right_deactivation_index(1)) = false;
            else
                non_active_idx(right_activation_index(2):right_deactivation_index(2)) = false;
            end
            x_cop(non_active_idx) = nan;
            y_cop(non_active_idx) = nan;
            z_cop(non_active_idx) = nan;
        end
        getrid = isoutlier(x_cop) | isoutlier(y_cop);
        x_cop(getrid) = nan;
        y_cop(getrid) = nan;
        z_cop(getrid) = nan;


        % Save the CoP
        COP.("plate_" + fp_num).x = x_cop;
        COP.("plate_" + fp_num).y = y_cop;
        COP.("plate_" + fp_num).z = z_cop;
        COP.sampling_freq.value = 200;
        COP.sampling_freq.unit = "Hz";
        COP.time_vector.value = single_trial_COP_data.Time;
        COP.time_vector.unit = "second";
        COP.n_forceplates = 6;
        COP.right_forceplates = GRF.right_forceplates;
        COP.left_forceplates = GRF.left_forceplates;
        COP.n_samples = length(single_trial_COP_data.Time);
        COP.unit = "m";
    end
end

function [activation_index, deactivation_index] = find_forceplate_activation_deactivation(Fz)
    % Initialize activation deactivation indices
    activation_index = zeros(1, 2);
    deactivation_index = zeros(1, 2);
    
    % Clean up GRF data for noise
    start_idx = find(~isnan(Fz), 1, "first");
    end_idx = find(isnan(Fz(start_idx:end)), 1, "first") + start_idx - 2;
    while ~isempty(end_idx) && ~isempty(start_idx) && end_idx > start_idx
        if end_idx - start_idx + 1 < 100
            Fz(start_idx:end_idx) = nan;
        end
        start_idx = find(~isnan(Fz(end_idx+1:end)), 1, "first") + end_idx;
        end_idx = find(isnan(Fz(start_idx:end)), 1, "first") + start_idx - 2;
    end

    % Find activation and deactivation of first plate of the same foot
    start_idx = find(~isnan(Fz), 1, "first");
    end_idx = find(isnan(Fz(start_idx:end)), 1, "first") + start_idx - 2;
    
    if ~isempty(start_idx)
        activation_index(1) = start_idx;
    end
    if ~isempty(end_idx)
        deactivation_index(1) = end_idx;
    end

    % Find activation and deactivation of second plate of the same foot
    end_idx = find(~isnan(Fz), 1,"last");
    start_idx = find(isnan(Fz(1:end_idx)), 1, "last") + 1;
    if ~isempty(start_idx)
        activation_index(2) = start_idx;
    end
    if ~isempty(end_idx)
        deactivation_index(2) = end_idx;
    end
end

function steps_info = save_step_data(COP, n_steps, relevant_forceplates)
    % Keep in mind force plates 1 and 6 are (almost) always empty so
    % data is largely noise so we only save forceplates 2, 3, 4 ,5.
    % relevant_forceplates = [2 3 4 5];
    % steps_with_oic_event = [2 3 4];
    steps_info(n_steps) = struct;
    for step_number=1:n_steps
        % Initial step quality is assumed to be good
        steps_info(step_number).step_quality = "good";

        % Force plate
        fp_num = relevant_forceplates(step_number);
        steps_info(step_number).plate = fp_num;

        % Step foot
        if ismember(fp_num, COP.right_forceplates)
            steps_info(step_number).foot = "right";
        else
            steps_info(step_number).foot = "left";
        end

        % Get CoP data
        y_cop = COP.("plate_" + fp_num).y;

        % Find the event indices and times
        COP_first_event_time = nan;
        COP_first_event_index = find(~isnan(y_cop), 1, "first");
        if ~isempty(COP_first_event_index)
            COP_first_event_time = COP.time_vector.value(COP_first_event_index);
        else
            % Re-categorize as bad step if no measurement indices are
            % found
            COP_first_event_index = nan;
            steps_info(step_number).step_quality = "bad";
            steps_info(step_number).foot = "bad";
            steps_info(step_number).plate = NaN;
        end

        COP_last_event_time = nan;
        COP_last_event_index = find(~isnan(y_cop), 1, "last");
        if ~isempty(COP_last_event_index)
            COP_last_event_time = COP.time_vector.value(COP_last_event_index);
        else
            COP_last_event_index = nan;
            steps_info(step_number).step_quality = "bad";
            steps_info(step_number).foot = "bad";
            steps_info(step_number).plate = NaN;
        end

        % save IC
        steps_info(step_number).events.IC.index = COP_first_event_index;
        steps_info(step_number).events.IC.time = COP_first_event_time;

        % save OIC
        % First initialize current OIC event
        steps_info(step_number).events.OIC.index = nan;
        steps_info(step_number).events.OIC.time = nan;

        % Then save current IC event as OIC of previous step
        if step_number > 1
            steps_info(step_number - 1).events.OIC.index = steps_info(step_number).events.IC.index;
            steps_info(step_number - 1).events.OIC.time = steps_info(step_number).events.IC.time;
        end

        % save TO
        steps_info(step_number).events.TO.index = COP_last_event_index;
        steps_info(step_number).events.TO.time = COP_last_event_time; % [sec]
    end
end

function mean_speed = calculate_speed(single_trial_marker_data, steps_info, markers_guide)
    right_IC = [steps_info(1).events.IC steps_info(3).events.IC];
    left_IC = [steps_info(2).events.IC steps_info(4).events.IC];

    psis.x = (single_trial_marker_data.(markers_guide.reference_guide{"Right Walking Direction Marker"}{2}) + single_trial_marker_data.(markers_guide.reference_guide{"Left Walking Direction Marker"}{2})) / 2;
    psis.y = (single_trial_marker_data.(markers_guide.reference_guide{"Right Walking Direction Marker"}{3}) + single_trial_marker_data.(markers_guide.reference_guide{"Right Walking Direction Marker"}{3})) / 2;

    distance = [ ...
        vecnorm([psis.x(right_IC(2).index); psis.y(right_IC(2).index)] - ...
                [psis.x(right_IC(1).index); psis.y(right_IC(1).index)]); ... % [mm]
        vecnorm([psis.x(left_IC(2).index); psis.y(left_IC(2).index)] - ...
                [psis.x(left_IC(1).index); psis.y(left_IC(1).index)])];    % [mm]

    distance = PROST.utils.convert_units(distance, "mm", "m");
    speed = distance ./ [(right_IC(2).time - right_IC(1).time); (left_IC(2).time - left_IC(1).time)];
    mean_speed = mean(speed); % [m/s]
end

function trajectories = save_marker_data(single_trial_marker_data)
    marker_names = single_trial_marker_data.Properties.VariableNames;
    marker_names(1) = [];
    marker_names = cellfun(@(x) x(1:end-1), marker_names, UniformOutput=false);

    for marker_name = string(marker_names)
        trajectories.(marker_name).x = single_trial_marker_data.(marker_name + "X")';
        trajectories.(marker_name).y = single_trial_marker_data.(marker_name + "Y")';
        trajectories.(marker_name).z = single_trial_marker_data.(marker_name + "Z")';
    end

    
    trajectories.unit = "mm";
    trajectories.sampling_freq.value = 200;
    trajectories.sampling_freq.unit = "Hz";
    trajectories.time_vector.value = single_trial_marker_data.Time;
    trajectories.time_vector.unit = "second";
    trajectories.n_samples = length(single_trial_marker_data.Time);
    trajectories.n_markers = length(marker_names);
end
