clearvars -except -regexp ^Dataset_\d+$
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder); % Change to folder of current script

toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets

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
             Dataset_3, "Dataset 3"};
n_datasets = size(load_list, 1);

%% Create ROS analysis object
[PROSTAnalyzer1, dataset_ids1] = PROST.PROSTAnalyzer(load_list, toolbox_root);
Dataset_1_ID = dataset_ids1(1);
Dataset_2_ID = dataset_ids1(2);
Dataset_3_ID = dataset_ids1(3);

% [PROSTAnalyzer2, dataset_ids2] = PROST.PROSTAnalyzer();
[PROSTAnalyzer2, dataset_ids2] = PROST.PROSTAnalyzer({}, toolbox_root);

%% Test Preloaded PROSTAnalyzer Object
for idx=1:length(dataset_ids1)
    dataset_id = dataset_ids1(idx);
    dataset_to_load_name = load_list{idx, 2};
    dataset_to_load = load_list{idx, 1};
    test_loaded_dataset(PROSTAnalyzer1, dataset_to_load_name, dataset_to_load, dataset_id)
    test_summary_table(PROSTAnalyzer1, dataset_to_load_name, dataset_to_load, dataset_id)
end

%% Test empty PROSTAnalyzer Object
assert(isempty(PROSTAnalyzer2.DataRecords))
assert(isempty(PROSTAnalyzer2.SummaryTable))
assert(PROSTAnalyzer2.SummaryTableSize == 0)

%% Test Empty IPD Table
assert(isempty(PROSTAnalyzer2.IPDTable))
assert(PROSTAnalyzer2.IPDTableSize == 0)
assert(isempty(PROSTAnalyzer1.IPDTable))
assert(PROSTAnalyzer1.IPDTableSize == 0)

%% Test Add Dataset
Dataset_4_ID_1 = test_add_dataset(PROSTAnalyzer1, "Dataset 4", Dataset_4);
Dataset_4_ID_2 = test_add_dataset(PROSTAnalyzer2, "Dataset 4", Dataset_4);

%% Helper Functions:
function dataset_id = test_add_dataset(PROSTAnalyzer, dataset_to_load_name, dataset_to_load)
    dataset_id = PROSTAnalyzer.add_dataset(dataset_to_load_name, dataset_to_load);
    test_loaded_dataset(PROSTAnalyzer, dataset_to_load_name, dataset_to_load, dataset_id)
    test_summary_table(PROSTAnalyzer, dataset_to_load_name, dataset_to_load, dataset_id)
end

function test_loaded_dataset(PROSTAnalyzer, dataset_to_load_name, dataset_to_load, dataset_id)
   assert(PROSTAnalyzer.get_dataset_name(dataset_id) == dataset_to_load_name)
   dataset = PROSTAnalyzer.get_dataset(dataset_id);
   assert(dataset.Dataset_id == dataset_id)
   assert(dataset.Dataset_name == dataset_to_load_name)
   assert(isequal(dataset.Article_data , dataset_to_load.Article_data))
   assert(isequal(dataset.Lab_system , dataset_to_load.Lab_system))
   assert(isequal(dataset.Experiment_protocol , dataset_to_load.Experiment_protocol))

   % Asserting Data filed
   participants = string(fieldnames(dataset_to_load.Data));
   assert(numel(dataset.Data) == numel(participants))
   for p_idx=1:numel(participants)
        participant = participants(p_idx);
        participant_name = dataset_to_load.Data.(participant).participant_ID_in_original_structure;
        assert(dataset.Data(p_idx).Participant_id == p_idx)      
        assert(dataset.Data(p_idx).Participant_name == participant_name)
        assert(isequal(dataset.Data(p_idx).Anthropometric_data, dataset_to_load.Data.(participant).metadata))
        clean_uniform_data = remove_field_recursive(dataset.Data(p_idx).Uniform_data, "Is_included");
        clean_uniform_data = remove_field_recursive(clean_uniform_data, "Shank_cop");
        assert(isequaln(clean_uniform_data, dataset_to_load.Data.(participant).uniform_data))
   end
   disp("LOAD DATASET TEST PASSED!")
end

