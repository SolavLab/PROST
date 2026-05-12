%% ------------------------------------------------------------------
%  build a matlab structure containing the first dataset data
%  Created by Dani Feal
%  Edited by Chen Reichsbouscher, 11.06.2025
% -------------------------------------------------------------------
%
clearvars -except -regexp ^Dataset_\d+$
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
        "Right PSIS"; ...
        "Left Lateral Ankle"; ...
        "Left Medial Ankle"; ...
        "Left Lateral Knee"; ...
        "Left Medial Knee"; ...
        "Left ASIS"; ...
        "Left PSIS"];
values = {{"RLAX", "RLAY", "RLAZ", 32, 33, 34}; ...
          {"RMAX", "RMAY", "RMAZ", 35, 36, 37}; .....
          {"RLKX", "RLKY", "RLKZ", 23, 24, 25}; ...
          {"RMKX", "RMKY", "RMKZ", 26, 27, 28}; ...
          {"RASISX", "RASISY", "RASISZ", 14, 15, 16}; ...
          {"RPSISX", "RPSISY", "RPSISZ", 8, 9, 10}; ...
          {"LLAX", "LLAY", "LLAZ", 59, 60, 61}; ...
          {"LMAX", "LMAY", "LMAZ", 62, 63, 64}; ...
          {"LLKX", "LLKY", "LLKZ", 50, 51, 52}; ...
          {"LMKX", "LMKY", "LMKZ", 53, 54, 55}; ...
          {"LASISX", "LASISY", "LASISZ", 17, 18, 19}; ...
          {"LPSISX", "LPSISY", "LPSISZ", 11, 12, 13}};
Markers_guide.reference_guide = dictionary(keys, values);
Dataset_1.Markers_guide = Markers_guide;

%       --------------------
% Dataset_1 / Lab_system :
%       --------------------
Lab_system.lab_frame = ...
    "X Direction: \n" + ...
    "For COP and marker trajectories: pointing in the direction that completes a right handed coordinate system.\n" + ...
    "for GRF data: the direction in the lab from the first forceplate to the last forceplate (walking direction).\n" + ...
    "Y Direction: \n" + ...
    "For COP and marker trajectories: the direction in the lab from the first forceplate to the last forceplate (walking direction).\n" + ...
    "For GRF data: pointing in the direction that completes a right handed coordinate system.\n" + ...
    "Z Direction: \n" + ...
    "For GRF, COP and marker trajectories the z direction is pointing up.";
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
Experiment_protocol.speed_categories = "V1 is a speed of 1.0 km/hour.\n" + ...
                                       "V15 is a speed of 1.5 km/hour.\n" + ...
                                       "V2 is a speed of 2.0 km/hour.\n" + ...
                                       "V25 is a speed of 2.5 km/hour.\n" + ...
                                       "V3 is a speed of 3.0 km/hour.\n" + ...
                                       "V35 is a speed of 3.5 km/hour.\n" + ...
                                       "V4 is a speed of 4.0 km/hour.\n";
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

