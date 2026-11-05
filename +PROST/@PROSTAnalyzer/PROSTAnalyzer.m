classdef PROSTAnalyzer < handle
    % PROSTAnalyzer serves as the central interface for data access, 
    % integration, and analysis. The class imports each standardized dataset 
    % and stores it in the DataRecords structure that preserves the 
    % hierarchical organization of datasets and participants.
    %
    % PROSTAnalyzer maintains two primary analysis tables: 
    % (i) SummaryTable - a dataset-level summary table describing cohort 
    %                    characteristics.
    % (ii) IPDTable - a leg-level analysis table that pools anthropometrics, 
    %                 footwear condition, and ROS-derived circular arc 
    %                 parameters for each participant leg. This forms the basis 
    %                 for all subsequent statistical analyses and 
    %                 visualizations.
    %
    % The main functionalities of PROSTAnalyzer include:
    %  - Calculating the ROS.
    %  - Analyzing participant ROS compared to anthropometrics info.
    %  - Plotting analysis data.
    %  - Analyzing statistics of the ROS across datasets.
    % ---------------------------------------------------------------------
    
    %% __________________________
    %   PROPERTIES
    % ___________________________
    properties(Constant, Access=private)
        NUM_SIDES = 2; % Number of possible sides ("left", "right").

        % Some constants for graphics so everything looks uniform
        COLOR_RIGHT_BRIGHT = [0 1 0]; % greenish bright
        COLOR_LEFT_BRIGHT = [1 0 0]; % reddish bright
        COLOR_RIGHT_DARK = [0 0.5 0.0]; % greenish dark
        COLOR_LEFT_DARK = [0.5, 0.0, 0.0]; % reddish dark
        COLORMAP_RIGHT = "summer";
        COLORMAP_LEFT = "autumn";
        COLOR_DEFAULT_BLUE = [0 0.4470 0.7410];
        COLOR_DEFAULT_ORANGE = [0.8500 0.3250 0.0980];
        COLOR_DEFAULT_YELLOW = [0.9290 0.6940 0.1250];
        COLOR_DEFAULT_PURPLE = [0.4940 0.1840 0.5560];
        COLOR_DEFAULT_GREEN = [0.4660 0.6740 0.1880];
        COLOR_DEFAULT_LIGHTBLUE = [0.3010 0.7450 0.9330];
        COLOR_DEFAULT_RED = [0.6350 0.0780 0.1840];
        MARKER_CENTER = 'square';
        MARKER_NADIR = 'square';
        MARKER_ANKLE = 'hexagram';
        MARKER_DOT = '.';
        MARKER_SQUARE = 's';
        MARKER_TRIANGLE_UP = '^';
        MARKER_CIRCLE = 'o';
        MARKERS = 'o^sd*xv><phn';
        MARKER_SIZE = 5;
        MARKER_SIZE_SCATTER = 30;
        MARKER_ALPHA = 0.5;
        MARKER_LINE_WIDTH = 1;
        LINE_WIDTH = 1.5;
        LINE_STYLE_SOLID = "-";
        LINE_STYLE_DASHED = "--";
        LINE_STYLE_DOTTED = ":";
        LINE_STYLE_DASHED_DOTTED = "-.";
        LINE_STYLES = ["-" "--" ":" "-."];
        LINE_COLOR = [0 0 0];
        LINE_ALPHA = 0.6;
        FONT_SIZE = 12;
        FONT_SIZE_TEXT = 12;
        FONT_WEIGHT = "normal";
        FONT_WEIGHT_TEXT = "bold";
        FONT_NAME = "Times New Roman";
        FONT_NAME_TEXT = "FixedWidth";
    end
    properties(Access=public)
        DataRecords = struct([]); % Data records
        IPDTable = table; % Unified table of all participant data
        SummaryTable = table; % Summary information of the datasets
        IPDTableSize = 0; % Size of the populated part of the IPD table
        SummaryTableSize = 0; % Size of the populated part of the summary table
        IgnoreObject = PROST.PROSTDatasetList(); % List of ignored trials
    end
    properties(Access=private)
        DataRecordsIDLookup = configureDictionary("double", "double"); % Lookup for data records dataset_id -> index
        PointClouds = {}; % Cell array of all point clouds.
        Toolbox_root = '';
        FirstUniqueDatasetId = 1; % Counter for generating unique dataset IDs.
    end
    properties(Constant, Access=private)
        DEBUG = true;
    end
    %% PUBLIC METHODS
    methods
        function [obj, dataset_ids] = PROSTAnalyzer(load_list, toolbox_root)
        %PROSTAnalyzer Constructor
        % Input :
        %   load_list - a cell array where each row pairs an in-memory dataset
        %               struct with its name, in either order
        %               Example:
        %               {Dataset_1, "Dataset 1"; "Dataset 2", Dataset_2}
        %   toolbox_root - the root path where the toolbox is saved for internal 
        %                  use. By default
        %                  opens a UI directory window that asks you where the
        %                  toolbox is located in the file system.

            % Pre Initialization
            summary_var_types = {'doublenan',  'string',       'string',       'string',  'doublenan',      'string',      'string',      'doublenan', 'doublenan', 'doublenan',   'doublenan',  'doublenan', 'doublenan', 'cellstr',          'doublenan',       'doublenan', 'doublenan',      'categorical',        'logical',    'doublenan',               'doublenan',        'doublenan',     'doublenan'};
            summary_var_names = {'Dataset_id', 'Dataset_name', 'Article_name', 'Authors', 'Published_year', 'Article_url', 'Dataset_url', 'Age_mean',  'Age_std',   'Height_mean', 'Height_std', 'Mass_mean', 'Mass_std',  'Speed_categories', 'N_participants',  'N_steps',   'N_forceplates',  'Footwear_condition', 'Has_medial', 'N_participants_included', 'N_steps_included', 'Steps_pp_mean', 'Steps_pp_std'};
            summary_var_units = {'',           '',             '',             '',        '',               '',            '',            'years',     'years',     'm',           'm',          'kg',        'kg',        '',                 '',                '',          '',               '',                   '',           '',                        '',                 '',              ''};
            summary_n_cols = numel(summary_var_names);
            obj.IgnoreObject = PROST.PROSTDatasetList(); % List of ignored trials

            if nargin < 2 || isempty(toolbox_root)
                obj.Toolbox_root = uigetdir([], "Where is the toolbox saved?");
            else
                obj.Toolbox_root = toolbox_root;
            end

            if nargin == 0 || isempty(load_list)
                fprintf("Creating empty PROSTAnalyzer object...\n");
                obj.DataRecords = struct('Dataset_id', {}, 'Dataset_name', {}, 'Article_data', {}, 'Lab_system', {}, 'Experiment_protocol', {}, 'Data', {});
                obj.SummaryTable = table('Size', [0 summary_n_cols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
                obj.SummaryTable.Properties.VariableUnits = summary_var_units;
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
                    throw(PROST.PROSTError("LoadList", "WrongFormat", ...
                        "Load list is not in the correct format.\n" + ...
                        "Each element should be a pair of dataset and dataset name."));
                end
                fprintf("Adding dataset %s to data records...\n", dataset_name);
                dataset_ids(dataset_idx) = obj.add_to_data_records(dataset_name, dataset);
            end
    
            
            % Creating summary table
            % Create an empty table for the data with the desired variable names:
            obj.SummaryTable = table('Size', [n_datasets summary_n_cols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
            obj.SummaryTable.Properties.VariableUnits = summary_var_units;
            obj.SummaryTableSize = 0;

            % Add to summary table data from the datasets
            for dataset_idx=1:n_datasets
                dataset_name = obj.get_dataset_name(dataset_ids(dataset_idx));
                fprintf("Adding dataset %s to summary table...\n", dataset_name);
                obj.add_to_summary_table(dataset_ids(dataset_idx));
            end
        end
        
        % dataset_id = add_dataset(obj, dataset_name, dataset, participants_to_ignore_left, participants_to_ignore_right);
        % add_to_ignore(obj, dataset_id, participants, trials, side);
        % clean_data(obj, ignore_list);
        % create_IPD_table(obj);
        % tf = dataset_exists(obj, dataset_id);
        % delete_dataset(obj, dataset_id);
        % delete_from_ignore(obj, dataset_id, participants, trials, side);
        % dataset = get_dataset(obj, dataset_id);
        % dataset_name = get_dataset_name(obj, dataset_id);
        % [predictors, names, units, types] = get_predictors(obj, list);
        % [responses, names, units, types] = get_responses(obj, list);
        % [IPD_samples, row_numbers, var_names] = get_IPD_samples(obj, var_list, varargin);
        % speed_table = get_step_speeds(obj, dataset_ids);
        % tf = has_medial(obj, dataset_id);
        % tf = is_ignored(obj, dataset_id, participant_id, trials, side);
        % tf = is_in_IPD_table(obj, dataset_id, participant_id, side);
        % tf = participant_exists(obj, dataset_id, participant_id);
        % plot_cop(obj, dataset_id, participant_id, side, step_number)
        % plot_predictors_vs_responses(obj, predictors_list, responses_list, number_of_axes_in_fig, show, file_type);
        % plot_ros(obj, who_to_plot, number_of_axes_in_fig, plot_type, show, file_type);
        % [fig, speed_table] = plot_speed_distribution(obj, dataset_ids, opts, save_opts);
        % fig = plot_stats(obj, var_name, normalizer_name, categorizer_name, show, file_type, varargin)
        % set_dataset(obj, dataset_id, dataset);
        % set_dataset_name(obj, dataset_id, dataset_name);
    end

    methods(Access=public, Hidden, Sealed)
         function val = debug(obj, name)
            arguments
                obj
                name    {mustBeMember(name, ["DataRecordsIDLookup", "PointClouds", "Toolbox_root" "FirstUniqueDatasetId"])}
            end
            if ~obj.DEBUG
                error("Debugging disabled");
            end
            val = obj.(name);
        end
    end

    %% PRIVATE METHODS
    methods (Access = private)
        % dataset_id = add_to_data_records(obj, dataset_name, dataset, anatomical_side);
        % add_to_IPD_table(obj, dataset_id);
        % add_to_summary_table(obj, dataset_id);
        % delete_from_data_records(obj, dataset_id, index);
        % delete_from_IPD_table(obj, flag, varargin);
        % delete_from_summary_table(obj, index);
        % filter_data_by_bad_steps(obj, dataset_id, bad_step_min_duration, anatomical_side);
        % filter_data_by_ignore(obj);
        % fit_to_circular_arc(obj, entry_number);
        % [IPD_samples, row_numbers] = get_IPD_samples_by_entry(obj, dataset_id, participant_id, side);
        % [IPD_samples, var_names] = get_IPD_samples_by_variable(obj, var_list);
        % [summary, entry_number] = get_summary_entry(obj, dataset_id);
        % var = get_summary_var(obj, var_name);
        % tf = is_in_summary_table(obj, dataset_id)
        % make_point_cloud(obj, dataset_id, participant_id, side, good_step_nums, row_number, anatomical_side);
        % populate_table(obj, dataset_id, start_row, anatomical_side);
        % sync_data_records_lookup(obj, dataset_id);
        % update_num_included_summary(obj, dataset_ids);
    end
    
    %% STATIC METHODS
    methods(Static)
        out = analyze_stats(value, distnames, opts);
        correlations = compute_correlations(predictors, responses);
        shank_data = convert_to_shank_frame(data, knee, ankle);
        shank_cop = cop_to_shank_frame(step, anatomical_side);
        [good_steps] = get_good_steps(steps, min_speed);
    end

    methods(Static, Access=private)
        [age, sex, height, mass, leg_length, thigh_length, shank_length, footwear_condition] = get_metadata(metadata, side);
        y = filter_outliers(y, filter, filter_options);
    end
end

