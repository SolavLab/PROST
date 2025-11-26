clearvars -except DB_1 DB_2 DB_3
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
toolbox_root = fileparts(script_full_path); % Get the folder of the script
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%% Build data
db_list = ["DB_1", fullfile(dataset_dir, "DB_1.mat"); "DB_2", fullfile(dataset_dir, "DB_2.mat"); "DB_3", fullfile(dataset_dir, "DB_3.mat")];

var_names = db_list(:, 1);
for index = 1:length(var_names)
    if ~exist(var_names(index), "var")
        load(db_list(index, 2))
    end
end
 
clearvars -except DB_1 DB_2 DB_3
close all 
clc

%% Load and ignore lists
%   load_list - a cell array where each row contains pairs of dataset name and 
%               path to the dataset. Example:
%               {"DB 1 Name", "path/to/DB1.mat"; "DB 2 Name", "path/to/DB2.mat"}
load_list = {DB_1, "Moreira et. al. (2021)"; DB_2, "Schreiber & Moissenet (2019)"; DB_3, "Lencioni et. al. (2019)"};
n_datasets = size(load_list, 1);

%% Create ROS analysis object
[PROSTObj, dataset_ids] = PROST.PROSTAnalyzer(load_list);
DB_1_ID = dataset_ids(1);
DB_2_ID = dataset_ids(2);
DB_3_ID = dataset_ids(3);

%% Clean data
% Some participants have bad data and should be ignored so we add them to an
% ignored list
ignore_list = PROST.PROSTIgnore();
ignore_list.add_ignored(DB_1_ID, [3 5 14 15 16], [], "Left");
ignore_list.add_ignored(DB_1_ID, [5 14 15 16], [], "Right");
ignore_list.add_ignored(DB_2_ID, [31], [], "Left");
ignore_list.add_ignored(DB_3_ID, [43, 47], [], "Left");

PROSTObj.clean_data(ignore_list);

%% Add to samples table data from datasets
for index=1:n_datasets
    dataset_name = PROSTObj.get_dataset_name(dataset_ids(index));
    PROSTObj.add_samples(dataset_ids(index));
end

%% Save PROST Object
save("PROSTObj.mat","PROSTObj")