% Get relevant marker names in original dataset
markers_guide = Dataset_1.Markers_guide;
for participant_number=1:n_participants
    % Initialize counters
    trials_counter = 0;
    left_steps_counter = 0;
    right_steps_counter = 0;

    % load data files:
    participant_ID = "Participant" + participant_number;
    participant_name = "participant_" + participant_number;
    participant_data = load(fullfile(data_path, participant_ID, "Raw_Data.mat"));
    participant_raw_data = participant_data.("Subject" + participant_number + "_raw");
    metadata_array = split(string(fileread(fullfile(data_path, participant_ID, "Metadata.txt"))));

    %                                    -------------------------------------
    % Dataset_1 / Data / participant_# / participant_ID_in_original_structure :
    %                                    -------------------------------------
    % the participant ID in the original data structure:
    Dataset_1.Data.(participant_name).participant_ID_in_original_structure = participant_ID;

    %                                    ---------
    % Dataset_1 / Data / participant_# / metadata :
    %                                    ---------
    % Age
    Dataset_1.Data.(participant_name).metadata.Age.value = double(metadata_array(4));
    Dataset_1.Data.(participant_name).metadata.Age.unit = "years";
    Dataset_1.Data.(participant_name).metadata.Age.method = "provided";

    % Sex
    Dataset_1.Data.(participant_name).metadata.Sex.value = metadata_array(6);
    Dataset_1.Data.(participant_name).metadata.Sex.unit = "Male/Female";
    Dataset_1.Data.(participant_name).metadata.Sex.method = "provided";

    % Height
    Dataset_1.Data.(participant_name).metadata.Height.value = double(metadata_array(9));
    Dataset_1.Data.(participant_name).metadata.Height.unit = "m";
    Dataset_1.Data.(participant_name).metadata.Height.method = "provided";

    % Mass
    Dataset_1.Data.(participant_name).metadata.Mass.value = double(metadata_array(13));
    Dataset_1.Data.(participant_name).metadata.Mass.unit = "kg";
    Dataset_1.Data.(participant_name).metadata.Mass.method = "provided";

    % Is_shod
    Dataset_1.Data.(participant_name).metadata.Is_shod.value = "Yes";
    Dataset_1.Data.(participant_name).metadata.Is_shod.unit = "Yes/No";
    Dataset_1.Data.(participant_name).metadata.Is_shod.method = "provided";

    % Calculate leg length, thigh length and shank length
    [right_leg_length, left_leg_length, right_thigh_length, left_thigh_length, right_shank_length, left_shank_length] = get_lengths(participant_raw_data, Dataset_1.Markers_guide); % [m]

    % Leg length - distance between anterior superior iliac spine (ASIS) and lateral ankle (LA)
    Dataset_1.Data.(participant_name).metadata.Leg_length.right = right_leg_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Leg_length.left = left_leg_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Leg_length.unit = "m";
    Dataset_1.Data.(participant_name).metadata.Leg_length.method = "calculated by median distance between ASIS and lateral ankle markers.";

    % Thigh length - distance between lateral knee (LK) and anterior superior iliac spine (ASIS)
    Dataset_1.Data.(participant_name).metadata.Thigh_length.right = right_thigh_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Thigh_length.left = left_thigh_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Thigh_length.unit = "m";
    Dataset_1.Data.(participant_name).metadata.Thigh_length.method = "calculated by median distance between ASIS and lateral knee markers.";

    % Shank length - distance between lateral knee (LK) and lateral ankle (LA)
    Dataset_1.Data.(participant_name).metadata.Shank_length.right = right_shank_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Shank_length.left = left_shank_length; % [m]
    Dataset_1.Data.(participant_name).metadata.Shank_length.unit = "m";
    Dataset_1.Data.(participant_name).metadata.Shank_length.method = "calculated by median distance between lateral knee and lateral ankle markers.";

    %                                                   ---------------------
    % Dataset_2 / Data / participant_# / uniform_data / Right,Left / step(#)
    %                                                   ---------------------
    % Prepping uniform data database
    Dataset_1.Data.(participant_name).uniform_data.right.step = [];
    Dataset_1.Data.(participant_name).uniform_data.left.step = [];

    %                                    -----------------
    % Dataset_1 / Data / participant_# / processed_original_data
    %                                    -----------------
    % Get available speeds
    available_speeds = zeros(1, 7);
    counter = 0;
    for speed_category=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_raw_data.("V" + speed_category))) > 1
            counter = counter + 1;
            available_speeds(counter) = speed_category;
        end
    end
    available_speeds = available_speeds(1:counter);

    % Run of the available speeds for this participant:
    for speed_category=available_speeds
        % Get data
        COP_data = participant_raw_data.("V" + speed_category).COP;
        marker_data = participant_raw_data.("V" + speed_category).Trajectories;
        GRF_data = participant_raw_data.("V" + speed_category).GRF;
        available_num_trials = length(COP_data);

        for num_trial=1:available_num_trials
            trials_counter = trials_counter + 1;

            % ------------------------------------------------------------------------------------
            %                            processed_original_data
            % ------------------------------------------------------------------------------------
            %                                                              -----------------
            % Dataset_1 / Data / participant_# / processed_original_data / trial(#) / origin
            %                                                              -----------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).origin.speed_catagory = "V" + speed_category;
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).origin.trial_number = num_trial;
            %                                                              -----------------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / walking_direction
            %                                                              -----------------------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).walking_direction = "+y in COP and tragectories data. +x in GRF data";

            %                                                              ----------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / first_foot
            %                                                              ----------------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).first_foot = "right";

            single_trial_COP_data = COP_data{num_trial, 2};
            single_trial_GRF_data = GRF_data{num_trial, 2};
            single_trial_marker_data = marker_data{num_trial, 2};

            %                                                              ----------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / Time
            %                                                              ----------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).Time.value = single_trial_COP_data.Time;
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).Time.unit = "second";
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).Sample_freq.value = 1/(single_trial_COP_data.Time(2) - single_trial_COP_data.Time(1));
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).Sample_freq.unit = "Hz";

            %                                                              ---------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / GRF
            %                                                              ---------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Left.x = single_trial_GRF_data.L_GRF_X; % walking direction
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Left.y = single_trial_GRF_data.L_GRF_Y; % not reliable, weird sometimes, pointing outside
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Left.z = single_trial_GRF_data.L_GRF_Z; % up
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Right.x = single_trial_GRF_data.R_GRF_X; % walking direction
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Right.y = single_trial_GRF_data.R_GRF_Y; % not reliable, weird sometimes, pointing outside
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.Right.z = single_trial_GRF_data.R_GRF_Z; % up
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.unit = "N";

            %                                                              -----------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / COP, events
            %                                                              -----------------------
            % We will only get the data from force plated 2 3 4 & 5 and number them 1,2,3,4
            % this is because force plates 1 and 6 are (almost) always empty
            forceplate_counter = 0;
            for force_plate=[2 3 4 5]
                forceplate_counter = forceplate_counter + 1;

                % Get COP data
                % cop is given in meters. notice we multiplied by 1000 to convert to mm.
                x_cop = PROST.utils.convert_units(single_trial_COP_data.("FP" + force_plate + "_X"), "m", "mm"); % [mm]
                y_cop = PROST.utils.convert_units(single_trial_COP_data.("FP" + force_plate + "_Y"), "m", "mm"); % [mm]
                z_cop = PROST.utils.convert_units(single_trial_COP_data.("FP" + force_plate + "_Z"), "m", "mm"); % [mm]

                % Process the COP data to get rid of wrong points
                if rem(forceplate_counter, 2) == 0 % left foot
                    x_cop(isnan(single_trial_GRF_data.L_GRF_Z)) = nan;
                    y_cop(isnan(single_trial_GRF_data.L_GRF_Z)) = nan;
                    z_cop(isnan(single_trial_GRF_data.L_GRF_Z)) = nan;
                else % right foot
                    x_cop(isnan(single_trial_GRF_data.R_GRF_Z)) = nan;
                    y_cop(isnan(single_trial_GRF_data.R_GRF_Z)) = nan;
                    z_cop(isnan(single_trial_GRF_data.R_GRF_Z)) = nan;
                end
                getrid = isoutlier(x_cop) | isoutlier(y_cop);
                x_cop(getrid) = nan;
                y_cop(getrid) = nan;
                z_cop(getrid) = nan;

                % Save the COP
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(forceplate_counter).x = x_cop;
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(forceplate_counter).y = y_cop;
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(forceplate_counter).z = z_cop;
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.unit = "mm";

                % Find the event indices and times
                COP_indices = 1:length(x_cop);
                COP_indices = COP_indices(~isnan(x_cop));

                % save IC
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + forceplate_counter).index = COP_indices(1);
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + forceplate_counter).time = single_trial_COP_data.Time(COP_indices(1)); % [sec]

                % save TO
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("TO" + forceplate_counter).index = COP_indices(end);
                Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("TO" + forceplate_counter).time = single_trial_COP_data.Time(COP_indices(end)); % [sec]
            end

            %                                                                          ---------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / events / method
            %                                                                          ---------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.method = "Calculated using the COP (since it has already taken into account the unreliable values in the edges)," + ...
                " by finding the first and last index and time for which the COP is not NaN.";
            %                                                              ------------------------
            % Dataset_1 / Data / participant_# / processed_original_data / trials(#) / trajectories
            %                                                              ------------------------
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).trajectories.value = single_trial_marker_data;
            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).trajectories.unit = "mm";

            %                                                              ----------------
            % Dataset_1 / Data / participant_# / processed_original_data / trial(#) / speed
            %                                                              ----------------
            IC1_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC1.index;
            IC2_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC2.index;
            IC3_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC3.index;
            IC4_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC4.index;

            IC1_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC1.time;
            IC2_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC2.time;
            IC3_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC3.time;
            IC4_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.IC4.time;

            psis.x = (single_trial_marker_data.(Markers_guide.reference_guide{"Right PSIS"}{1}) + single_trial_marker_data.(Markers_guide.reference_guide{"Left PSIS"}{1})) / 2;
            psis.y = (single_trial_marker_data.(Markers_guide.reference_guide{"Right PSIS"}{2}) + single_trial_marker_data.(Markers_guide.reference_guide{"Right PSIS"}{2})) / 2;

            distance = [vecnorm([psis.x(IC3_index); psis.y(IC3_index)] - [psis.x(IC1_index); psis.y(IC1_index)]); ... % [mm]
                vecnorm([psis.x(IC4_index); psis.y(IC4_index)] - [psis.x(IC2_index); psis.y(IC2_index)])];    % [mm]
            distance = PROST.utils.convert_units(distance, "mm", "m");
            speed = distance ./ [(IC3_time - IC1_time); (IC4_time - IC2_time)];
            mean_speed = mean(speed); % [m/s]

            speed_structure.value = PROST.utils.convert_units(PROST.utils.convert_units(mean_speed, "m", "km"), "hour", "second");
            speed_structure.unit="km/hour";
            speed_structure.method= ...
            "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
            "Then calculated the mean speed of both feet.\n" + ...
            "Converted from [m/sec] to [km/hour]";
            speed_structure.speed_category = "V" + speed_category;

            Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).speed = speed_structure;

            % -----------------------------------------------------------------------------------
            %                            uniform_data
            % -----------------------------------------------------------------------------------
            %                              ---------------- --------------- --------
            % Dataset_1 / Data / participant_# / uniform_data / right or left / step(#)
            %                              ---------------- --------------- --------
            % reminder:
            % the frame of reference of the given (original) markers and COP:
            % x - right direction
            % y - walking direction
            % z - up
            % the frame of reference of the given (original) GRF:
            % x - walking direction
            % y - the medial direction?
            % z - up
            % ---------------------------------------------
            % in uniform data, the markers and COP data should be transformed so that:
            % x - walking direction
            % y - to the left (of the body)
            % z - up
            % ---------------------------------------------
            % so: (for markers and COP)
            % summery of needed transformation:
            % ---------------------------------
            % new_x =  old_y
            % new_y = - old_x
            % new_z =  old_z

            % also we are normalizing each step to only 101 points
            % summery of temporal alignment:
            % -------------------------
            % the GRF should be temporally aligned (to 101 points) in the stance phase (SP) -> from initial contact to toe off
            % while the COP and markers should be temporally aligned (to 101 points) in the weight acceptance + single support phase (SS) -> from initial contact to opposite initial contact

            % Saving data of 3 steps
            % We have the data of 4 steps per trial but since OIC isn't known,
            % we use the IC time of the subsequent step.
            for step_number=1:3
                % Get event indices and times
                IC_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + step_number).index;
                IC_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + step_number).time;
                TO_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("TO" + step_number).index;
                TO_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("TO" + step_number).time;
                OIC_index = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + (step_number + 1)).index;
                OIC_time = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).events.("IC" + (step_number + 1)).time;
                
                if OIC_index < IC_index
                    continue
                end
                if rem(step_number, 2) == 0
                    left_steps_counter = left_steps_counter + 1;
                    relevant_index = left_steps_counter;
                    side = "left";
                    foot = "Left";
                else
                    right_steps_counter = right_steps_counter + 1;
                    relevant_index = right_steps_counter;
                    side = "right";
                    foot = "Right";
                end
                
                %                                                                          -------
                % Dataset_1 / Data / participant_# / uniform_data / right,left / step(#) / source
                %                                                                          -------
                %                                                                               ----------------------------------
                %                                                                              / original_trial_number_in_database
                %                                                                               ----------------------------------
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_trial_number_in_database = trials_counter;
                %                                                                               ---------------
                %                                                                              / original_trial
                %                                                                               ---------------
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_trial = "V" + speed_category + "_" + num_trial;
                %                                                                               ------------
                %                                                                              / step_number
                %                                                                               ------------
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.step_number = step_number;
                %                                                                               -------------
                %                                                                              / Plate_number
                %                                                                               -------------
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.plate_number = step_number + 1;

                % original IC,OIC,and TO: index and time
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.forceplate_index = IC_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.forceplate_index = OIC_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.forceplate_index = TO_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.trajectory_index = IC_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.trajectory_index = OIC_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.trajectory_index = TO_index;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_IC.time = IC_time;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_OIC.time = OIC_time;
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).source.original_TO.time = TO_time;
                % --------------------------------------------------------------

                % Size of temporal alignment. We want 101 points so data is in
                % percentage of stance phase \ single support phase.
                n_temporal_alignment = 101;

                %                                                                         ----------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / COP   -  temporally aligned
                %                                                                         ----------------------------

                % transform the original y to be x now (so x will be the walking direction)
                % and the original x to be the new -y (so the z direction will still point up)
                one_step_COP.x = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(step_number).y;
                one_step_COP.y = -Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(step_number).x;
                % one_step_COP.z = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).COP.FP(step_number).z;

                % cut the COP data from IC to OIC (weight acceptance + single support) and interpolate it to 101 points
                original_indices = 1:length(one_step_COP.x);
                original_indices = original_indices(~isnan(one_step_COP.x));
                interpolated_COP.x = interp1(IC_index:OIC_index, one_step_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.y = interp1(IC_index:OIC_index, one_step_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.z = zeros(size(interpolated_COP.x));
                interpolated_COP.unit = "mm";
                interpolated_COP.temporal_alignment = "Initial contact to opposite initial contact.";

                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).COP = interpolated_COP;

                %                                                                          ----------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / GRF   -  temporally aligned
                %                                                                          ----------------------------

                % the original x axis stays as x as this is the walking direction
                one_step_GRF.x = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.(foot).x;

                % the original z axis stays as z as this is the direction pointing up
                one_step_GRF.z = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.(foot).z;

                % y on the other hand, was always pointing inwards in the original data.
                % in the other hand in order to comply with the right hand rule
                %                          Z * X = Y
                % and with the directions of the x axis and z axis
                % the y axis should be pointing to the Left!
                % so for steps 1 and 3 (right foot), the GRF should stay the same
                % but for steps 2 and 4 (left foot), the direction of the GRF needs to be flipped.
                one_step_GRF.y = (-1)^(step_number + 1) .* Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).GRF.(foot).y;

                % cut the GRF data from IC to TO and interpolate it to 101 points :
                interpolated_GRF.x = interp1(IC_index:TO_index, one_step_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.y = interp1(IC_index:TO_index, one_step_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.z = interp1(IC_index:TO_index, one_step_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.unit = "N";
                interpolated_GRF.temporal_alignment = "Initial contact to toe off (stance phase).";
                
                % OIC event after temporal alignment
                interpolated_GRF.OIC.time = round((n_temporal_alignment - 1)*(OIC_index - IC_index)/(TO_index - IC_index));
                interpolated_GRF.OIC.index = interpolated_GRF.OIC.time + 1;

                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).GRF = interpolated_GRF;

                %                                                                          --------------------------------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / Markers   -  temporally aligned
                %                                                                          --------------------------------
                % first we need to decide what markers interest us:
                % we will store the data of the medial and lateral ankle markers
                %                    and of the medial and lateral knee markers
                % and the mean between the medial and lateral markers (for the center of the ankle and the knee)
                % get the markers data
                trajectories = Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).trajectories;
                % For the ankle
                one_step_Markers.Ankle.lateral.x = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{2});
                one_step_Markers.Ankle.lateral.y = -trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{1});
                one_step_Markers.Ankle.lateral.z = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{3});
                one_step_Markers.Ankle.medial.x = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{2});
                one_step_Markers.Ankle.medial.y = -trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{1});
                one_step_Markers.Ankle.medial.z = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{3});

                % For the knee
                one_step_Markers.Knee.lateral.x = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{2});
                one_step_Markers.Knee.lateral.y = -trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{1});
                one_step_Markers.Knee.lateral.z = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{3});
                one_step_Markers.Knee.medial.x = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Knee"}{2});
                one_step_Markers.Knee.medial.y = -trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Knee"}{1});
                one_step_Markers.Knee.medial.z = trajectories.value.(Dataset_1.Markers_guide.reference_guide{foot + " Medial Knee"}{3});

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
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).Markers = interpolated_Markers;

                %                                                                       ------
                % Dataset_1 / Data / participant_# / uniform_data / Right,Left / step(#) / speed
                %                                                                       ------
                Dataset_1.Data.(participant_name).uniform_data.(side).step(relevant_index).speed = ...
                    Dataset_1.Data.(participant_name).processed_original_data.trial(trials_counter).speed;
            end
        end
    end

    % Add up total number of trials
    Dataset_1.Experiment_protocol.num_trials = Dataset_1.Experiment_protocol.num_trials + trials_counter;
