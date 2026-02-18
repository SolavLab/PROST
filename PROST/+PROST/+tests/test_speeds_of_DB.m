clearvars -except DB_1 DB_2 DB_3
close all
clc

if ~exist("DB_1")
    load("../DB1/DB_1.mat")
end
if ~exist("DB_2")
    load("../DB2/DB_2.mat")
end
if ~exist("DB_3")
    load("../DB3/DB_3.mat")
end

%%
dataset_ids = [1 2 3];
speeds = [];
participants = [];
datasets = [];
participant_counter = 1;
f = figure(Name="Speeds by Participant");
colors = lines(length(dataset_ids));
hold on
grid minor
for dataset_id=dataset_ids
    % data_type = dictionary;
    if dataset_id == 1
        data = DB_1.Data;
    elseif dataset_id == 2
        data = DB_2.Data;
    elseif dataset_id == 3
        data = DB_3.Data;
    else
        continue
    end
    n_participants = length(fieldnames(data));
    for participant_number=1:n_participants
        p_name = "participant_" + participant_number;
        for side=["right", "left"]
            trials = data.(p_name).uniform_data.(side).step;
            n_trials = length(trials);
            for trial_number=1:n_trials
                speed = trials(trial_number).speed.km_per_hour.value; % [km/h]
                speeds(end + 1, :) = speed;
                participants(end + 1, :) = participant_counter;
                datasets(end + 1, :) = dataset_id;
            end
        end
        participant_counter = participant_counter + 1;
    end
    h = gscatter(participants, speeds, datasets, "rgb", "o", 5, "off", "filled");
end
xlabel("participant #")
ylabel("speed [km/h]")
title("Speeds by Participant");
legend(h, "DB" + dataset_ids)

%%
dataset_ids = [1 2 3];
speeds_for_kmeans = speeds(ismember(datasets(:), dataset_ids));
participants_for_kmeans = participants(ismember(datasets(:), dataset_ids));
max_clusters = 20;
kmeans_indices = zeros(length(speeds_for_kmeans), max_clusters);
sumdValues = zeros(max_clusters, 1);
for n_clusters = 1:max_clusters
    [kmeans_idx, ~, sumd] = kmeans(speeds_for_kmeans, n_clusters, 'Replicates', 5);
    kmeans_indices(:, n_clusters) = kmeans_idx;
    sumdValues(n_clusters) = sum(sumd);
end
figure(Name="Elbow Method for Kmeans")
plot(1:max_clusters, sumdValues, '-o')
xlabel('Number of clusters k')
ylabel('Total within-cluster distance')
title('Elbow Method')
grid minor

%%
n_clusters = 6;
[kmeans_idx, ~] = kmeans(speeds_for_kmeans, n_clusters);
clusters = cell(1, n_clusters);
figure(Name='Kmeans - Cluster Assignments')
colors = lines(n_clusters);
hold on
grid minor
mean_indices = NaN + (1:n_clusters);
gscatter(participants_for_kmeans, speeds_for_kmeans, kmeans_idx, colors, "o", 5, "filled")
legend
title('Cluster Assignments', "Datasets: " + join(string(dataset_ids), ", "));
xlabel("participant #")
ylabel("speed [km/h]")
hold off

%% Save figures
figHandles = findall(0, 'Type', 'figure');
fprintf("Saving figures...\n");
for k = 1:numel(figHandles)
    f = figHandles(k);
    filepath = "..\figures\Speeds";
    filename = sprintf('%s.png', f.Name);
    exportgraphics(f, fullfile(filepath, filename), 'Resolution',300); % 300 DPI
end