clearvars -except DB_1 DB_2 DB_3
close all
clc

% setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_path = fileparts(script_full_path); % Get the folder of the script
toolbox_root = extractBefore(script_path, "+"); % Get the folder of the PROST toolbox root
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script
set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%% Load data
db_list = ["DB_1", "example_datasets/DB_1.mat"; "DB_3", "example_datasets/DB_3.mat"];
% db_list = ["DB_3", "./DB3/DB_3.mat"];

var_names = db_list(:, 1);
dataset_paths = split(db_list(:, 2), "/");
if iscolumn(dataset_paths)
    dataset_paths = dataset_paths';
end
build_names = replace("build_database_" + dataset_paths(:, end), "mat", "m");
dataset_paths(:, end) = build_names(:);
for index = 1:length(var_names)
    if ~exist(var_names(index), "var")
        disp("Building " + var_names(index) + "...")
        dataset_file = join(dataset_paths(index, :), "/");
        run(dataset_file)
    end
end

clearvars -except DB_1 DB_2 DB_3
close all

%% Load and ignore lists
load_list = {DB_1, "DB_1"; DB_3, "DB_3"};
ignore_list = {"DB_1", [3 5 14 15 16], [5 14 15 16];...
               "DB_3", 23, 23};
% load_list = {DB_3, "DB_3"};
% ignore_list = {};

%% Create ROS analysis object
[obj, ~] = PROST.PROSTAnalyzer();

%% Test Add Dataset Elements
assert(isempty(obj.DataRecords))

DB_1_ID = obj.add_to_data_records("DB_1", DB_1);
assert(isscalar(obj.DataRecords))
assert(obj.DataRecords(1).Dataset_id == DB_1_ID)
assert(obj.DataRecords(1).Dataset_name == "DB_1")
assert(isequaln(obj.DataRecords(1).Article_data, DB_1.Article_data))
assert(isequaln(obj.DataRecords(1).Experiment_explained, DB_1.Experiment_explained))
assert(isequaln(obj.DataRecords(1).Lab_explained, DB_1.Lab_explained))
assert(length(obj.DataRecords(1).Data) == 16)
for p=1:16
    assert(obj.DataRecords(1).Data(p).Participant_id == p)
    assert(obj.DataRecords(1).Data(p).Participant_name == "participant_" + p)
    assert(isequaln(obj.DataRecords(1).Data(p).Anthropometric_data, DB_1.Data.("participant_" + p).metadata))
    assert(isequaln(obj.DataRecords(1).Data(p).Uniform_data, DB_1.Data.("participant_" + p).uniform_data))
end

DB_3_ID = obj.add_to_data_records("DB_3", DB_3);
assert(length(obj.DataRecords) == 2)
assert(obj.DataRecords(2).Dataset_id == DB_3_ID)
assert(obj.DataRecords(2).Dataset_name == "DB_3")
assert(isequaln(obj.DataRecords(2).Article_data, DB_3.Article_data))
assert(isequaln(obj.DataRecords(2).Experiment_explained, DB_3.Experiment_explained))
assert(isequaln(obj.DataRecords(2).Lab_explained, DB_3.Lab_explained))
assert(length(obj.DataRecords(2).Data) == 50)
for p=1:50
    assert(obj.DataRecords(2).Data(p).Participant_id == p)
    assert(obj.DataRecords(2).Data(p).Participant_name == "participant_" + p)
    assert(isequaln(obj.DataRecords(2).Data(p).Anthropometric_data, DB_3.Data.("participant_" + p).metadata))
    assert(isequaln(obj.DataRecords(2).Data(p).Uniform_data, DB_3.Data.("participant_" + p).uniform_data))
end

assert(isempty(obj.SummaryTable))
assert(obj.SummaryTableSize == 0)

obj.add_to_summary_table(DB_1_ID);
assert(height(obj.SummaryTable) == 1)
assert(obj.SummaryTableSize == 1)
assert(obj.SummaryTable.Dataset_id(1) == DB_1_ID)
assert(obj.SummaryTable.Dataset_name(1) == "DB_1")
assert(obj.SummaryTable.Article_name(1) == DB_1.Article_data.article_name)
assert(obj.SummaryTable.Authors(1) == DB_1.Article_data.authors)
assert(obj.SummaryTable.Published_year(1) == DB_1.Article_data.published_year)
assert(obj.SummaryTable.Article_url(1) == DB_1.Article_data.link_to_paper)
assert(obj.SummaryTable.Dataset_url(1) == DB_1.Article_data.link_to_dataset)
assert(isequaln(obj.SummaryTable.Speed_categories{1}, DB_1.Experiment_explained.speed_categories))
assert(obj.SummaryTable.Num_participants(1) == DB_1.Experiment_explained.num_participants)
assert(obj.SummaryTable.Num_forceplates(1) == DB_1.Lab_explained.num_forceplates)
assert(obj.SummaryTable.Is_shod(1) == DB_1.Data.participant_1.metadata.Is_shod.value)
for side=["left" "right"]
    steps = DB_1.Data.participant_1.uniform_data.(side).step;
    if ~isempty(steps)
        assert(obj.SummaryTable.Has_medial(1) == ~isempty(steps(1).Markers.Ankle.medial))
    end