end
Dataset_1.Experiment_protocol.num_steps = Dataset_1.Experiment_protocol.num_trials .* 3;

save("..\Dataset_1.mat","Dataset_1")


%% ----------------------------
%  Auxiliary Functions
% -----------------------------
% function [metadata, standing_trial] = get_metadata(metadata_array, participant_raw_data, markers_guide);
% %GET_METADATA reads anthropometric data from the data files of the participant.
% % Also gets the standing trial data and calculates missing data from it 
% % (leg length, shank length, thigh length etc).
% % Input :
% %   trial_for_metadata_raw - an example trial containing the participant 
% %                            metadata (anthropometric data).
% %   standing_trial_raw - the standing trial for calculating missing data.
% %   markers_guide - the reference guide for all the important markers.
% % Output :
% %   metadata - the anthropometric data of the participant.
% %   standing_trial - the standing trial measurement data.
% 
%     % Get participant metadata
%     % trial_data_for_metadata = ezc3dRead(convertStringsToChars(trial_path));
% 
%       % Age
%     Dataset_1.Data.(participant_name).metadata.Age.value = double(metadata_array(4));
%     Dataset_1.Data.(participant_name).metadata.Age.unit = "years";
%     Dataset_1.Data.(participant_name).metadata.Age.method = "provided";
% 
%     % Sex
%     Dataset_1.Data.(participant_name).metadata.Sex.value = metadata_array(6);
%     Dataset_1.Data.(participant_name).metadata.Sex.unit = "Male/Female";
%     Dataset_1.Data.(participant_name).metadata.Sex.method = "provided";
% 
%     % Height
%     Dataset_1.Data.(participant_name).metadata.Height.value = double(metadata_array(9));
%     Dataset_1.Data.(participant_name).metadata.Height.unit = "m";
%     Dataset_1.Data.(participant_name).metadata.Height.method = "provided";
% 
%     % Mass
%     Dataset_1.Data.(participant_name).metadata.Mass.value = double(metadata_array(13));
%     Dataset_1.Data.(participant_name).metadata.Mass.unit = "kg";
%     Dataset_1.Data.(participant_name).metadata.Mass.method = "provided";
% 
%     % Is_shod
%     Dataset_1.Data.(participant_name).metadata.Is_shod.value = "Yes";
%     Dataset_1.Data.(participant_name).metadata.Is_shod.unit = "Yes/No";
%     Dataset_1.Data.(participant_name).metadata.Is_shod.method = "provided";
% 
%     % Calculate leg length, thigh length and shank length
%     [right_leg_length, left_leg_length, right_thigh_length, left_thigh_length, right_shank_length, left_shank_length] = get_lengths(participant_raw_data, markers_guide); % [m]
% 
%     % Calculate missing metadata from standing trial    
%     % leg length - from ASIS to lateral ankle
%     metadata.Leg_length.right = right_leg_length;
%     metadata.Leg_length.left = left_leg_length;
%     metadata.Leg_length.unit = "m";
%     metadata.Leg_length.method = "calculated by distance between ASIS and lateral ankle markers in the standing trial";
% 
%     % thigh length - from ASIS to lateral knee
%     metadata.Thigh_length.right = right_thigh_length;
%     metadata.Thigh_length.left = left_thigh_length;
%     metadata.Thigh_length.unit = "m";
%     metadata.Thigh_length.method = "calculated by distance between ASIS and lateral knee markers in the standing trial";
% 
%     % shank length - from lateral knee to lateral ankle
%     metadata.Shank_length.right = right_shank_length;
%     metadata.Shank_length.left = left_shank_length;
%     metadata.Shank_length.unit = "m";
%     metadata.Shank_length.method = "calculated by distance between lateral knee and lateral ankle markers in the standing trial";
% end

