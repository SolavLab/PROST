function [median_right_thigh_length, median_left_thigh_length, median_right_shank_length, median_left_shank_length] = get_lengths(participant_number)
    % Input:
    % participant_number - a number between 1 and 16
% -----------------------------------------------
    % Set default values if inputs are not specified
    if nargin < 1
        participant_number = 1;
    end
    % load the data:
    participant_Data=load('Subjects_Data\Participant'+string(participant_number)+'\Raw_Data.mat');
    participant_raw_Data=participant_Data.("Subject"+string(participant_number)+"_raw");
    %get available speeds
    available_speeds=zeros(1,7);
    counter=0;
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_raw_Data.("V"+string(speed))))>1 % <- <- <- <- <- <- <- <- <- <- <- <- <- <- Important command!
            counter=counter+1;                                            %                               how to get the number of fields in a structure
            available_speeds(counter)=speed;                              %                              and the names of all the fields in the structure
        end
    end
    available_speeds=available_speeds(1:counter);
    % run on all the available speeds:
    trials_counter=0;
    right_thigh_lengths_vector = zeros(1,100);
    left_thigh_lengths_vector = zeros(1,100);
    right_shank_lengths_vector = zeros(1,100);
    left_shank_lengths_vector = zeros(1,100);
    for speed = available_speeds
        trajectories_data=participant_raw_Data.("V"+string(speed)).Trajectories;
        available_num_trials=length(trajectories_data);
        for num_trial=1:available_num_trials
            if (participant_number==16)&&(speed==25)&&((num_trial==5)||(num_trial==6)||(num_trial==7)||(num_trial==8)||(num_trial==9))
                continue
            end
            trials_counter = trials_counter + 1;
            % get the data of this singal trial:
            singal_trial_trajectories_data=trajectories_data{num_trial,2};
            % calculate the lengths:
            time = singal_trial_trajectories_data.Time;
            % left ankle  -  [LLAX,   LLAY,   LLAZ]   -  left latteral ankle x
            % left knee   -  [LLKX,   LLKY,   LLKZ]   -  left latteral knee x
            % left hip    -  [LTROCX, LTROCY, LTROCZ] -  left TROC x
            % right ankle -  [RLAX,   RLAY,   RLAZ]   -  right latteral ankle x
            % right knee  -  [RLKX,   RLKY,   RLKZ]   -  right latteral knee x
            % right hip   -  [RTROCX, RTROCY, RTROCZ] -  right TROC x
            n = length(time);
            right_thigh_length = zeros(1,n);
            right_shank_length = zeros(1,n);
            left_thigh_length = zeros(1,n);
            left_shank_length = zeros(1,n);
            for i = 1:n
                right_thigh_length(i) = norm([ singal_trial_trajectories_data.RTROCX(i) - singal_trial_trajectories_data.RLKX(i);...
                                               singal_trial_trajectories_data.RTROCY(i) - singal_trial_trajectories_data.RLKY(i);...
                                               singal_trial_trajectories_data.RTROCZ(i) - singal_trial_trajectories_data.RLKZ(i)]); % [mm]
                left_thigh_length(i)  = norm([ singal_trial_trajectories_data.LTROCX(i) - singal_trial_trajectories_data.LLKX(i);...
                                               singal_trial_trajectories_data.LTROCY(i) - singal_trial_trajectories_data.LLKY(i);...
                                               singal_trial_trajectories_data.LTROCZ(i) - singal_trial_trajectories_data.LLKZ(i)]); % [mm]
                right_shank_length(i) = norm([ singal_trial_trajectories_data.RLAX(i) - singal_trial_trajectories_data.RLKX(i);...
                                               singal_trial_trajectories_data.RLAY(i) - singal_trial_trajectories_data.RLKY(i);...
                                               singal_trial_trajectories_data.RLAZ(i) - singal_trial_trajectories_data.RLKZ(i)]); % [mm]
                left_shank_length(i)  = norm([ singal_trial_trajectories_data.LLAX(i) - singal_trial_trajectories_data.LLKX(i);...
                                               singal_trial_trajectories_data.LLAY(i) - singal_trial_trajectories_data.LLKY(i);...
                                               singal_trial_trajectories_data.LLAZ(i) - singal_trial_trajectories_data.LLKZ(i)]); % [mm]
            end
            right_thigh_length = right_thigh_length/1000; % [m]
            left_thigh_length = left_thigh_length/1000; % [m]
            right_shank_length = right_shank_length/1000; % [m]
            left_shank_length = left_shank_length/1000; % [m]
            % save medians
            right_thigh_lengths_vector(trials_counter) = median(right_thigh_length);
            left_thigh_lengths_vector(trials_counter) = median(left_thigh_length);
            right_shank_lengths_vector(trials_counter) = median(right_shank_length);
            left_shank_lengths_vector(trials_counter) = median(left_shank_length);
        end
    end
    right_thigh_lengths_vector = right_thigh_lengths_vector(1:trials_counter);
    left_thigh_lengths_vector = left_thigh_lengths_vector(1:trials_counter);
    right_shank_lengths_vector = right_shank_lengths_vector(1:trials_counter);
    left_shank_lengths_vector = left_shank_lengths_vector(1:trials_counter);
    median_right_thigh_length = median(right_thigh_lengths_vector);
    median_left_thigh_length = median(left_thigh_lengths_vector);
    median_right_shank_length = median(right_shank_lengths_vector);
    median_left_shank_length = median(left_shank_lengths_vector);
end