end

obj.add_to_summary_table(DB_3_ID);
assert(height(obj.SummaryTable) == 2)
assert(obj.SummaryTableSize == 2)
assert(obj.SummaryTable.Dataset_id(2) == DB_3_ID)
assert(obj.SummaryTable.Dataset_name(2) == "DB_3")
assert(obj.SummaryTable.Article_name(2) == DB_3.Article_data.article_name)
assert(obj.SummaryTable.Authors(2) == DB_3.Article_data.authors)
assert(obj.SummaryTable.Published_year(2) == DB_3.Article_data.published_year)
assert(obj.SummaryTable.Article_url(2) == DB_3.Article_data.link_to_paper)
assert(obj.SummaryTable.Dataset_url(2) == DB_3.Article_data.link_to_dataset)
assert(isequaln(obj.SummaryTable.Speed_categories{2}, DB_3.Experiment_explained.speed_categories))
assert(obj.SummaryTable.Num_participants(2) == DB_3.Experiment_explained.num_participants)
assert(obj.SummaryTable.Num_forceplates(2) == DB_3.Lab_explained.num_forceplates)
assert(obj.SummaryTable.Is_shod(2) == DB_3.Data.participant_1.metadata.Is_shod.value)
for side=["left" "right"]
    steps = DB_3.Data.participant_1.uniform_data.(side).step;
    if ~isempty(steps)
        assert(obj.SummaryTable.Has_medial(2) == ~isempty(steps(1).Markers.Ankle.medial))
    end
end

assert(isempty(obj.SamplesTable))
assert(obj.SamplesTableSize == 0)

obj.add_to_samples_table(DB_1_ID);
assert(height(obj.SamplesTable) == obj.NUM_SIDES*16)
sides_counter = 0;
for p=1:16
    for side=["left" "right"]
        steps = DB_1.Data.("participant_" + p).uniform_data.(side).step;
        sides_counter = sides_counter + ~isempty(steps);
    end
end
assert(obj.SamplesTableSize == sides_counter)

obj.add_to_samples_table(DB_3_ID);
assert(height(obj.SamplesTable) == obj.NUM_SIDES*16 + obj.NUM_SIDES*50)
for p=1:50
    for side=["left" "right"]
        steps = DB_3.Data.("participant_" + p).uniform_data.(side).step;
        sides_counter = sides_counter + ~isempty(steps);
    end
end
assert(obj.SamplesTableSize == sides_counter)


%% Test Delete Dataset
obj.delete_dataset(DB_1_ID);
obj.delete_dataset(DB_3_ID);

assert(isempty(obj.DataRecords))
assert(numEntries(obj.DataRecordsIDLookup) == 0)
assert(isempty(obj.SummaryTable))
assert(obj.SummaryTableSize == 0)
assert(all(ismissing(obj.SamplesTable, {false, missing}), 'all'))
assert(obj.SamplesTableSize == 0)
%% Test Add Dataset
assert(isempty(obj.DataRecords))
assert(numEntries(obj.DataRecordsIDLookup) == 0)
assert(isempty(obj.SummaryTable))
assert(obj.SummaryTableSize == 0)
assert(all(ismissing(obj.SamplesTable, {false, missing}), 'all') || isempty(obj.SamplesTable))
assert(obj.SamplesTableSize == 0)

DB_1_ID = obj.add_dataset("DB_1", DB_1);
assert(isscalar(obj.DataRecords))
assert(obj.DataRecords(1).Dataset_id == DB_1_ID)
assert(obj.DataRecords(1).Dataset_name == "DB_1")
assert(isequaln(obj.DataRecords(1).Article_data, DB_1.Article_data))
assert(isequaln(obj.DataRecords(1).Experiment_explained, DB_1.Experiment_explained))
assert(isequaln(obj.DataRecords(1).Lab_explained, DB_1.Lab_explained))
assert(length(obj.DataRecords(1).Data) == 16)
for p=1:16
    assert(obj.DataRecords(1).Data(p).Participant_id == p)
    assert(obj.DataRecords(1).Data(p).Participant_name == "participant_" + p)
    assert(isequaln(obj.DataRecords(1).Data(p).Anthropometric_data, DB_1.Data.("participant_" + p).metadata))
    assert(isequaln(obj.DataRecords(1).Data(p).Uniform_data, DB_1.Data.("participant_" + p).uniform_data))
