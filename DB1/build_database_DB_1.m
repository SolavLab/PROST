%% ------------------------------------------------------------------
%  build a matlab structure containing the first database data
%  Created by Dani Feal
%  Edited by Chen Reichsbouscher, 11.06.2025
% -------------------------------------------------------------------
%
clc; close all; clearvars -except DB_2 DB_3;

% Add data files to path
data_path = "C:\Users\chenr\Documents\PROST\DB1\Subjects_Data";
addpath(data_path);

% Add PROST package to path
addpath("C:\Users\chenr\Documents\PROST\");

%% -----------------------------
%  General Database info:
% ------------------------------
%       -------------
% DB_1 / article_data :
%       -------------
Article_data.article_name = "Lower limb kinematic, kinetic, and EMG data from young healthy humans during walking at controlled speeds";
Article_data.authors = "Luís Moreira, Joana Figueiredo, Pedro Fonseca, João P. Vilas-Boas & Cristina P. Santos";
Article_data.link_to_paper = "https://doi.org/10.1038/s41597-021-00881-3";
Article_data.link_to_dataset = "https://doi.org/10.6084/m9.figshare.c.4923162.v1";
Article_data.published_year = 2021;

DB_1.Article_data = Article_data;

%       -------------
% DB_1 / marker_names :
%       -------------
Markers_guide.explanation_txt="The field reference_guide containes a dictionary.\n"+...
    "The keys: the names we gave each marker for cohesiveness between the different databases.\n"+...
    "The values: a cell array with the data of that marker in the original database.\n"+...
    "Columns 1, 2, 3: the name of the variable in the original trajectories database for the X, Y and Z coordinates.\n"+...
    "Columns 4, 5, 6: the number of the column in the original trajectories database for the X, Y and Z coordinates.\n"+...
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
DB_1.Markers_guide = Markers_guide;

%       --------------------
% DB_1 / Lab_system :
%       --------------------
Lab_system.lab_frame.x= ...
    "For COP and marker trajectories: pointing in the direction that completes a right handed coordinate system.\n" + ...
    "for GRF data: the direction in the lab from the first forceplate to the last forceplate (walking direction).";
Lab_system.lab_frame.y= ...
    "For COP and marker trajectories: the direction in the lab from the first forceplate to the last forceplate (walking direction).\n" + ...
    "For GRF data: pointing in the direction that completes a right handed coordinate system.";
Lab_system.lab_frame.z= ...
    "For GRF, COP and marker trajectories the z direction is pointing up.";
Lab_system.num_forceplates = 6;

DB_1.Lab_system = Lab_system;

%       ---------------------
% DB_1 / Experiment_protocol :
%       ---------------------
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
Experiment_protocol.speed_categories.V1 = "V1 is a speed of 1.0 km/h.";
Experiment_protocol.speed_categories.V15 = "V15 is a speed of 1.5 km/h.";
Experiment_protocol.speed_categories.V2 = "V2 is a speed of 2.0 km/h.";
Experiment_protocol.speed_categories.V25 = "V25 is a speed of 2.5 km/h.";
Experiment_protocol.speed_categories.V3 = "V3 is a speed of 3.0 km/h.";
Experiment_protocol.speed_categories.V35 = "V35 is a speed of 3.5 km/h.";
Experiment_protocol.speed_categories.V4 = "V4 is a speed of 4.0 km/h.";
Experiment_protocol.num_participants = 16;

DB_1.Experiment_protocol = Experiment_protocol;


%% -----------------------------
%  participant specific info:
% ------------------------------
participant_numbers = 1:16;
for participant_number=participant_numbers
    % Initialize counters
    trials_counter = 0;
    left_steps_counter = 0;
    right_steps_counter = 0;

    % load the data:
    participant_id = "Participant_" + participant_number;
    participant_name = "participant_" + participant_number;
    participant_data = load(fullfile("Subjects_Data", erase(participant_id, "_"), "Raw_Data.mat"));
    participant_raw_data = participant_data.("Subject" + participant_number + "_raw");
    metadata_array = split(string(fileread(fullfile("Subjects_Data", erase(participant_id, "_"), "Metadata.txt"))));

    %                              -------------------------------------
    % DB_1 / Data / participant_# / participant_ID_in_original_structure :
    %                              -------------------------------------
    DB_1.Data.(participant_name).participant_ID_in_original_structure = participant_id;

    %                              ---------
    % DB_1 / Data / participant_# / metadata :
    %                              ---------
    % Age
    DB_1.Data.(participant_name).metadata.Age.value = double(metadata_array(4));
    DB_1.Data.(participant_name).metadata.Age.unit = "years";
    DB_1.Data.(participant_name).metadata.Age.method = "given";

    % Gender
    DB_1.Data.(participant_name).metadata.Gender.value = metadata_array(6);
    DB_1.Data.(participant_name).metadata.Gender.unit = "Male/Female";
    DB_1.Data.(participant_name).metadata.Gender.method = "given";

    % Height
    DB_1.Data.(participant_name).metadata.Height.value = double(metadata_array(9));
    DB_1.Data.(participant_name).metadata.Height.unit = "m";
    DB_1.Data.(participant_name).metadata.Height.method = "given";

    % Mass
    DB_1.Data.(participant_name).metadata.Mass.value = double(metadata_array(13));
    DB_1.Data.(participant_name).metadata.Mass.unit = "kg";
    DB_1.Data.(participant_name).metadata.Mass.method = "given";

    % Is_shod
    DB_1.Data.(participant_name).metadata.Is_shod.value = "Yes";
    DB_1.Data.(participant_name).metadata.Is_shod.unit = "Yes/No";
    DB_1.Data.(participant_name).metadata.Is_shod.method = "given";

    % Calculate leg length, thigh length and shank length
    [right_leg_length, left_leg_length, right_thigh_length, left_thigh_length, right_shank_length, left_shank_length] = get_lengths(participant_number, participant_raw_data, DB_1.Markers_guide); % [m]

    % Leg length - distance between anterior superior iliac spine (ASIS) and lateral ankle (LA)
    DB_1.Data.(participant_name).metadata.Leg_length.right.value = right_leg_length; % [m]
    DB_1.Data.(participant_name).metadata.Leg_length.left.value = left_leg_length; % [m]
    DB_1.Data.(participant_name).metadata.Leg_length.unit = "m";
    DB_1.Data.(participant_name).metadata.Leg_length.method = "calculated by median distance between markers in all trials";

    % Thigh length - distance between lateral knee (LK) and anterior superior iliac spine (ASIS)
    DB_1.Data.(participant_name).metadata.Thigh_length.right.value = right_thigh_length; % [m]
    DB_1.Data.(participant_name).metadata.Thigh_length.left.value = left_thigh_length; % [m]
    DB_1.Data.(participant_name).metadata.Thigh_length.unit = "m";
    DB_1.Data.(participant_name).metadata.Thigh_length.method = "calculated by median distance between markers in all trials";

    % Shank length - distance between lateral knee (LK) and lateral ankle (LA)
    DB_1.Data.(participant_name).metadata.Shank_length.right.value = right_shank_length; % [m]
    DB_1.Data.(participant_name).metadata.Shank_length.left.value = left_shank_length; % [m]
    DB_1.Data.(participant_name).metadata.Shank_length.unit = "m";
    DB_1.Data.(participant_name).metadata.Shank_length.method = "calculated by median distance between markers in all trials";

    % Foot length
    % DB_1.Data.(participant_name).metadata.Foot_length.right.value = double(metadata_array(21));
    % DB_1.Data.(participant_name).metadata.Foot_length.left.value = double(metadata_array(21));
    % DB_1.Data.(participant_name).metadata.Foot_length.unit = "m";
    % DB_1.Data.(participant_name).metadata.Foot_length.method = "given";

    %                               -----------------
    % DB_1 / Data / participant_# / unprocessed_data
    %                               -----------------
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
        trajectories_data = participant_raw_data.("V" + speed_category).Trajectories;
        GRF_data = participant_raw_data.("V" + speed_category).GRF;
        available_num_trials = length(COP_data);

        for num_trial=1:available_num_trials
            trials_counter = trials_counter + 1;
            trial_name = ("trial_" + trials_counter);

            %------------------------------------------------------------------------------------
            %                            unprocessed_data
            %------------------------------------------------------------------------------------
            %                                                            -------
            % DB_1 / Data / participant_# / unprocessed_data / trial(#) / origin
            %                                                            -------
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).origin.speed_catagory = "V" + speed_category;
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).origin.number_of_trial_under_speed_catagory = num_trial;
            %                                                              -----------------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / walking_direction
            %                                                              -----------------
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).walking_direction = "+y in COP and tragectories data. +x in GRF data";

            %                                                              ----------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / first_foot
            %                                                              ----------
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).first_foot = "right";

            single_trial_COP_data = COP_data{num_trial, 2};
            single_trial_GRF_data = GRF_data{num_trial, 2};
            single_trial_trajectories_data = trajectories_data{num_trial, 2};

            %                                                             ------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / Time
            %                                                             ----
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).Time.value = single_trial_COP_data.Time;
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).Time.unit = "second";
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).Sample_freq.value = 1/(single_trial_COP_data.Time(2) - single_trial_COP_data.Time(1));
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).Sample_freq.unit = "Hz";

            %                                                             -----
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / GRF
            %                                                             -----
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Left.x = single_trial_GRF_data.L_GRF_X; % walking direction
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Left.y = single_trial_GRF_data.L_GRF_Y; % not reliable, weird sometimes, pointing outside
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Left.z = single_trial_GRF_data.L_GRF_Z; % up
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Right.x = single_trial_GRF_data.R_GRF_X; % walking direction
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Right.y = single_trial_GRF_data.R_GRF_Y; % not reliable, weird sometimes, pointing outside
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.Right.z = single_trial_GRF_data.R_GRF_Z; % up
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.unit = "N";

            %                                                             ------------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / COP, events
            %                                                             ------------
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
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(forceplate_counter).x = x_cop;
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(forceplate_counter).y = y_cop;
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(forceplate_counter).z = z_cop;
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.unit = "mm";

                % Find the event indices and times
                COP_indices = 1:length(x_cop);
                COP_indices = COP_indices(~isnan(x_cop));

                % save IC
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + forceplate_counter).index = COP_indices(1);
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + forceplate_counter).time = single_trial_COP_data.Time(COP_indices(1)); % [sec]

                % save TO
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("TO" + forceplate_counter).index = COP_indices(end);
                DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("TO" + forceplate_counter).time = single_trial_COP_data.Time(COP_indices(end)); % [sec]
            end

            %                                                             -----------------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / events / method
            %                                                             -----------------
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.method = "Calculated using the COP (since it has already taken into account the unreliable values in the edges)," + ...
                " by finding the first and last index and time for which the COP is not NaN.";
            %                                                             -------------
            % DB_1 / Data / participant_# / unprocessed_data / trials(#) / trajectories
            %                                                             -------------
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).trajectories.value = single_trial_trajectories_data; % here +y is walking direction and z is up
            DB_1.Data.(participant_name).unprocessed_data.(trial_name).trajectories.unit = "mm";

            %                                                            ------
            % DB_1 / Data / participant_# / unprocessed_data / trial(#) / speed
            %                                                            ------
            IC1_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC1.index;
            IC2_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC2.index;
            IC3_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC3.index;
            IC4_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC4.index;

            IC1_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC1.time;
            IC2_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC2.time;
            IC3_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC3.time;
            IC4_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.IC4.time;

            psis.x = (single_trial_trajectories_data.(Markers_guide.reference_guide{"Right PSIS"}{1}) + single_trial_trajectories_data.(Markers_guide.reference_guide{"Left PSIS"}{1})) / 2;
            psis.y = (single_trial_trajectories_data.(Markers_guide.reference_guide{"Right PSIS"}{2}) + single_trial_trajectories_data.(Markers_guide.reference_guide{"Right PSIS"}{2})) / 2;

            distance = [vecnorm([psis.x(IC3_index); psis.y(IC3_index)] - [psis.x(IC1_index); psis.y(IC1_index)]); ... % [mm]
                vecnorm([psis.x(IC4_index); psis.y(IC4_index)] - [psis.x(IC2_index); psis.y(IC2_index)])];    % [mm]
            distance = PROST.utils.convert_units(distance, "mm", "m");
            speed = distance ./ [(IC3_time - IC1_time); (IC4_time - IC2_time)];
            mean_speed = mean(speed); % [m/s]

            speed_structure.m_per_sec.value = mean_speed;
            speed_structure.m_per_sec.unit = "m/sec";
            speed_structure.m_per_sec.method = ...
                "For each foot, calculated the distance traveled of the mean PSIS marker divided by the time between two consecutive foot strikes of that foot.\n" + ...
                "Then calculated the mean speed of both feet.";

            speed_structure.km_per_hour.value = PROST.utils.convert_units(PROST.utils.convert_units(speed_structure.m_per_sec.value, "m", "km"), "hour", "second");
            speed_structure.km_per_hour.unit="km/hour";
            speed_structure.km_per_hour.method="calculated by" + ...
                "For each foot, calculated the distance traveled divided by the time between two consecutive foot strikes of that foot.\n" + ...
                "Then calculated the mean speed of both feet.\n" + ...
                "Converted from [m/sec] to [km/hr]";

            speed_structure.given_speed.value = (speed_category >= 10)*(speed_category/10) + (speed_category < 10)*speed_category;
            speed_structure.given_speed.unit = "km/h";

            DB_1.Data.(participant_name).unprocessed_data.(trial_name).speed = speed_structure;

            %------------------------------------------------------------------------------------
            %                            processed_data
            %------------------------------------------------------------------------------------
            %                              ---------------- --------------- --------
            % DB_1 / Data / participant_# / processed_data / right or left / step(#)
            %                              ---------------- --------------- --------
            % reminder:
            % the frame of reference of the given (unprocessed) markers and COP:
            % x - right direction
            % y - walking direction
            % z - up
            % the frame of reference of the given (unprocessed) GRF:
            % x - walking direction
            % y - the medial direction?
            % z - up
            % ---------------------------------------------
            % in processed data, the markers and COP data should be transformed so that:
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
            % while the COP and markers should be temporally aligned (to 101 points) in the weight accpentance + single support phase (SS) -> from initial contact to opposite initial contact

            % Saving data of 3 steps
            % We have the data of 4 steps per trial but since OIC isn't known,
            % we use the IC time of the subsequent step.
            for step_number=1:3
                % Get event indices and times
                IC_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + step_number).index;
                IC_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + step_number).time;
                TO_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("TO" + step_number).index;
                TO_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("TO" + step_number).time;
                OIC_index = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + (step_number + 1)).index;
                OIC_time = DB_1.Data.(participant_name).unprocessed_data.(trial_name).events.("IC" + (step_number + 1)).time;
                
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
                
                %                                                                      -------
                % DB_1 / Data / participant_# / processed_data / right,left / step(#) / source
                %                                                                      -------
                %                                                                               ----------------------------------
                %                                                                              / original_trial_number_in_database
                %                                                                               ----------------------------------
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_trial_number_in_database = trials_counter;
                %                                                                               ---------------
                %                                                                              / original_trial
                %                                                                               ---------------
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_trial = "V" + speed_category + "_" + num_trial;
                %                                                                               ------------
                %                                                                              / step_number
                %                                                                               ------------
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.step_number = step_number;
                %                                                                               -------------
                %                                                                              / Plate_number
                %                                                                               -------------
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.plate_number = step_number + 1;

                % original IC,OIC,and TO: index and time
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_IC.forceplate_index = IC_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_OIC.forceplate_index = OIC_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_TO.forceplate_index = TO_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_IC.trajectory_index = IC_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_OIC.trajectory_index = OIC_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_TO.trajectory_index = TO_index;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_IC.time = IC_time;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_OIC.time = OIC_time;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).source.original_TO.time = TO_time;
                % --------------------------------------------------------------

                % Size of temporal alignment. We want 101 points so data is in
                % percentage of stance phase \ single support phase.
                n_temporal_alignment = 101;

                %                                                                      ----------------------------
                % DB_1 / Data / participant_# / processed_data / Right,Left / step(#) / COP   -  temporally aligned
                %                                                                      ----------------------------

                % transform the original y to be x now (so x will be the walking direction)
                % and the original x to be the new -y (so the z direction will still point up)
                one_step_COP.x = DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(step_number).y;
                one_step_COP.y = -DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(step_number).x;
                one_step_COP.z = DB_1.Data.(participant_name).unprocessed_data.(trial_name).COP.FP(step_number).z;

                % cut the COP data from IC to OIC (weight accetnace + single support) and interpolate it to 101 points
                original_indices = 1:length(one_step_COP.x);
                original_indices = original_indices(~isnan(one_step_COP.x));
                interpolated_COP.x = interp1(IC_index:OIC_index, one_step_COP.x(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.y = interp1(IC_index:OIC_index, one_step_COP.y(IC_index:OIC_index), linspace(IC_index, OIC_index, n_temporal_alignment));
                interpolated_COP.z = NaN(size(interpolated_COP.x));
                interpolated_COP.unit = "mm";
                interpolated_COP.temporal_alignment = "weight acceptance + single support";
                interpolated_COP.IC_index = 1;
                interpolated_COP.OIC_index = n_temporal_alignment;

                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).COP = interpolated_COP;

                %                                                                      ----------------------------
                % DB_1 / Data / participant_# / processed_data / Right,Left / step(#) / GRF   -  temporally aligned
                %                                                                      ----------------------------

                % the original x axis stays as x as this is the walking direction
                one_step_GRF.x = DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.(foot).x;

                % the original z axis stays as z as this is the direction pointing up
                one_step_GRF.z = DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.(foot).z;

                % y on the other hand, was always pointing inwards in the original data.
                % in the other hand in order to comply with the right hand rule
                %                          Z * X = Y
                % and with the directions of the x axis and z axis
                % the y axis should be pointing to the Left!
                % so for steps 1 and 3 (right foot), the GRF should stay the same
                % but for steps 2 and 4 (left foot), the direction of the GRF needs to be flipped.
                one_step_GRF.y = (-1)^(step_number + 1) .* DB_1.Data.(participant_name).unprocessed_data.(trial_name).GRF.(foot).y;

                % cut the GRF data from IC to TO and interpolate it to 101 points :
                interpolated_GRF.x = interp1(IC_index:TO_index, one_step_GRF.x(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.y = interp1(IC_index:TO_index, one_step_GRF.y(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.z = interp1(IC_index:TO_index, one_step_GRF.z(IC_index:TO_index), linspace(IC_index, TO_index, n_temporal_alignment));
                interpolated_GRF.unit = "N";
                interpolated_GRF.temporal_alignment = "stance phase";
                interpolated_GRF.IC_index = 1;
                interpolated_GRF.OIC_index = round(n_temporal_alignment*(OIC_index - IC_index)/(TO_index - IC_index));
                interpolated_GRF.TO_index = n_temporal_alignment;

                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).GRF = interpolated_GRF;

                %                                                                      --------------------------------
                % DB_1 / Data / participant_# / processed_data / Right,Left / step(#) / Markers   -  temporally aligned
                %                                                                      --------------------------------
                % first we need to decide what markers interest us:
                % we will store the data of the medial and lateral ankle markers
                %                    and of the medial and lateral knee markers
                % and the mean between the medial and lateral markers (for the center of the ankle and the knee)
                % get the markers data
                trajectories = DB_1.Data.(participant_name).unprocessed_data.(trial_name).trajectories;
                % For the ankle
                one_step_Markers.Ankle.lateral.x = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{2});
                one_step_Markers.Ankle.lateral.y = -trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{1});
                one_step_Markers.Ankle.lateral.z = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Ankle"}{3});
                one_step_Markers.Ankle.medial.x = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{2});
                one_step_Markers.Ankle.medial.y = -trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{1});
                one_step_Markers.Ankle.medial.z = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Ankle"}{3});

                % For the knee
                one_step_Markers.Knee.lateral.x = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{2});
                one_step_Markers.Knee.lateral.y = -trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{1});
                one_step_Markers.Knee.lateral.z = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Lateral Knee"}{3});
                one_step_Markers.Knee.medial.x = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Knee"}{2});
                one_step_Markers.Knee.medial.y = -trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Knee"}{1});
                one_step_Markers.Knee.medial.z = trajectories.value.(DB_1.Markers_guide.reference_guide{foot + " Medial Knee"}{3});

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
                interpolated_Markers.temporal_alignment = "weight acceptance + single support";
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).Markers = interpolated_Markers;

                %                                                                       ------
                % DB_1 / Data / participant_# / processed_data / Right,Left / step(#) / speed
                %                                                                       ------
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).speed.m_per_sec = speed_structure.m_per_sec;
                DB_1.Data.(participant_name).processed_data.(side).step(relevant_index).speed.km_per_hour = speed_structure.km_per_hour;
            end
        end
    end

    % Add foot length estimation to metadata.
    % right_steps = DB_1.Data.(participant_name).processed_data.right.step;
    % estimated_foot_length_right = PROST.utils.estimate_foot_length(right_steps);
    % left_steps = DB_1.Data.(participant_name).processed_data.left.step;
    % estimated_foot_length_left = PROST.utils.estimate_foot_length(left_steps);
    % DB_1.Data.(participant_name).metadata.Estimated_foot_length.right.value = estimated_foot_length_right;
    % DB_1.Data.(participant_name).metadata.Estimated_foot_length.left.value = estimated_foot_length_left;
    % DB_1.Data.(participant_name).metadata.Estimated_foot_length.unit = "m";
    % DB_1.Data.(participant_name).metadata.Estimated_foot_length.method = "calculated from average COP in walking direction which is 0.83 of foot length.";
