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
    Dataset_1.Data.(participant_name).participant_ID_in_original_structure = string(participant_ID);

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
function [median_right_leg_length, median_left_leg_length, median_right_thigh_length, median_left_thigh_length, median_right_shank_length, median_left_shank_length] = get_lengths(participant_data, markers_guide)
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

            % get the data of this single trial:
            single_trial_trajectories_data = trajectories_data{num_trial, 2};

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
    median_right_leg_length = median(right_leg_lengths_vector);
    median_left_leg_length = median(left_leg_lengths_vector);
    median_right_thigh_length = median(right_thigh_lengths_vector);
    median_left_thigh_length = median(left_thigh_lengths_vector);
    median_right_shank_length = median(right_shank_lengths_vector);
    median_left_shank_length = median(left_shank_lengths_vector);
end