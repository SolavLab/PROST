classdef PROSTAnalyzer < handle
    %PROSTAnalyzer Is a class that analyzes the ROS of all the datasets 
    % together:
    %  - calculating the ROS.
    %  - analyzing participant ROS compared to metadata info.
    %  - calculating PCA.
    %  - Plotting analysis data.
    % ---------------------------------------------------------------------
    
    %% __________________________
    %   PROPERTIES
    % ___________________________
    properties(Constant, Access=private)
        NUM_SIDES = 2; % Number of possible sides ("left", "right").

        % Some constants for graphics so everything looks uniform
        COLOR_RIGHT_BRIGHT = [0 0.9 0]; % greenish bright
        COLOR_LEFT_BRIGHT = [0.9 0 0]; % reddish bright
        COLOR_RIGHT_DARK = [0 0.5 0.4]; % greenish dark
        COLOR_LEFT_DARK = [0.5, 0.0, 0.4]; % reddish dark
        MARKER_CIRCLE = 'o';
        MARKER_DOT = '.';
        MARKER_SQUARE = 'square';
        MARKER_UP = '^';
        MARKERS = 'o^sd*xv><phn';
        MARKER_SIZE = 5;
        MARKER_SIZE_SCATTER = 50;
        MARKER_FACE_ALPHA = 0.6;
        LINE_WIDTH = 2;
        LINE_STYLE_SOLID = "-";
        LINE_STYLE_DASHED = "--";
        LINE_COLOR = "black";
        FONT_SIZE = 10;
        FONT_WEIGHT = "bold";
    end
    properties(Access=public)
        DataRecords = struct([]); % Data records
        SamplesTable = table; % Unified table of all participant data
        SummaryTable = table; % Summary information of the datasets
        DataRecordsIDLookup = configureDictionary("double", "double"); % Lookup for data records dataset_id -> index
        SamplesTableSize = 0; % Size of the populated part of the samples table
        SummaryTableSize = 0; % Size of the populated part of the summary table
        PointClouds = {}; % Cell array of all point clouds.
        IgnoreObject = PROST.PROSTDatasetList(); % List of ignored trials
        FirstUniqueDatasetId = 1; % Counter for generating unique dataset IDs.
    end
    properties(Access=private)
        toolbox_root = '';
    end

    %% PUBLIC METHODS
    methods
        function [obj, dataset_ids] = PROSTAnalyzer(load_list, toolbox_root)
        %PROSTAnalyzer Constructor
        % Input :
        %   load_list - a cell array where each row contains pairs of 
        %               dataset name and path to the dataset
        %               Example:
        %               {"DB Name 1", "path/to/DB1.mat"; "DB Name", 
        %               "path/to/DB2.mat"}
        %   toolbox_root - the root path where the toolbox is saved.

            % Pre Initialization
            samples_var_types =        {'doublenan',  'doublenan',      'categorical', 'categorical',         'doublenan', 'categorical', 'doublenan', 'doublenan', 'doublenan',  'doublenan',    'doublenan',    'categorical', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan',  'doublenan'};
            samples_var_names =        {'Dataset_id', 'Participant_id', 'Side',        'Anatomical_side',     'Age',       'Gender',      'Height',    'Mass',      'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod',     'Radius',    'Center_x',  'Center_z',  'Ang_start', 'Ang_end',   'Arc_length', 'Residual' };
            samples_var_units =        {'',           '',               'right/left',  'lateral/medial/mean', 'years',     'Male/Female', 'm',         'kg',        'm',          'm',            'm',            'Yes/No',      'mm',        'mm',        'mm',        'deg',       'deg',       'deg',        'mm'       };
            samples_var_descriptions = {'',           '',               '',            '',                    'feature',   'feature',     'feature',   'feature',   'feature',    'feature',      'feature',      'feature',     'label',     'label',     'label',     'label',     'label',     'label',      ''         };
            samples_numCols = numel(samples_var_names);
    
            summary_var_types = {'doublenan',  'string',       'string',       'string'   'doublenan',      'string',      'string'       'string'            'doublenan'         'doublenan',       'categorical', 'logical'};
            summary_var_names = {'Dataset_id', 'Dataset_name', 'Article_name', 'Authors', 'Published_year', 'Article_url', 'Dataset_url', 'Speed_categories', 'Num_participants', 'Num_forceplates', 'Is_shod',     'Has_medial'};
            summary_numCols = numel(summary_var_names);
            
            if nargin < 2 || isempty(toolbox_root)
                obj.toolbox_root = uigetdir([], "Where is the toolbox saved?");
            else
                obj.toolbox_root = toolbox_root;
            end
            if nargin == 0 || isempty(load_list)
                fprintf("Creating empty PROSTAnalyzer object...\n");
                obj.DataRecords = struct('Dataset_id', {}, 'Dataset_name', {}, 'Article_data', {}, 'Lab_system', {}, 'Experiment_protocol', {}, 'Data', {});
                obj.SummaryTable = table('Size', [0 summary_numCols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
                obj.SamplesTable = table('Size', [0 samples_numCols], 'VariableTypes', samples_var_types, 'VariableNames', samples_var_names);
                obj.SamplesTable.Properties.VariableUnits = samples_var_units;
                obj.SamplesTable.Properties.VariableDescriptions = samples_var_descriptions;
                dataset_ids = [];
                return
            end
                
            % Loading data records
            fprintf("Saving all datasets from load list:\n");
            n_datasets = size(load_list, 1);
            dataset_ids = NaN(n_datasets, 1);
            for dataset_idx=1:n_datasets
                if isstruct(load_list{dataset_idx, 1}) && (isStringScalar(load_list{dataset_idx, 2}) || ischar(load_list{dataset_idx, 2}))
                    dataset = load_list{dataset_idx, 1};
                    dataset_name = load_list{dataset_idx, 2};
                elseif isstruct(load_list{dataset_idx, 2}) && (isStringScalar(load_list{dataset_idx, 1}) || ischar(load_list{dataset_idx, 1}))
                    dataset = load_list{dataset_idx, 2};
                    dataset_name = load_list{dataset_idx, 1};
                else
                    error(PROST.PROSTError("LoadList", "WrongFormat", ...
                        "Load list is not in the correct format.\n" + ...
                        "Each element should be a pair of dataset and dataset name."));
                end
                fprintf("Adding dataset %s to data records...\n", dataset_name);
                dataset_ids(dataset_idx) = obj.add_to_data_records(dataset_name, dataset);
            end
    
            
            % Creating summary table
            disp("Creating summary table...")

            % Create an empty table for the data with the desired variable names:
            summary_table = table('Size', [n_datasets summary_numCols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
            obj.SummaryTable = summary_table;
            obj.SummaryTableSize = 0;

            % Add to samples table data from datasets
            for dataset_idx=1:n_datasets
                dataset_name = obj.get_dataset_name(dataset_ids(dataset_idx));
                fprintf("Adding dataset %s to summary table...\n", dataset_name);
                obj.add_to_summary_table(dataset_ids(dataset_idx));
            end
    
            % Create samples table
            % Count the number of rows needed in samples table
            numRows = 0;
            for dataset_idx=1:n_datasets
                numRows = numRows + obj.NUM_SIDES*length(obj.DataRecords(dataset_idx).Data);
            end

            % Create an empty table for the data with the desired variable names:
            samples_table = table('Size', [numRows samples_numCols], 'VariableTypes', samples_var_types, 'VariableNames', samples_var_names);
            samples_table.Properties.VariableUnits = samples_var_units;
            samples_table.Properties.VariableDescriptions = samples_var_descriptions;
            obj.SamplesTable = samples_table;
            obj.SamplesTableSize = 0;
        end
        
        % dataset_id = add_dataset(obj, dataset_name, dataset, participants_to_ignore_left, participants_to_ignore_right);
        % add_samples(obj, dataset_id);
        % add_to_ignore(obj, dataset_id, participants, trials, side);
        % clean_data(obj, ignore_list);
        % tf = dataset_exists(obj, dataset_id);
        % delete_dataset(obj, dataset_id);
        % delete_from_ignore(obj, dataset_id, participants, trials, side);
        % delete_samples(obj, flag, varargin);
        % dataset = get_dataset(obj, dataset_id);
        % dataset_name = get_dataset_name(obj, dataset_id);
        % [features, names, units, types] = get_features(obj, list);
        % [labels, names, units, types] = get_labels(obj, list);
        % [samples, row_numbers, var_names] = get_samples(obj, var_list, varargin);
        % tf = has_medial(obj, dataset_id);
        % tf = is_ignored(obj, dataset_id, participant_id, trials, side);
        % tf = is_in_samples_table(obj, dataset_id, participant_id, side);
        % tf = participant_exists(obj, dataset_id, participant_id);
        % plot_features_vs_labels(obj, features_list, labels_list, number_of_axes_in_fig, show, file_type);
        % plot_ros(obj, who_to_plot, number_of_axes_in_fig, plot_type, show, file_type);
        % plot_cop(obj, dataset_id, participant_id, side, step_number)
        % [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = pls_analysis(obj, show, file_type);
        % set_dataset(obj, dataset_id, dataset);
        % set_dataset_name(obj, dataset_id, dataset_name);
        % tf = is_in_summary(obj, dataset_id);
    end

    %% PRIVATE METHODS
    methods (Access = private)
        % dataset_id = add_to_data_records(obj, dataset_name, dataset, anatomical_side)  
        % add_to_summary_table(obj, dataset_id);
        % delete_from_data_records(obj, dataset_id, index);
        % delete_from_summary_table(obj, index);
        % filter_data_by_bad_steps(obj, dataset_id, bad_step_min_duration, anatomical_side);
        % filter_data_by_ignore(obj);
        % filter_data_by_outliers(obj, var_list, method);
        % fit_to_circular_arc(obj, entry_number);
        % [samples, row_numbers] = get_sample_entry(obj, dataset_id, participant_id, side);
        % [samples, var_names] = get_sample_var(obj, var_list);
        % [summary, entry_number] = get_summary_entry(obj, dataset_id);
        % var = get_summary_var(obj, var_name);
        % tf = is_in_summary_table(obj, dataset_id)
        % make_point_cloud(obj, dataset_id, participant_id, side, good_step_nums, row_number, anatomical_side);
        % populate_table(obj, dataset_id, start_row, anatomical_side);
        % update_num_included_summary(obj, dataset_ids);
    end
    
    %% STATIC METHODS
    methods(Static)
        [good_steps] = get_good_steps(steps, min_speed);
        shank_cop = cop_to_shank_frame(step, anatomical_side);
        shank_data = convert_to_shank_frame(data, knee, ankle)
        [age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod] = get_metadata(metadata, side);
        save_figure(f, file_path, file_type);

    end
end

