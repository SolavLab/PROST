clearvars -except -regexp ^Dataset_\d+$
close all
clc

%% Setup
script_full_path = mfilename('fullpath'); % Full path of this script (MATLAB editor, VS Code, and batch)
if isempty(script_full_path)
    script_full_path = matlab.desktop.editor.getActiveFilename; % Fallback: evaluating a selection in the MATLAB editor
end
assert(~isempty(script_full_path), "Cannot determine script location. Run the whole file rather than a selection.")
toolbox_root = fileparts(script_full_path); % Get the folder of the script
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 
warning('off', 'backtrace')

%% Load Datasets
dataset_list = ["Dataset_1"; "Dataset_2"; "Dataset_3"; "Dataset_4"];

% Datasets kept from the workspace may differ from the files on disk, so only the
% loaded files are hashed in the provenance
loaded_files = strings(0, 1);
workspace_datasets = strings(0, 1);
for idx = 1:length(dataset_list)
    var_name = dataset_list(idx);
    if ~exist(var_name, "var")
        file_name = fullfile(dataset_dir, var_name + ".mat");
        load(file_name)
        loaded_files(end+1, 1) = fullfile("example_datasets", var_name + ".mat"); %#ok<SAGROW>
    else
        workspace_datasets(end+1, 1) = var_name; %#ok<SAGROW>
    end
end

%% Create Load List
%   load_list - a cell array where each row pairs an in-memory dataset struct
%               with its name, in either order. Example:
%               {Dataset_1, "Dataset 1"; "Dataset 2", Dataset_2}
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
ignore_list.add_to_list(Dataset_1_ID, 15); % Mislabeled markers or axes
ignore_list.add_to_list(Dataset_1_ID, 14); % Mislabeled marker: left "knee" sits ~200 mm above the ankle (likely a mid-shank marker), so left shank-CS CoP is non-physiological.
ignore_list.add_to_list(Dataset_3_ID, [43, 47], [], "Left"); % Flat step (large\negative outlier radius)
PROSTAnalyzer.clean_data(ignore_list);

%% Add to samples table data from datasets
PROSTAnalyzer.create_IPD_table();

%% Save PROST Object
fprintf("Saving PROSTAnalyzer object...\n");
PROSTAnalyzer_provenance = PROST.utils.provenance(loaded_files);
PROSTAnalyzer_provenance.workspace_datasets = workspace_datasets; % used as found in the workspace, not hashed
save("PROSTAnalyzer.mat", "PROSTAnalyzer", "PROSTAnalyzer_provenance")
fprintf("PROSTAnalyzer object saved.\n");
