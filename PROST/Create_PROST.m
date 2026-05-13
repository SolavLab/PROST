clearvars -except -regexp ^Dataset_\d+$
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
toolbox_root = fileparts(script_full_path); % Get the folder of the script
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 
warning('off', 'backtrace')

%% Load Datasets
db_list = ["Dataset_1", fullfile(dataset_dir, "Dataset_1.mat"); ...
           "Dataset_2", fullfile(dataset_dir, "Dataset_2.mat"); ...
           "Dataset_3", fullfile(dataset_dir, "Dataset_3.mat"); ...
           "Dataset_4", fullfile(dataset_dir, "Dataset_4.mat")];

var_names = db_list(:, 1);
for index = 1:length(var_names)
    if ~exist(var_names(index), "var")
        load(db_list(index, 2))
    end
end

%% Create Load List
%   load_list - a cell array where each row contains pairs of dataset name and 
%               path to the dataset. Example:
%               {"Dataset 1 Name", "path/to/Dataset1.mat"; "Dataset 2 Name", "path/to/Dataset2.mat"}
load_list = {Dataset_1, "Dataset 1"; ...
             Dataset_2, "Dataset 2"; ... 
             Dataset_3, "Dataset 3"; ...
             Dataset_4, "Dataset 4"};
n_datasets = size(load_list, 1);

%% Create ROS analysis object
[PROSTAnalyzer, dataset_ids] = PROST.PROSTAnalyzer(load_list, toolbox_root);
Dataset_1_ID = dataset_ids(1);
Dataset_2_ID = dataset_ids(2);
Dataset_3_ID = dataset_ids(3);
Dataset_4_ID = dataset_ids(4);

%% Clean data
% Some participants have bad data and should be ignored so we add them to an
% ignored list (mislabeled markers, faulty measurement etc.)
% We also filter out steps where the measurement resulted in a long toe-to-heel
% step in the shank-CS.
ignore_list = PROST.PROSTDatasetList();
ignore_list.add_to_list(Dataset_1_ID, 3, 63, "Left"); % Mislabeled markers or axes
ignore_list.add_to_list(Dataset_1_ID, 5, 69, "Left"); % Mislabeled markers or axes
ignore_list.add_to_list(Dataset_1_ID, 5, 138, "Right"); % Mislabeled markers or axes
ignore_list.add_to_list(Dataset_1_ID, 15, [], "Left"); % Mislabeled markers or axes
ignore_list.add_to_list(Dataset_1_ID, 15, [], "Right"); % Mislabeled markers or axes
% ignore_list.add_to_list(Dataset_1_ID, [3 5 14 15 16], [], "Left");
% ignore_list.add_to_list(Dataset_1_ID, [5 14 15 16], [], "Right");
% ignore_list.add_to_list(Dataset_2_ID, [31], [], "Left");
ignore_list.add_to_list(Dataset_3_ID, [43, 47], [], "Left"); % Flat step (large\negative outlier radius)
PROSTAnalyzer.clean_data(ignore_list);

%% Add to samples table data from datasets
PROSTAnalyzer.create_samples_table();

%% Save PROST Object
fprintf("Saving PROSTAnalyzer object...\n");
save("PROSTAnalyzer.mat","PROSTAnalyzer")
fprintf("PROSTAnalyzer object saved.\n");