end
assert(height(obj.SummaryTable) == 1)
assert(obj.SummaryTableSize == 1)
assert(obj.SummaryTable.Dataset_id(1) == DB_1_ID)
assert(obj.SummaryTable.Dataset_name(1) == "DB_1")
assert(obj.SummaryTable.Article_name(1) == DB_1.Article_data.article_name)
assert(obj.SummaryTable.Authors(1) == DB_1.Article_data.authors)
assert(obj.SummaryTable.Published_year(1) == DB_1.Article_data.published_year)
assert(obj.SummaryTable.Article_url(1) == DB_1.Article_data.link_to_paper)
assert(obj.SummaryTable.Dataset_url(1) == DB_1.Article_data.link_to_dataset)
assert(isequaln(obj.SummaryTable.Speed_categories{1}, DB_1.Experiment_explained.speed_categories))
assert(obj.SummaryTable.Num_participants(1) == DB_1.Experiment_explained.num_participants)
assert(obj.SummaryTable.Num_forceplates(1) == DB_1.Lab_explained.num_forceplates)
assert(obj.SummaryTable.Is_shod(1) == DB_1.Data.participant_1.metadata.Is_shod.value)
for side=["left" "right"]
    steps = DB_1.Data.participant_1.uniform_data.(side).step;
    if ~isempty(steps)
        assert(obj.SummaryTable.Has_medial(1) == ~isempty(steps(1).Markers.Ankle.medial))
    end
end
assert(height(obj.SamplesTable) == obj.NUM_SIDES*16)
sides_counter = 0;
for p=1:16
    for side=["left" "right"]
        steps = DB_1.Data.("participant_" + p).uniform_data.(side).step;
        sides_counter = sides_counter + ~isempty(steps);
    end
end
assert(obj.SamplesTableSize == sides_counter)

DB_3_ID = obj.add_dataset("DB_3", DB_3);
assert(length(obj.DataRecords) == 2)
assert(obj.DataRecords(2).Dataset_id == DB_3_ID)
assert(obj.DataRecords(2).Dataset_name == "DB_3")
assert(isequaln(obj.DataRecords(2).Article_data, DB_3.Article_data))
assert(isequaln(obj.DataRecords(2).Experiment_explained, DB_3.Experiment_explained))
assert(isequaln(obj.DataRecords(2).Lab_explained, DB_3.Lab_explained))
assert(length(obj.DataRecords(2).Data) == 50)
for p=1:50
    assert(obj.DataRecords(2).Data(p).Participant_id == p)
    assert(obj.DataRecords(2).Data(p).Participant_name == "participant_" + p)
    assert(isequaln(obj.DataRecords(2).Data(p).Anthropometric_data, DB_3.Data.("participant_" + p).metadata))
    assert(isequaln(obj.DataRecords(2).Data(p).Uniform_data, DB_3.Data.("participant_" + p).uniform_data))
end
assert(height(obj.SummaryTable) == 2)
assert(obj.SummaryTableSize == 2)
assert(obj.SummaryTable.Dataset_id(2) == DB_3_ID)
assert(obj.SummaryTable.Dataset_name(2) == "DB_3")
assert(obj.SummaryTable.Article_name(2) == DB_3.Article_data.article_name)
assert(obj.SummaryTable.Authors(2) == DB_3.Article_data.authors)
assert(obj.SummaryTable.Published_year(2) == DB_3.Article_data.published_year)
assert(obj.SummaryTable.Article_url(2) == DB_3.Article_data.link_to_paper)
assert(obj.SummaryTable.Dataset_url(2) == DB_3.Article_data.link_to_dataset)
assert(isequaln(obj.SummaryTable.Speed_categories{2}, DB_3.Experiment_explained.speed_categories))
assert(obj.SummaryTable.Num_participants(2) == DB_3.Experiment_explained.num_participants)
assert(obj.SummaryTable.Num_forceplates(2) == DB_3.Lab_explained.num_forceplates)
assert(obj.SummaryTable.Is_shod(2) == DB_3.Data.participant_1.metadata.Is_shod.value)
for side=["left" "right"]
    steps = DB_3.Data.participant_1.uniform_data.(side).step;
    if ~isempty(steps)
        assert(obj.SummaryTable.Has_medial(2) == ~isempty(steps(1).Markers.Ankle.medial))
    end
end
assert(height(obj.SamplesTable) == obj.NUM_SIDES*16 + obj.NUM_SIDES*50)
for p=1:50
    for side=["left" "right"]
        steps = DB_3.Data.("participant_" + p).uniform_data.(side).step;
        sides_counter = sides_counter + ~isempty(steps);
    end
end
assert(obj.SamplesTableSize == sides_counter)