% function [marker_data, COP_data, GRF_data, available_num_trials] = get_trial_data(participant_raw_data)
% %GET_TRIAL_DATA reads the marker and force plate measurements and event 
% % information from the data file of a trial.
% % Input :
% %   trial_path - path to the data file of a trial containing the trial 
% %                measurements.
% %   markers_guide - the reference guide for all the important markers.
% % Output :
% %   marker_data - marker trajectory measurements.
% %   forceplate_data - force plate measurements.
% %   event_data - information of events during the trial (foot strikes and foot
% %                offs).
% 
%     % Get data
%     COP_data = participant_raw_data.("V" + speed_category).COP;
%     marker_data = participant_raw_data.("V" + speed_category).Trajectories;
%     GRF_data = participant_raw_data.("V" + speed_category).GRF;
%     available_num_trials = length(COP_data);
% end
% 
% function steps_info = save_steps_info(event_data, forceplate_data, marker_data, n_steps)
% %GET_STEPS_INFO saves the step information of all steps in a single trial to our 
% % preferred structure format for easier access later.
% % Input :
% %   event_data - information of events during the trial (foot strikes and foot
% %                offs).
% %   forceplate_data - force plate measurements.
% %   marker_data - marker trajectory measurements. 
% %   n_steps - number of steps in the trial.
% % Output :
% %   steps_info - a struct array with the step information of each step. Includes
% %                event (IC, OIC, TO) times and indices in the force plate time
% %                vector and trajectory time vector, the foot, the plate and step 
% %                quality ("good" or "bad").
% 
%     % By what frequency to round?
%     round_by = max(forceplate_data.freq, marker_data.freq);
% 
%     % Indices of events in events vectors for first steps.
%     base_IC_index = 1;
%     base_OIC_index = 3;
%     base_TO_index = 4;
%     steps_info(n_steps) = struct("events", [], "step_quality", [], "plate", [], "foot", []);
%     feet = strings(n_steps, 1);
%     for step_number=1:n_steps
%         shift_index = 2*(step_number - 1); % Shift indices of events for each step
% 
%         % initial contact
%         steps_info(step_number).events.IC.time = event_data.times(base_IC_index + shift_index);
%         steps_info(step_number).events.IC.time = round(round_by*(steps_info(step_number).events.IC.time))/round_by;
%         [~, steps_info(step_number).events.IC.forceplate_index] = min(abs(steps_info(step_number).events.IC.time - forceplate_data.time_vector));
%         [~, steps_info(step_number).events.IC.trajectory_index] = min(abs(steps_info(step_number).events.IC.time - marker_data.time_vector));
% 
%         % opposite initial contact
%         steps_info(step_number).events.OIC.time = event_data.times(base_OIC_index + shift_index);
%         steps_info(step_number).events.OIC.time = round(round_by*(steps_info(step_number).events.OIC.time))/round_by;
%         [~, steps_info(step_number).events.OIC.forceplate_index] = min(abs(steps_info(step_number).events.OIC.time - forceplate_data.time_vector));
%         [~, steps_info(step_number).events.OIC.trajectory_index] = min(abs(steps_info(step_number).events.OIC.time - marker_data.time_vector));
% 
%         % toe off
%         steps_info(step_number).events.TO.time = event_data.times(base_TO_index + shift_index);
%         steps_info(step_number).events.TO.time = round(round_by*(steps_info(step_number).events.TO.time))/round_by;
%         [~, steps_info(step_number).events.TO.forceplate_index] = min(abs(steps_info(step_number).events.TO.time - forceplate_data.time_vector));
%         [~, steps_info(step_number).events.TO.trajectory_index] = min(abs(steps_info(step_number).events.TO.time - marker_data.time_vector));
% 
%         % foot
%         feet(step_number) = lower(event_data.feet(base_IC_index + shift_index));
%     end
%     steps_info = check_step(steps_info, forceplate_data, feet);
% end
% 
% function steps_info = check_step(steps_info, forceplate_data, feet)
% %CHECK_STEP checks the quality of the step and updates the step information
% % accordingly. A "bad" step is one that either started or ended on a force
% % plate, had both feet on the plate or had the foot on both steps at the same
% % time.
% % Input :
% %   steps_info - the information of the steps. 
% %   forceplate_data - force plate measurements of all plates.
% %   feet - the foot of each step according to the data files.
% % Output :
% %   steps_info - the information of each step updated with the step quality, the 
% %                relevant plate and foot (if "good").
% 
%     % Tolerance value for time difference.
%     tol = 0.1;
% 
%     % Set default values of steps_info to "bad" steps
%     [steps_info.step_quality] = deal("bad");
%     [steps_info.plate] = deal(NaN);
%     [steps_info.foot] = deal("bad");
% 
%     % Get activation and deactivation force plate times
%     fp_times = get_forceplate_times(forceplate_data);
% 
%     % Get event times of IC and TO for each step
%     times_IC = arrayfun(@(s) s.events.IC.time, steps_info);
%     times_TO = arrayfun(@(s) s.events.TO.time, steps_info);
% 
%     % Get rid of plates with bad steps
%     plates = 1:forceplate_data.n_forceplates;
%     idx1 = isnan(fp_times(:, 1)) | isnan(fp_times(:, 2)); % Plates with no activation or deactivation time
%     idx2 = [abs(diff(fp_times(:, 1))) < tol; 0] | [abs(diff(fp_times(:, 2))) < tol; 0]; % Plates where foot was on both plates
%     plates(idx1 | idx2) = [];
% 
%     % Check which step belongs to which plate
%     for fp_num=plates
%         [~, step_number_IC] = min(abs(times_IC - fp_times(fp_num, 1)));
%         [~, step_number_TO] = min(abs(times_TO - fp_times(fp_num, 2)));
% 
%         if step_number_IC == step_number_TO 
%             step_IC_time = steps_info(step_number_IC).events.IC.time;
%             step_TO_time = steps_info(step_number_IC).events.TO.time;
%             step_plate = steps_info(step_number_IC).plate;
%             step_quality = steps_info(step_number_IC).step_quality;
%             if abs(step_IC_time - fp_times(fp_num, 1)) < tol && ...
%                abs(step_TO_time - fp_times(fp_num, 2)) < tol && ...
%                (step_quality == "bad" || ...
%                (abs(step_IC_time - fp_times(step_plate, 1) > abs(step_IC_time - fp_times(fp_num, 1)) && ...
%                 abs(step_TO_time - fp_times(step_plate, 2)) > abs(step_TO_time - fp_times(fp_num, 2)))))
%                 steps_info(step_number_IC).step_quality = "good";
%                 steps_info(step_number_IC).plate = fp_num;
%                 steps_info(step_number_IC).foot = feet(step_number_IC);
%             end
%         end
%     end
% end
% 
% function [activation_time, deactivation_time] = get_plate_activation_deactivation_times(plate_data, time_vector)
% %GET_PLATE_ACTIVATION_DEACTIVATION_TIMES calculates the activation and
% % deactivation times of a given force plate. These are the first and last times
% % when normal ground reaction force is measured. Default times: NaN.
% % Input :
% %   plate_data - the measurement data of a single force plate.
% %   time_vector - the time vector of the force plate.
% % Output :
% %   activation_time - the activation time of the force plate.
% %   deactivation_time - the deactivation time of the force plate.
% 
%     Fz = plate_data.grf(3, :);
%     start_index = find(Fz ~= 0 & ~isnan(Fz), 1, 'first');
%     end_index = find(Fz ~= 0 & ~isnan(Fz), 1, 'last');
%     if isempty(start_index) || start_index == 1
%         activation_time = NaN;
%     else
%         activation_time = time_vector(start_index);
%     end
%     if isempty(end_index) || end_index == length(Fz)
%         deactivation_time = NaN;
%     else
%         deactivation_time = time_vector(end_index);
%     end
% end
% 
% function fp_times = get_forceplate_times(forceplate_data)
% %GET_FORCEPLATE_TIMES calculates the activation and deactivation times of all
% % force plates.
% % Input :
% %   forceplate_data - measurement data of all force plates.
% % Output :
% %   fp_times - a nx2 array with the activation (column 1) and deactivation
% %              (column 2) of each force plate. n is the number of force plates.
% 
%     fp_times = zeros(forceplate_data.n_forceplates, 2);
%     for fp_number=1:forceplate_data.n_forceplates
%         [activation_time, deactivation_time] = get_plate_activation_deactivation_times(forceplate_data.plate(fp_number), forceplate_data.time_vector);
%         fp_times(fp_number, 1) = activation_time;
%         fp_times(fp_number, 2) = deactivation_time;
%     end
% end
% 
% function steps_info = fix_event_times(steps_info, forceplate_data, marker_data)
% %FIX_EVENT_TIMES For each step in the trial, if the step is good, changes the 
% % initial contact and toe-off that we saved according to the GRF (checks where 
% % the GRF is not 0). If no GRF signal is found changes that step to "bad".
% % Input :
% %   steps_info - step information of all steps in the trial. 
% %   forceplate_data - force plate measurements. 
% %   marker_data - marker trajectory measurements. 
% % Output :
% %   steps_info - the information of all steps updated with the fixed event times 
% %                and the step quality.
% 
% 
%     for step_num=1:length(steps_info)
%         if steps_info(step_num).step_quality == "good"
%             % find out what is the right force plate
%             fp_num = steps_info(step_num).plate;
% 
%             % get the GRF from this force plate
%             GRF = forceplate_data.plate(fp_num).grf;
% 
%             % get the IC, OIC and TO of this step
%             IC_index = steps_info(step_num).events.IC.forceplate_index;
%             OIC_index = steps_info(step_num).events.OIC.forceplate_index;
%             TO_index = steps_info(step_num).events.TO.forceplate_index;
% 
%             % Fixing IC Index
%             % cut the GRF according to the IC and OIC
%             cut_GRF.x = GRF(1, IC_index:OIC_index);
%             cut_GRF.y = GRF(2, IC_index:OIC_index);
%             cut_GRF.z = GRF(3, IC_index:OIC_index);
% 
%             % Find data that is in IC:OIC that is not an outlier and has no
%             % "inactive" constant value (0 for GRF).
%             % is_in = (~isoutlier(cut_GRF.x)) & (~isoutlier(cut_GRF.y)) & (~isoutlier(cut_GRF.z)) & (cut_GRF.z > 0);
%             is_in = (cut_GRF.z > 0);
%             added_IC = find(is_in, 1, 'first'); 
% 
%             % Now add the new IC index to the old one
%             if isempty(added_IC)
%                 steps_info(step_num).step_quality = "bad";
%                 warning('Participant %s, condition %d, trial %d: Step %d was reported as good, but no GRF initial contact detected', participant_ID, c, t, step_num);
%             else
%                 % change the IC of this good step:
%                 new_forceplate_IC_index = IC_index + added_IC - 1;
%                 [~, new_trajectory_IC_index] = min(abs(forceplate_data.time_vector(new_forceplate_IC_index) - marker_data.time_vector));
%                 steps_info(step_num).events.IC.forceplate_index = new_forceplate_IC_index;
%                 steps_info(step_num).events.IC.time = forceplate_data.time_vector(new_forceplate_IC_index);
%                 steps_info(step_num).events.IC.trajectory_index = new_trajectory_IC_index;
%             end
%             if ~(mod(steps_info(step_num).events.IC.forceplate_index, 1) == 0) || ~(mod(steps_info(step_num).events.IC.trajectory_index, 1) == 0)
%                 error("IC index not an integer.\n" + ...
%                     "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.IC.forceplate_index, steps_info(step_num).events.IC.trajectory_index)
%             end
% 
%             % Fixing TO Index
%             % cut the GRF according to the OIC and TO
%             cut_GRF.x = GRF(1, OIC_index:TO_index);
%             cut_GRF.y = GRF(2, OIC_index:TO_index);
%             cut_GRF.z = GRF(3, OIC_index:TO_index);
% 
%             % Find data that is in OIC:TO that is not an outlier and has no
%             % "inactive" constant value (0 for GRF).
%             is_in = (cut_GRF.z > 0);
%             added_OIC = find(is_in, 1, 'last'); 
% 
%             % Now add the new IC index to the old one
%             if isempty(added_OIC)
%                 steps_info(step_num).step_quality = "bad";
%                 warning('Participant %s, condition %d, trial %d: Step %d was reported as good, but no GRF toe-off detected', participant_ID, c, t, step_num);
%             else
%                 % change the IC of this good step:
%                 new_forceplate_TO_index = OIC_index + added_OIC - 1;
%                 [~, new_trajectory_TO_index] = min(abs(forceplate_data.time_vector(new_forceplate_TO_index) - marker_data.time_vector));
%                 steps_info(step_num).events.TO.forceplate_index = new_forceplate_TO_index;
%                 steps_info(step_num).events.TO.time = forceplate_data.time_vector(new_forceplate_TO_index);
%                 steps_info(step_num).events.TO.trajectory_index = new_trajectory_TO_index;
%             end
%             if ~(mod(steps_info(step_num).events.TO.forceplate_index, 1) == 0) || ~(mod(steps_info(step_num).events.TO.trajectory_index, 1) == 0)
%                 error("TO index not an integer.\n" + ...
%                       "Forceplate index: %d. Trajectory index: %d", steps_info(step_num).events.TO.forceplate_index, steps_info(step_num).events.TO.trajectory_index)
%             end
%         end
%     end
% end
% 
% function trajectories = save_marker_data(marker_data, standing_trial, markers_guide)
% %SAVE_MARKER_DATA saves the measurement data of a single trial from the markers 
% % to our preferred structure format for easier access later. Also saves virtual 
% % knee trajectories from the given markers.
% % Input :
% %   marker_data - the measurement data from the markers that we saved from the 
% %                 data files.
% %   standing_trial - the measurement data from the standing trial. Used for
% %                    calculating virtual markers.
% %   markers_guide - the reference guide for all the important markers.
% % Output :
% %   trajectories - trajectory measurements. Includes also units, sampling 
% %         frequency, time vector, number of samples and number of markers.
% 
%     trajectories.unit = "mm";
%     trajectories.time_vector.value = marker_data.time_vector;
%     trajectories.time_vector.unit = "second";
%     trajectories.sampling_freq.value = marker_data.freq;
%     trajectories.sampling_freq.unit = "Hz";
%     trajectories.n_markers = marker_data.n_markers;
%     trajectories.n_samples = marker_data.n_samples;
%     for idx=1:marker_data.n_markers
%         marker_name = marker_data.marker_names(idx);
%         trajectories.(marker_name).x = squeeze(marker_data.data(1, idx, :))';
%         trajectories.(marker_name).y = squeeze(marker_data.data(2, idx, :))';
%         trajectories.(marker_name).z = squeeze(marker_data.data(3, idx, :))';
%     end
% 
%     % Prep virtual markers
%     trajectories.(markers_guide.reference_guide{"Right Lateral Knee"}{1}) = struct("x", [], "y", [], "z", []);
%     trajectories.(markers_guide.reference_guide{"Left Lateral Knee"}{1}) = struct("x", [], "y", [], "z", []);
%     trajectories.(markers_guide.reference_guide{"Right Medial Knee"}{1}) = struct("x", [], "y", [], "z", []);
%     trajectories.(markers_guide.reference_guide{"Left Medial Knee"}{1}) = struct("x", [], "y", [], "z", []);
% 
%     try
%     % Lateral Virtual Knee calculated from Fibula Head (FAX) and
%     % Lateral Femoral Epicondyle (FLE)
%     right_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Lateral Femoral Epicondyle"}{2}); % R_FLE
%     left_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Lateral Femoral Epicondyle"}{2}); % L_FLE
%     right_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Fibular Head"}{2}); % R_FAX
%     left_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Fibular Head"}{2}); % L_FAX
%     trajectories.(markers_guide.reference_guide{"Right Lateral Knee"}{1}) = ...
%         PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Right Fibular Head"}{1}), ... % R_FAX
%                         trajectories.(markers_guide.reference_guide{"Right Lateral Ankle"}{1}), ...      % R_FAL
%                         right_ST_below_knee, right_ST_above_knee);
%     trajectories.(markers_guide.reference_guide{"Left Lateral Knee"}{1}) = ...
%         PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Left Fibular Head"}{1}), ... % L_FAX
%                         trajectories.(markers_guide.reference_guide{"Left Lateral Ankle"}{1}), ...      % L_FAL
%                         left_ST_below_knee, left_ST_above_knee);
% 
%     % Medial Virtual Knee calculated from Tibial Tuberosity (TTC) and
%     % Medial Femoral Epicondyle (FME)
%     right_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Medial Femoral Epicondyle"}{2}); % R_FME
%     left_ST_above_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Medial Femoral Epicondyle"}{2}); % L_FME
%     right_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Right Tibial Tuberosity"}{2}); % R_TTC
%     left_ST_below_knee = standing_trial.data(:, markers_guide.reference_guide{"Left Tibial Tuberosity"}{2}); % L_TTC
%     trajectories.(markers_guide.reference_guide{"Right Medial Knee"}{1}) = ...
%     PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Right Tibial Tuberosity"}{1}), ... % R_TTC
%                     trajectories.(markers_guide.reference_guide{"Right Medial Ankle"}{1}), ...      % R_TAM
%                     right_ST_below_knee, right_ST_above_knee);
%     trajectories.(markers_guide.reference_guide{"Left Medial Knee"}{1}) = ...
%     PROST.utils.get_knee_marker(trajectories.(markers_guide.reference_guide{"Left Tibial Tuberosity"}{1}), ...  % L_TTC
%                     trajectories.(markers_guide.reference_guide{"Left Medial Ankle"}{1}), ...       % L_TAM
%                     left_ST_below_knee, left_ST_above_knee);
%     catch
%         % We skip bad trials with missing important markers, can't compute
%         % virtual knee markers.
%     end
% end
% 
% function [GRF, COP] = save_forceplate_data(forceplate_data)
% %SAVE_FORCEPLATE_DATA saves the measurement data of a single trial from the 
% % force plates of to our preferred structure format for easier access later.
% % Input :
% %   forceplate_data - the measurement data from the force plates that we saved 
% %                     from the data files.
% % Output :
% %   GRF - ground reaction force measurements. Includes also units, sampling 
% %         frequency, time vector, number of samples and number of force plates.
% %   COP - center of pressure measurements. Includes also units, sampling 
% %         frequency, time vector, number of samples and number of force plates.
% 
%      % -------------------------------------------
%      % the x direction is the direction of walking.
%      % the y direction is pointing to the left (of the body).
%      % the z direction is pointing up.
%      % -------------------------------------------
%      for fp_num=1:forceplate_data.n_forceplates
%          GRF.("plate_" + fp_num).x = forceplate_data.plate(fp_num).grf(1, :);
%          GRF.("plate_" + fp_num).y = forceplate_data.plate(fp_num).grf(2, :);
%          GRF.("plate_" + fp_num).z = forceplate_data.plate(fp_num).grf(3, :);
% 
%          COP.("plate_" + fp_num).x = forceplate_data.plate(fp_num).cop(1, :);
%          COP.("plate_" + fp_num).y = forceplate_data.plate(fp_num).cop(2, :);
%          COP.("plate_" + fp_num).z = forceplate_data.plate(fp_num).cop(3, :);
%      end
%      GRF.unit = "N";
%      GRF.sampling_freq.value = forceplate_data.freq;
%      GRF.sampling_freq.unit = "Hz";
%      GRF.time_vector.value = forceplate_data.time_vector;
%      GRF.time_vector.unit = "second";
%      GRF.n_forceplates = forceplate_data.n_forceplates;
%      GRF.n_samples = forceplate_data.n_samples;
% 
%      COP.unit = "mm";
%      COP.sampling_freq.value = forceplate_data.freq;
%      COP.sampling_freq.unit = "Hz";
%      COP.time_vector.value = forceplate_data.time_vector;
%      COP.time_vector.unit = "second";
%      COP.n_forceplates = forceplate_data.n_forceplates;
%      COP.n_samples = forceplate_data.n_samples;
% end
% 
% function speed = calculate_speed(trajectories, events, walking_marker_name)
% %CALCULATE_SPEED estimates the mean walking speed of both steps of the trial 
% % from the trajectory measurement data and the times of the foot strikes.
% % Here the events are all those of the trial for both steps.
% % Input :
% %   trajectories - the trajectory measurement data.
% %   events - all events of the trial (not the same as step_info), includes all
% %            foot strikes of both feet.
% %   walking_marker_name - the name of the marker used for estimating the
% %                         distance walked during the trial.
% % Output :
% %   speed - the estimated speed of the trial in [m/sec].
% 
%     % Find foot strike times
%     n_events = length(events.names);
%     strike_times = struct("Left", [], "Right", []);
%     for idx=1:n_events
%         if strcmp(events.names(idx), "Foot Strike1") || strcmp(events.names(idx), "Foot Strike2")
%             foot = events.feet(idx);
%             time = events.times(idx);
%             strike_times.(foot) = [strike_times.(foot) time];
%         end
%     end
% 
%     % Calculate speed
%     sides = string(fields(strike_times));
%     n_sides = length(sides);
%     speed = nan(1, n_sides);
%     for side_num=1:n_sides     
%         % Get strike times and indices of the side
%         strikes = strike_times.(sides(side_num));
%         if length(strikes) ~= 2
%             continue
%         end
%         time_start = strikes(1);
%         time_end = strikes(2);
%         [~, index_start] = min(abs(time_start - trajectories.time_vector.value));
%         [~, index_end] = min(abs(time_end - trajectories.time_vector.value));
% 
%         % we chose to calculate the distance using the marker for the walking
%         % direction (the SXS marker)
%         distance_marker = [trajectories.(walking_marker_name).x; 
%                            trajectories.(walking_marker_name).y];
%         distance = norm([distance_marker(1, index_end) - distance_marker(1, index_start);...
%                          distance_marker(2, index_end) - distance_marker(2, index_start)]); % [mm]
%         distance = PROST.utils.convert_units(distance, trajectories.unit, "m"); % [m]
% 
%         % Calculate speed of the side
%         duration = time_end - time_start;
%         if trajectories.time_vector.unit ~= "second"
%             duration = PROST.utils.convert_units(duration, trajectories.time_vector.unit, "second");
%         end
%         speed(side_num) = distance/duration; % [m/sec]
%     end
%     speed = mean(speed, 'omitnan');
% end
% 
% function interpolated_COP = interpolate_COP(COP, step_info, walking_direction, n_temporal_alignment)
% %INTERPOLATE_COP converts the center of pressure (COP) measurements to our 
% % coordinate system and interpolates into n_temporal_alignment points from 
% % initial contact to opposite initial contact.
% % By default n_temporal_alignment is 101 points thus the trajectories are 
% % aligned to a percent of the phase.
% % Input :
% %   COP - the center of pressure measurement data.
% %   step_info - the information on the step to align. Includes event times and
% %               indices.
% %   walking_direction - the walking direction.
% %   n_temporal_alignment - the number of points to interpolate into.
% % Output :
% %   interpolated_COP - the transformed and interpolated measurements.
% 
%     % Default size of temporal alignment. We want 101 points so data is
%     % in percentage of stance phase \ single support phase.
%     if nargin < 4
%         n_temporal_alignment = 101;
%     end
% 
%     % Force plate number
%     fp_num = step_info.plate;
% 
%     % Get event indices of the force plate measurements
%     IC_index = step_info.events.IC.forceplate_index;
%     OIC_index = step_info.events.OIC.forceplate_index;
% 
%     % get data (get the COP of the fitting plate:
%     interpolated_COP.x = walking_direction*COP.("plate_" + fp_num).x;
%     interpolated_COP.y = walking_direction*COP.("plate_" + fp_num).y;
%     % interpolated_COP.z = COP.("plate_" + fp_num).z;
% 
%     % % cut the COP from IC to OIC filter it and temporally align to 101 points
%     interpolated_COP.x = interp1(IC_index:OIC_index, interpolated_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_COP.y = interp1(IC_index:OIC_index, interpolated_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_COP.z = zeros(size(interpolated_COP.x));
%     % interpolated_COP.z = interp1(IC_index:OIC_index, interpolated_COP.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
% 
%     interpolated_COP.unit = "mm";
%     interpolated_COP.temporal_alignment = "Initial contact to opposite initial contact.";
% end
% 
% function interpolated_GRF = interpolate_GRF(GRF, step_info, walking_direction, n_temporal_alignment)
% %INTERPOLATE_GRF converts the ground reaction force (GRF) measurements to our 
% % coordinate system and interpolates into n_temporal_alignment points of the 
% % stance phase (from initial contact to toe off).
% % By default n_temporal_alignment is 101 points thus the trajectories are 
% % aligned to a percent of the phase.
% % Input :
% %   GRF - the ground reaction force measurement data.
% %   step_info - the information on the step to align. Includes event times and
% %               indices.
% %   walking_direction - the walking direction.
% %   n_temporal_alignment - the number of points to interpolate into.
% % Output :
% %   interpolated_GRF - the transformed and interpolated measurements.
% 
%     % Default size of temporal alignment. We want 101 points so data is
%     % in percentage of stance phase \ single support phase.
%     if nargin < 4
%         n_temporal_alignment = 101;
%     end
% 
%     % Force plate number
%     fp_num = step_info.plate;
% 
%     % Get event indices of the force plate measurements
%     IC_index = step_info.events.IC.forceplate_index;
%     OIC_index = step_info.events.OIC.forceplate_index;
%     TO_index = step_info.events.TO.forceplate_index;
% 
%     % get data (get the GRF of the fitting plate:
%     interpolated_GRF.x = walking_direction*GRF.("plate_" + fp_num).x;
%     interpolated_GRF.y = walking_direction*GRF.("plate_" + fp_num).y;
%     interpolated_GRF.z = GRF.("plate_" + fp_num).z;
% 
%     % % cut the GRF from IC to TO filter it and temporally align to 101 points
%     interpolated_GRF.x = interp1(IC_index:TO_index, interpolated_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
%     interpolated_GRF.y = interp1(IC_index:TO_index, interpolated_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
%     interpolated_GRF.z = interp1(IC_index:TO_index, interpolated_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
% 
%     interpolated_GRF.unit = "N";
%     interpolated_GRF.temporal_alignment = "Initial contact to toe off (stance phase).";
% 
%     % OIC event after temporal alignment
%     interpolated_GRF.OIC.time = round((n_temporal_alignment - 1)*(OIC_index - IC_index)/(TO_index - IC_index));
%     interpolated_GRF.OIC.index = interpolated_GRF.OIC.time + 1;
% end
% 
% function interpolated_Markers = interpolate_trajectories(trajectories, step_info, markers_guide, walking_direction, n_temporal_alignment)
% %INTERPOLATE_TRAJECTORIES converts the trajectory measurements to our coordinate 
% % system and interpolates into n_temporal_alignment points of the weight 
% % acceptance + single support phase (from initial contact to opposite initial 
% % contact). 
% % By default n_temporal_alignment is 101 points thus the trajectories are 
% % aligned to a percent of the phase.
% % Input :
% %   trajectories - the trajectory measurement data.
% %   step_info - the information on the step to align. Includes event times and
% %               indices.
% %   markers_guide - the reference guide for all the important markers.
% %   walking_direction - the walking direction.
% %   n_temporal_alignment - the number of points to interpolate into.
% % Output :
% %   interpolated_Markers - the transformed and interpolated measurements.
% 
%     % Default size of temporal alignment. We want 101 points so data is
%     % in percentage of stance phase \ single support phase.
%     if nargin < 4
%         n_temporal_alignment = 101;
%     end
%     % Foot of the step
%     foot = PROST.utils.capitalize(step_info.foot);
% 
%     % Get event indices of the trajectory measurements
%     IC_index = step_info.events.IC.trajectory_index;
%     OIC_index = step_info.events.OIC.trajectory_index;
% 
%     % --------------------------------------------------
%     % first we need to decide what markers interest us:
%     % FAL - external ankle
%     % TAM - internal ankle
%     % LatVirtualKnee - external knee
%     % MedVirtualKnee - internal ankle
%     % we should also calculate the mean between the internal and
%     % the external markers.
%     % --------------------------------------------------
%     % get the markers data :
%     % For the ankle:
%     interpolated_Markers.Ankle.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).x;
%     interpolated_Markers.Ankle.lateral.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).y;
%     interpolated_Markers.Ankle.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Ankle"}{1}).z;
%     interpolated_Markers.Ankle.medial.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).x;
%     interpolated_Markers.Ankle.medial.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).y;
%     interpolated_Markers.Ankle.medial.z = trajectories.(markers_guide.reference_guide{foot + " Medial Ankle"}{1}).z;
% 
%     % For the knee:
%     interpolated_Markers.Knee.lateral.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).x;
%     interpolated_Markers.Knee.lateral.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).y;
%     interpolated_Markers.Knee.lateral.z = trajectories.(markers_guide.reference_guide{foot + " Lateral Knee"}{1}).z;
%     interpolated_Markers.Knee.medial.x = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).x;
%     interpolated_Markers.Knee.medial.y = walking_direction*trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).y;
%     interpolated_Markers.Knee.medial.z = trajectories.(markers_guide.reference_guide{foot + " Medial Knee"}{1}).z;
% 
%     % Cut the ankle markers data from IC to OIC and temporally align it to 101 points :
%     interpolated_Markers.Ankle.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Ankle.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Ankle.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Ankle.medial.x = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Ankle.medial.y = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Ankle.medial.z = interp1(IC_index:OIC_index, interpolated_Markers.Ankle.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
% 
%     % Calculate mean ankle marker from medial and lateral
%     interpolated_Markers.Ankle.mean.x = (interpolated_Markers.Ankle.lateral.x + interpolated_Markers.Ankle.medial.x)/2;
%     interpolated_Markers.Ankle.mean.y = (interpolated_Markers.Ankle.lateral.y + interpolated_Markers.Ankle.medial.y)/2;
%     interpolated_Markers.Ankle.mean.z = (interpolated_Markers.Ankle.lateral.z + interpolated_Markers.Ankle.medial.z)/2;
% 
%     % Cut the knee markers data from IC to OIC and temporally align it to 101 points :
%     interpolated_Markers.Knee.lateral.x = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Knee.lateral.y = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Knee.lateral.z = interp1(IC_index:OIC_index, interpolated_Markers.Knee.lateral.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Knee.medial.x = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Knee.medial.y = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
%     interpolated_Markers.Knee.medial.z = interp1(IC_index:OIC_index, interpolated_Markers.Knee.medial.z(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
% 
%     % Calculate mean knee marker from medial and lateral
%     interpolated_Markers.Knee.mean.x = (interpolated_Markers.Knee.lateral.x + interpolated_Markers.Knee.medial.x)/2;
%     interpolated_Markers.Knee.mean.y = (interpolated_Markers.Knee.lateral.y + interpolated_Markers.Knee.medial.y)/2;
%     interpolated_Markers.Knee.mean.z = (interpolated_Markers.Knee.lateral.z + interpolated_Markers.Knee.medial.z)/2;
% 
%     interpolated_Markers.unit = "mm";
%     interpolated_Markers.temporal_alignment = "Initial contact to opposite initial contact.";
% end



function [mean_right_leg_length, mean_left_leg_length, mean_right_thigh_length, mean_left_thigh_length, mean_right_shank_length, mean_left_shank_length] = get_lengths(participant_data, markers_guide)
%GET_LENGTHS gives the lengths of the leg, thigh and shank of each side by
% calculating the median distance between the relevant markers for all
% trials.
% Input:
%   participant_data - the raw data struct object of the participant.
%   markers_guide - the reference guide to the marker names.

    relevant_markers = markers_guide.reference_guide;

    % get available speeds
    available_speeds = zeros(1, 7);
    counter = 0;
    for speed_category=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed_category))) > 1
            counter = counter + 1;
            available_speeds(counter) = speed_category;
        end
    end
    available_speeds = available_speeds(1:counter);

    % run on all the available speeds:
    trials_counter = 0;
    right_leg_lengths_vector = zeros(1, length(available_speeds)*10);
    left_leg_lengths_vector = zeros(1, length(available_speeds)*10);
    right_thigh_lengths_vector = zeros(1, length(available_speeds)*10);
    left_thigh_lengths_vector = zeros(1, length(available_speeds)*10);
    right_shank_lengths_vector = zeros(1, length(available_speeds)*10);
    left_shank_lengths_vector = zeros(1, length(available_speeds)*10);
    for speed_category=available_speeds
        trajectories_data = participant_data.("V" + speed_category).Trajectories;
        available_num_trials = length(trajectories_data);
        for num_trial=1:available_num_trials
            trials_counter = trials_counter + 1;

            % calculate the lengths:
            % left_ankle  -  left lateral ankle
            % left_knee   -  left lateral knee
            % left_asis   -  left ASIS
            % right_ankle -  right lateral ankle
            % right_knee  -  right lateral knee
            % right_asis  -  right ASIS
            right_asis = [single_trial_trajectories_data.(relevant_markers{"Right ASIS"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right ASIS"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right ASIS"}{3})'];
            left_asis = [single_trial_trajectories_data.(relevant_markers{"Left ASIS"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left ASIS"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left ASIS"}{3})'];
            right_ankle = [single_trial_trajectories_data.(relevant_markers{"Right Lateral Ankle"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right Lateral Ankle"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right Lateral Ankle"}{3})'];
            left_ankle = [single_trial_trajectories_data.(relevant_markers{"Left Lateral Ankle"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left Lateral Ankle"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left Lateral Ankle"}{3})'];
            right_knee = [single_trial_trajectories_data.(relevant_markers{"Right Lateral Knee"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right Lateral Knee"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Right Lateral Knee"}{3})'];
            left_knee = [single_trial_trajectories_data.(relevant_markers{"Left Lateral Knee"}{1})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left Lateral Knee"}{2})'; ...
                single_trial_trajectories_data.(relevant_markers{"Left Lateral Knee"}{3})'];

            right_leg_length = PROST.utils.convert_units(vecnorm(right_asis - right_ankle), "mm", "m");
            left_leg_length = PROST.utils.convert_units(vecnorm(left_asis - left_ankle), "mm", "m");
            right_thigh_length = PROST.utils.convert_units(vecnorm(right_asis - right_knee), "mm", "m");
            left_thigh_length = PROST.utils.convert_units(vecnorm(left_asis - left_knee), "mm", "m");
            right_shank_length = PROST.utils.convert_units(vecnorm(right_knee - right_ankle), "mm", "m");
            left_shank_length = PROST.utils.convert_units(vecnorm(left_knee - left_ankle), "mm", "m");

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
    mean_right_leg_length = median(right_leg_lengths_vector);
    mean_left_leg_length = median(left_leg_lengths_vector);
    mean_right_thigh_length = median(right_thigh_lengths_vector);
    mean_left_thigh_length = median(left_thigh_lengths_vector);
    mean_right_shank_length = median(right_shank_lengths_vector);
    mean_left_shank_length = median(left_shank_lengths_vector);
end