function s = remove_field_recursive(s, field_name)
    if isstruct(s)
        % Remove field from current level
        if isfield(s, field_name)
            s = rmfield(s, field_name);
        end

        % Recurse into all remaining fields
        fields = fieldnames(s);
        for i = 1:numel(s)
            for j = 1:numel(fields)
                f = fields{j};
                if isstruct(s(i).(f))
                    s(i).(f) = remove_field_recursive(s(i).(f), field_name);
                end
            end
        end
    end
end

function test_summary_table(PROSTAnalyzer, dataset_to_load_name, dataset_to_load, dataset_id)
    row_number = find(PROSTAnalyzer.SummaryTable.Dataset_id == dataset_id);
    assert(isscalar(row_number))
    assert(PROSTAnalyzer.SummaryTable.Dataset_name(row_number) == dataset_to_load_name)
    assert(PROSTAnalyzer.SummaryTable.Article_name(row_number) == dataset_to_load.Article_data.article_name)
    assert(PROSTAnalyzer.SummaryTable.Authors(row_number) == dataset_to_load.Article_data.authors)
    assert(PROSTAnalyzer.SummaryTable.Published_year(row_number) == dataset_to_load.Article_data.published_year)
    assert(PROSTAnalyzer.SummaryTable.Article_url(row_number) == dataset_to_load.Article_data.link_to_paper)
    assert(PROSTAnalyzer.SummaryTable.Dataset_url(row_number) == dataset_to_load.Article_data.link_to_dataset)

    [mean, std] = calc_metadata_mean_std(dataset_to_load, "Age");
    assert(PROSTAnalyzer.SummaryTable.Age_mean(row_number) == mean)
    assert(PROSTAnalyzer.SummaryTable.Age_std(row_number) == std)
    [mean, std] = calc_metadata_mean_std(dataset_to_load, "Height");
    assert(PROSTAnalyzer.SummaryTable.Height_mean(row_number) == mean)
    assert(PROSTAnalyzer.SummaryTable.Height_std(row_number) == std)
    [mean, std] = calc_metadata_mean_std(dataset_to_load, "Mass");
    assert(PROSTAnalyzer.SummaryTable.Mass_mean(row_number) == mean)
    assert(PROSTAnalyzer.SummaryTable.Mass_std(row_number) == std)

    assert(PROSTAnalyzer.SummaryTable.Speed_categories(row_number) == dataset_to_load.Experiment_protocol.speed_categories)
    assert(PROSTAnalyzer.SummaryTable.N_participants(row_number) == dataset_to_load.Experiment_protocol.num_participants)
    assert(PROSTAnalyzer.SummaryTable.N_steps(row_number) == dataset_to_load.Experiment_protocol.num_steps)
    assert(PROSTAnalyzer.SummaryTable.N_forceplates(row_number) == dataset_to_load.Lab_system.num_forceplates)

    dataset_footwear_condition = dataset_to_load.Data.participant_1.metadata.Footwear_condition.value;
    dataset_has_medial = false;
    participants = string(fieldnames(dataset_to_load.Data));
    for idx=1:numel(participants)
        if ~isempty(dataset_to_load.Data.(participants(idx)).uniform_data.right.step)
            dataset_has_medial = ~isempty(dataset_to_load.Data.(participants(idx)).uniform_data.right.step(1).Markers.Ankle.medial);
            break
        else
            dataset_has_medial = ~isempty(dataset_to_load.Data.(participants(idx)).uniform_data.left.step(1).Markers.Ankle.medial);
            break
        end         
    end
    assert(PROSTAnalyzer.SummaryTable.Footwear_condition(row_number) == dataset_footwear_condition)
    assert(PROSTAnalyzer.SummaryTable.Has_medial(row_number) == dataset_has_medial)
    disp("SUMMARY TABLE TEST PASSED!")
end

function [val_mean, val_std] = calc_metadata_mean_std(dataset_to_load, field_name)
    participants = string(fieldnames(dataset_to_load.Data));
    values = [];
    for p_idx=1:numel(participants)
        field = dataset_to_load.Data.(participants(p_idx)).metadata.(field_name);
        if isfield(field, "value")
            values = [values field.value];
        else
            values = [values field.right field.left];
        end
    end

    val_mean = mean(values);
    val_std = std(values);
end
