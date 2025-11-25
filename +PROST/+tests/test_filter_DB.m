close all
clc

%   load_list - a cell array where each row contains pairs of dataset name and 
%               path to the dataset. Example:
%               {"DB 1 Name", "path/to/DB1.mat"; "DB 2 Name", "path/to/DB2.mat"}
load_list = {DB_1, "Moreira et. al. (2021)"; DB_2, "Schreiber & Moissenet (2019)"; DB_3, "Lencioni et. al. (2019)"};
n_datasets = size(load_list, 1);

[obj, dataset_ids] = ROSAnalyzer.ROSAnalyzer(load_list);
DB_1_ID = dataset_ids(1);
DB_2_ID = dataset_ids(2);
DB_3_ID = dataset_ids(3);

%% Check One Trials of One Participant
dataset_id = DB_2_ID; % Schreiber & Moissenet (2019)
dataset = obj.get_dataset(dataset_id);
participant_id = 1;
trial_num = 1;
side = "left";
participant_name = dataset.Data(participant_id).Participant_name;

step = dataset.Data(participant_id).Processed_data.(side).step(trial_num);
shank_cop = step.Shank_cop;
x = shank_cop.x(~isnan(shank_cop.x));
y = shank_cop.y(~isnan(shank_cop.y));
z = shank_cop.z(~isnan(shank_cop.z));
dz_dx = (diff(z)./diff(x));
dx = (diff(x));

figure
tiledlayout
sgtitle(sprintf("P%d (%s) Step: %d %s", participant_id, participant_name, trial_num, side))

nexttile
scatter(x, z, 30, 1:length(x), '^', 'filled')
hold on
axis equal
grid on
xlabel("x [mm]")
ylabel("z [mm]")

nexttile
scatter(1:length(dz_dx), dz_dx, 30, 1:length(dz_dx), '^', 'filled')
hold on
yline(0, 'k', LineWidth=3)
grid on
xlabel("index")
ylabel("dz/dx [mm]")

nexttile
scatter(1:length(x), x, 30, 1:length(x), '^', 'filled')
hold on
axis equal
grid on
xlabel("index")
ylabel("x [mm]")

nexttile
scatter(1:length(dx), dx, 30, 1:length(dx), '^', 'filled')
hold on
yline(0, 'k', LineWidth=3)
grid on
xlabel("index")
ylabel("dx [mm]")

%% Check All Trials of One Participant
dataset_id = DB_1_ID;
dataset = obj.get_dataset(dataset_id);
participant_id = 24;
participant_name = dataset.Data(participant_id).Participant_name;
for side = ["right"]
    trials = dataset.Data(participant_id).Processed_data.(side).step;
    n_trials = length(trials);
    for trial_num=1:n_trials
        step = trials(trial_num);
        trial_name = step.source.original_trial;
        shank_cop = step.Shank_cop;
        
        figure
        tiledlayout(2,2)
        sgtitle(sprintf("P%d (%s) %s, T%d (%s)\n", participant_id, participant_name, side, trial_num, replace(trial_name, "_", " ")))
        
        x = shank_cop.x(~isnan(shank_cop.x));
        y = shank_cop.y(~isnan(shank_cop.y));
        z = shank_cop.z(~isnan(shank_cop.z));
        dz_dx = (diff(z)./diff(x));
        dx = (diff(x));

        nexttile
        scatter(x, z, 30, 1:length(x), '^', 'filled')
        hold on
        axis equal
        grid on
        xlabel("x [mm]")
        ylabel("z [mm]")
    
        nexttile
        scatter(1:length(dz_dx), dz_dx, 30, 1:length(dz_dx), '^', 'filled')
        hold on
        yline(0, 'k', LineWidth=3)
        grid on
        xlabel("index")
        ylabel("dz/dx [mm]")
    
        nexttile
        scatter(1:length(x), x, 30, 1:length(x), '^', 'filled')
        hold on
        axis equal
        grid on
        xlabel("index")
        ylabel("x [mm]")
       
        nexttile
        scatter(1:length(dx), dx, 30, 1:length(dx), '^', 'filled')
        hold on
        yline(0, 'k', LineWidth=3)
        grid on
        xlabel("index")
        ylabel("dx [mm]")
    end
end

%% Filter Bad Trials
clearvars bad_trials
bad_trials = [];
bad_sides = [];
bad_participants = [];
n_participants = length(participants);
for participant_id=1:n_participants
    participant_name = dataset.Data(participant_id).Participant_name;
    for side=["left" "right"]
        trials = dataset.Data(participant_id).Processed_data.(side).step;
        n_trials = length(trials);
        for trial_num=1:n_trials
            step = trials(trial_num);
            trial_name = step.source.original_trial;
            shank_cop = step.Shank_cop;

            x = shank_cop.x(~isnan(shank_cop.x));
            y = shank_cop.y(~isnan(shank_cop.y));
            z = shank_cop.z(~isnan(shank_cop.z));
            dz_dx = (diff(z)./diff(x));
            dx = diff(x);
            sign_d = sign(dx);
            idx_switch = find(diff(sign_d) ~= 0);
            if isempty(idx_switch) 
                if sign_d(1) < 0
                    fprintf("P%d (%s) %s, T%d (%s) **** +1\n", participant_id, participant_name, side, trial_num, replace(trial_name, "_", " "))
                end
                continue
            else
                idx_switch = [0 idx_switch];
                idx_switch = [idx_switch length(sign_d)];
                k=1:length(idx_switch)-1;
                if  any(sign_d(idx_switch(k) + 1) < 0 & idx_switch(k + 1) - idx_switch(k) > 10)
                    fprintf("P%d (%s) %s, T%d (%s)\n", participant_id, participant_name, side, trial_num, replace(trial_name, "_", " "))
                    bad_trials = [bad_trials trial_num];
                    bad_sides = [bad_sides side];
                    bad_participants = [bad_participants participant_id];
                end
            end
        end
    end
end

%% Check Filtered Trials
for i=1:length(bad_trials)
    participant_id = bad_participants(i);
    side = bad_sides(i);
    trial_num = bad_trials(i);

    participant_name = dataset.Data(participant_id).Participant_name;
    step = dataset.Data(participant_id).Processed_data.(side).step(trial_num);
    trial_name = step.source.original_trial;
    shank_cop = step.Shank_cop;

    figure
    tiledlayout(2,2)
    sgtitle(sprintf("P%d (%s) %s, T%d (%s)\n", participant_id, participant_name, side, trial_num, replace(trial_name, "_", " ")))

    x = shank_cop.x(~isnan(shank_cop.x));
    y = shank_cop.y(~isnan(shank_cop.y));
    z = shank_cop.z(~isnan(shank_cop.z));
    dz_dx = (diff(z)./diff(x));
    dx = (diff(x));

    nexttile
    scatter(x, z, 30, 1:length(x), '^', 'filled')
    hold on
    axis equal
    grid on
    xlabel("x [mm]")
    ylabel("z [mm]")

    nexttile
    scatter(1:length(dz_dx), dz_dx, 30, 1:length(dz_dx), '^', 'filled')
    hold on
    yline(0, 'k', LineWidth=3)
    grid on
    xlabel("index")
    ylabel("dz_dx [mm]")

    nexttile
    scatter(1:length(x), x, 30, 1:length(x), '^', 'filled')
    hold on
    axis equal
    grid on
    xlabel("index")
    ylabel("x [mm]")

    nexttile
    scatter(1:length(dx), dx, 30, 1:length(dx), '^', 'filled')
    hold on
    yline(0, 'k', LineWidth=3)
    grid on
    xlabel("index")
    ylabel("dx [mm]")
end