end

save("DB_1.mat","DB_1")

function [median_right_leg_length, median_left_leg_length, median_right_thigh_length, median_left_thigh_length, median_right_shank_length, median_left_shank_length] = get_lengths(participant_number, participant_data, markers_guide)
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
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed))) > 1
            counter = counter + 1;
            available_speeds(counter) = speed;
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
    for speed=available_speeds
        trajectories_data = participant_data.("V" + speed).Trajectories;
        available_num_trials = length(trajectories_data);
        for num_trial=1:available_num_trials
            if participant_number == 16 && speed == 25 && (num_trial == 5 || num_trial == 6 || num_trial == 7 || num_trial == 8 || num_trial == 9)
                continue
            end
            trials_counter = trials_counter + 1;

            % get the data of this single trial:
            single_trial_trajectories_data = trajectories_data{num_trial, 2};

            % calculate the lengths:
            time = single_trial_trajectories_data.Time;

            % left ankle  -  [LLAX,   LLAY,   LLAZ]   -  left lateral ankle x
            % left knee   -  [LLKX,   LLKY,   LLKZ]   -  left lateral knee x
            % left ASIS   -  [LASISX, LASISY, LASISZ] -  left ASIS x
            % right ankle -  [RLAX,   RLAY,   RLAZ]   -  right lateral ankle x
            % right knee  -  [RLKX,   RLKY,   RLKZ]   -  right lateral knee x
            % right ASIS  -  [RASISX, RASISY, RASISZ] -  right ASIS x
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