classdef ROSAnalyzer < handle
    %ROSAnalyzer Is a class that analyzes the ROS of all the datasets 
    % together:
    %  - calculating the ROS.
    %  - analyzing participant ROS compared to metadata info.
    %  - calculating PCA.
    %  - Plotting analysis data.
    % ---------------------------------------------------------------------
    
    %% __________________________
    %   PROPERTIES
    % ___________________________
    properties(Constant)
        NUM_SIDES = 2; % Number of possible sides ("left", "right").
        NUM_ANATOMICAL_SIDES = 3; % Number of possible anatomical side ("lateral", "medial", "mean")
    end
    properties(Access=public) % TODO: Make private at end of debugging
        DataRecords = struct([]); % Data records
        SamplesTable = table; % Unified table of all participant data
        SummaryTable = table; % Summary information of the datasets
        DataRecordsIDLookup = configureDictionary("double", "double"); % Lookup for data records dataset_id -> index
        SamplesTableSize = 0; % Size of the populated part of the samples table
        SummaryTableSize = 0; % Size of the populated part of the summary table
        PointClouds = {}; % Cell array of all point clouds.
        IgnoreList = cell(0, 3); % Cell array of all ignored participants
        FirstUniqueDatasetId = 1; % Counter for generating unique dataset IDs.
    end

    %% PUBLIC METHODS
    methods
        %% --------- Constructor ------------------------------------------
        function [obj, dataset_ids] = ROSAnalyzer(load_list, ignore_list)
        %ROS Constructor
        % Input :
        %   load_list - a cell array where each row contains pairs of 
        %               dataset name and path to the dataset
        %               Example:
        %               {"DB Name 1", "path/to/DB1.mat"; "DB Name", 
        %               "path/to/DB2.mat"}
        %   ignore_list - list of trials to ignore (left and right steps 
        %                 per participant. A cell array of the form: 
        %                 {"DB Name", [participants_to_ignore_left], 
        %                 [participants_to_ignore_right]}

            % Pre Initialization
            samples_var_types =        {'doublenan',  'doublenan',      'categorical', 'categorical',         'doublenan', 'categorical', 'doublenan', 'doublenan', 'doublenan',  'doublenan',    'doublenan',    'categorical', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan',  'doublenan'};
            samples_var_names =        {'Dataset_id', 'Participant_id', 'Side',        'Anatomical_side',     'Age',       'Gender',      'Height',    'Mass',      'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod',     'Radius',    'Center_x',  'Center_z',  'Ang_start', 'Ang_end',   'Arc_length', 'Residual' };
            samples_var_units =        {'',           '',               'right/left',  'lateral/medial/mean', 'years',     'Male/Female', 'm',         'kg',        'm',          'm',            'm',            'Yes/No',      'mm',        'mm',        'mm',        'deg',       'deg',       'deg',        'mm'       };
            samples_var_descriptions = {'',           '',               '',            '',                    'feature',   'feature',     'feature',   'feature',   'feature',    'feature',      'feature',      'feature',     'label',     'label',     'label',     'label',     'label',     'label',      ''         };
            samples_numCols = length(samples_var_names);
    
            summary_var_types = {'doublenan',  'string',       'string',       'string'   'doublenan',      'string',      'string'       'cell'              'doublenan'         'doublenan',       'categorical', 'logical'};
            summary_var_names = {'Dataset_id', 'Dataset_name', 'Article_name', 'Authors', 'Published_year', 'Article_url', 'Dataset_url', 'Speed_categories', 'Num_participants', 'Num_forceplates', 'Is_shod',     'Has_medial'};
            summary_numCols = length(summary_var_names);
    
            if nargin == 0 || isempty(load_list)
                disp("Creating empty ROS object...")
                obj.DataRecords = struct('Dataset_id', {}, 'Dataset_name', {}, 'Article_data', {}, 'Lab_system', {}, 'Experiment_protocol', {}, 'Data', {});
                obj.SummaryTable = table('Size', [0 summary_numCols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
                obj.SamplesTable = table('Size', [0 samples_numCols], 'VariableTypes', samples_var_types, 'VariableNames', samples_var_names);
                obj.SamplesTable.Properties.VariableUnits = samples_var_units;
                obj.SamplesTable.Properties.VariableDescriptions = samples_var_descriptions;
                dataset_ids = [];
                return
            end
            
            % Object Initialization
            if ~(nargin < 2 || isempty(ignore_list))
                % Saving ignore list
                disp("Saving ignore list...")
                obj.IgnoreList = ignore_list;
            end
    
            % Loading data records
            disp("Saving all datasets from load list...")
            n_datasets = size(load_list, 1);
            dataset_ids = NaN(n_datasets, 1);
            for index=1:n_datasets
                if isstruct(load_list{index, 1}) && (isStringScalar(load_list{index, 2}) || ischar(load_list{index, 2}))
                    dataset = load_list{index, 1};
                    dataset_name = load_list{index, 2};
                elseif isstruct(load_list{index, 2}) && (isStringScalar(load_list{index, 1}) || ischar(load_list{index, 1}))
                    dataset = load_list{index, 2};
                    dataset_name = load_list{index, 1};
                else
                    error("ROSAnalyzer:LoadList:WrongFormat", ...
                        "Load list is not in the correct format.\n" + ...
                        "Each element should be a pair of dataset and dataset name.")
                end
                disp("Adding dataset " + dataset_name + " to data records...")
                dataset_ids(index) = obj.add_to_data_records(dataset_name, dataset);
            end
    
            % Creating summary table
            disp("Creating summary table...")
            % Create an empty table for the data with the desired variable names:
            summary_table = table('Size', [n_datasets summary_numCols], 'VariableTypes', summary_var_types, 'VariableNames', summary_var_names);
            obj.SummaryTable = summary_table;
            obj.SummaryTableSize = 0;
            % Add to samples table data from datasets
            % start_row = 1;
            for index=1:n_datasets
                dataset_name = obj.get_dataset_name(dataset_ids(index));
                disp("Adding dataset " + dataset_name + " to summary table...")
                obj.add_to_summary_table(dataset_ids(index));
            end
    
            % Create samples table
            disp("Creating samples table...")
            % Count the number of rows needed in samples table
            numRows = 0;
            for index=1:n_datasets
                numRows = numRows + obj.NUM_SIDES*length(obj.DataRecords(index).Data);
                ignore_num = obj.get_num_ignored(index);
                numRows = numRows - ignore_num;
            end
            % Create an empty table for the data with the desired variable names:
            samples_table = table('Size', [numRows samples_numCols], 'VariableTypes', samples_var_types, 'VariableNames', samples_var_names);
            samples_table.Properties.VariableUnits = samples_var_units;
            samples_table.Properties.VariableDescriptions = samples_var_descriptions;
            obj.SamplesTable = samples_table;
            obj.SamplesTableSize = 0;
            % Add to samples table data from datasets
            for index=1:n_datasets
                dataset_name = obj.get_dataset_name(dataset_ids(index));
                disp("Adding dataset " + dataset_name + " to samples table...")
                obj.add_to_samples_table(dataset_ids(index));
            end
        end

        %% --------- Getters/Setters --------------------------------------
        function dataset = get_dataset(obj, dataset_id)
        %GET_DATASET returns the dataset object from the data records with 
        % the given ID. If there is no dataset with the ID, returns an 
        % empty struct.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        % Output :
        %   dataset - the dataset in the data records. Empty struct if 
        %             doesn't exist.
            
            if obj.dataset_exists(dataset_id)
                index = obj.DataRecordsIDLookup(dataset_id);
                dataset = obj.DataRecords(index);
            else
                dataset = struct([]);
            end
        end
        function dataset_name = get_dataset_name(obj, dataset_id)
        %GET_DATASET_NAME returns the name of the dataset with the given 
        % dataset ID.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        % Output :
        %   dataset_name - the name of the dataset. Equals empty string if 
        %                  the dataset does not exist.
        
            if obj.dataset_exists(dataset_id)
                index = obj.DataRecordsIDLookup(dataset_id);
                dataset_name = obj.DataRecords(index).Dataset_name;
            else
                dataset_name = "";
            end
        end
        function [samples, entry_numbers] = get_sample_entry(obj, dataset_id, participant_id, side, anatomical_side)
        %GET_SAMPLE_ENTRY returns the entry numbers and sample entries from the 
        % samples table given the dataset IDs, participant IDs, sides and 
        % anatomical sides. Returns empty table and empty array if does not 
        % exist.
        % Input :
        %   dataset_id - the dataset ID for the requested entry. A positive 
        %                integer number. Could be a vector of IDs.
        %   participant_id - the participant ID for the requested entry. A 
        %                    positive integer number. Could be a vector of IDs.
        %                    Default: all participants of the dataset with 
        %                    ID dataset_id (except those ignored).
        %   side - the side for the requested entry. Could be a vector of both
        %          "left" and "right".
        %          Default: ["left", "right"].
        %   anatomical_side - the anatomical side for the requested entry. Could
        %                     be a vector of multiple anatomical sides.
        %                     Default: ["lateral", "medial", "mean"].
        % Output :
        %   samples - the entry/entries in the samples table.
        %   entry_numbers - the row number/s of the entry/entries in the samples 
        %                   table. 
            
            if nargin < 5
                anatomical_side = ["lateral" "medial" "mean"];
            end
            if nargin < 4
                side = ["left" "right"];
            end
            if nargin == 2
                dataset = obj.get_dataset(dataset_id);
                if isempty(dataset)
                    entry_numbers = [];
                    samples = table;
                    return
                end
                participant_id = [dataset.Data(:).Participant_id];
            end
            side_rows = ismember(obj.SamplesTable.Side, side);
            anatomical_side_rows = ismember(obj.SamplesTable.Anatomical_side, anatomical_side);
            participant_rows = ismember(obj.SamplesTable.Participant_id, participant_id);
            dataset_rows = ismember(obj.SamplesTable.Dataset_id, dataset_id);
            entry_numbers = find(dataset_rows & participant_rows & side_rows & anatomical_side_rows);
            if isempty(entry_numbers)
                samples = table;
            else
                samples = obj.SamplesTable(entry_numbers, :);
            end
        end
        function var = get_sample_var(obj, list)
        %GET_SAMPLE_VAR returns a table of all variables in list from the 
        % samples table.
        % Input :
        %   list - the variable name or list of variable names. Must be a string 
        %          array or character cell array.
        % Output :
        %   var - the sample table entries for the variables in list.

            idx = ismember(list, string(obj.SamplesTable.Properties.VariableNames));
            if ~any(idx)
                error("ROSAnalyzer:SamplesTable:VariableDoesNotExist", ...
                      "The variables " + string(mat2str(list)) + " do not exist.")
            end
            var = obj.SamplesTable{1:obj.SamplesTableSize, list(idx)};
        end
        function [features, names, units, types] = get_features(obj, list)
        %GET_FEATURES returns a table of all features (anthropometric data) in 
        % list from the samples table.
        % Input :
        %   list - list of features to return
        % Output : 
        %   features - the anthropometric parameters.
        %   names - the names of the anthropometric parameters.
        %   units - the units of the anthropometric parameters.
        %   types - the anthropometric parameter types.

            idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'feature');
            if nargin == 2 && ~isempty(list)
                idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
            end
            if ~any(idx)
                error("ROSAnalyzer:SamplesTable:FeatureDoesNotExist", ...
                      "The features " + string(mat2str(list)) + " do not exist.")
            end
            names = obj.SamplesTable.Properties.VariableNames(idx);
            units = obj.SamplesTable.Properties.VariableUnits(idx);
            types = obj.SamplesTable.Properties.VariableTypes(idx);
            features = obj.SamplesTable(1:obj.SamplesTableSize, names); 
        end
        function [labels, names, units, types] = get_labels(obj, list)
        %GET_LABELS returns all labels (ROS arc parameters) in list from 
        % the samples table.
        % Input :
        %   list - list of labels to return
        % Output : 
        %   labels - the ROS parameters.
        %   names - the names of the ROS parameters.
        %   units - the units of the ROS parameters.
        %   types - the ROS parameter types.

            idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'label');
            if nargin == 2 && ~isempty(list)
                idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
            end
            if ~any(idx)
                error("ROSAnalyzer:SamplesTable:LabelDoesNotExist", ...
                      "The labels " + string(mat2str(list)) + " do not exist.")
            end
            names = obj.SamplesTable.Properties.VariableNames(idx);
            units = obj.SamplesTable.Properties.VariableUnits(idx);
            types = obj.SamplesTable.Properties.VariableTypes(idx);
            labels = obj.SamplesTable(1:obj.SamplesTableSize, names);
        end
        function [summary, entry_number] = get_summary_entry(obj, dataset_id)
        %GET_DATA_SUMMARY_ENTRY returns the entry number in the data 
        % summary table from the dataset ID. If there is no dataset with 
        % the given ID, returns an empty table and NaN.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        % Output :
        %   summary - the entry in the summary table. Empty table if
        %             doesn't exist.
        %   entry_number - the row number in the summary table of the
        %                  entry. NaN if entry doesn't exist.

            entry_number = find(obj.SummaryTable.Dataset_id == dataset_id);
            if isempty(entry_number)
                summary = table;
                entry_number = NaN;
            else
                summary = obj.SummaryTable(entry_number, :);
            end
        end
        function var = get_summary_var(obj, var_name)
        %GET_SSUMMARY_VAR returns all entries of var_name from summary
        % table.
        % Input :
        %   var_name - the variable name. Must be a string scalar or 
        %              character row vector.
        % Output :
        %   var - the summary table entries for variable var_name.

            if ~isStringScalar(var_name) && (~ischar(var_name) || isrow(var_name))
                error("ROSAnalyzer:SummaryTable:WrongFormat", ...
                      "Summary table variable name must be a string scalar or character row vector.")
            elseif ~ismember(var_name, obj.SummaryTable.Properties.VariableNames)
                error("ROSAnalyzer:SummaryTable:UnrecognizedVariableName", ...
                      "'%s' is not a variable name of the summary table.", var_name)
            end
            var = obj.SummaryTable.(var_name)(1:obj.SummaryTableSize);
        end
        function ignore_num = get_num_ignored(obj, dataset_id)
        %GET_NUM_IGNORED returns the number of ignored trials (both left
        % and right) in ignored list of the given dataset.
        % Input : 
        %   dataset_id - the ID of the dataset. A positive integer number.
        % Output :
        %   ignore_num - number of ignored trials.
        
            dataset_name = obj.get_dataset_name(dataset_id);
            ignore_num = length([obj.IgnoreList{strcmp(string(obj.IgnoreList(:, 1)), dataset_name), 2:3}]);
        end

        %% --------- Modifiers --------------------------------------------
        function dataset_id = add_dataset(obj, dataset_name, dataset, participants_to_ignore_left, participants_to_ignore_right)
        %ADD_DATASET Adds a new dataset to data_records and to the feature 
        % table.
        % Input :
        %   dataset_name - the name of the dataset to add.
        %   dataset - the dataset struct to add.
        %   participants_to_ignore_left, participants_to_ignore_right -
        %   vectors of participant numbers to ignore for left and right 
        %   steps respectively.

            disp("Adding dataset " + dataset_name + "...")
            % Add to ignore list if there are participants to ignore
            if nargin == 4
                participants_to_ignore_right = [];
            end
            if nargin > 3 && (~isempty(participants_to_ignore_left) || ~isempty(participants_to_ignore_right)) 
                obj.add_to_ignore_list({dataset_name, participants_to_ignore_left, participants_to_ignore_right, participants_to_ignore_right});
            end

            % Add to data records
            index = obj.add_to_data_records(dataset_name, dataset);
            dataset_id = obj.DataRecords(index).Dataset_id;
            
            % Add to summary table
            obj.add_to_summary_table(dataset_id);
            
            % Add to samples table
            obj.add_to_samples_table(dataset_id);

        end
        function delete_dataset(obj, dataset_id)
        %DELETE_DATASET deletes the given dataset from all records.
        % Input :
        %   dataset_id - the ID of the dataset to delete. A positive 
        %                integer number.
            
            disp("Deleting dataset " + dataset_id + "...")
            if ~obj.dataset_exists(dataset_id)
                return
            end

            % Get dataset info
            index = obj.DataRecordsIDLookup(dataset_id);

            % Delete from data records
            obj.delete_from_data_records(dataset_id, index);

            % Delete from summary table
            obj.delete_from_summary_table(index);

            % Delete from samples table
            obj.delete_from_samples_table(dataset_id);
            
        end
        
        % TODO: add functionality to add_participant. I need to figure our
        % how I add label parameters to samples table.
        % function add_participant(obj, dataset_id, participant_name, metadata, processed_data, participant_id)
        %     dataset = obj.get_dataset(dataset_id);
        %     if isempty(dataset)
        %         error("ROSAnalyzer:DataRecords:MissingDataset", ...
        %               "Dataset %d not in data records.", dataset_id)
        %     end
        % 
        %     disp("Adding to datarecords: participant " + participant_id + " to dataset " + dataset_id + "...")
        %     participant_ids = [obj.data_records(dataset_id).Data(:).Participant_id];
        %     if nargin < 6 || ~ismember(participant_id, participant_ids)
        %         participant_id = length(participant_ids) + 1;
        %     end
        %     obj.data_records(dataset_id).Data(participant_id).Participant_id = participant_id;
        %     obj.data_records(dataset_id).Data(participant_id).Participant_name = participant_name;
        %     obj.data_records(dataset_id).Data(participant_id).Anthropometric_data = metadata;
        %     obj.data_records(dataset_id).Data(participant_id).Processed_data = processed_data;
        % 
        %     disp("Updating number of participants in summary table for dataset " + dataset_id + "...")
        %     [~, index] = obj.get_summary_entry(dataset_id);
        %     obj.summary_table.Num_Participants(index) = obj.summary_table.Num_Participants(index) + 1;
        % 
        %     disp("Adding to samples table: participant " + participant_id + " to dataset " + dataset_id + "...")
        %     obj.populate_table
        % end
        % TODO: Create delete_participant function

        %% --------- Plot Functions --------------------------------------- 
        function plot_features_vs_labels(obj, features_list, labels_list, number_of_axes_in_fig)
        %PLOT_FEATURES_VS_LABELS plots the features (anthropometric parameters)
        % v.s. the labels (ROS parameters).
        % Input :
        %   features_list - list of anthropometric parameters to plot.
        %   labels_list - list of ROS parameters to plot.
        %   number_of_axes_in_fig - number of axes per figure to plot.

            % Prep plotting list
            disp("Plotting Features vs Labels...")
            if nargin < 3
                labels_list = {};
            end 
            if nargin < 2
                features_list = {};
            end

            % Get Data
            [features, feature_names, feature_units, feature_types] = obj.get_features(features_list);
            [labels, label_names, label_units, label_types] = obj.get_labels(labels_list);
            n_features = numel(feature_names);
            n_labels = numel(label_names);
            if nargin < 4
                number_of_axes_in_fig = length(label_names);
            end
            
            % Get Sides
            sides = obj.get_sample_var("Side");
            
            % Get Residuals
            residuals = obj.get_sample_var("Residual");
            r_left  = residuals(sides=="left");
            r_right = residuals(sides=="right");

            % Normalize inverse residuals for reasonable marker sizes
            inv_left  = 1 ./ r_left;
            inv_right = 1 ./ r_right;
            norm_left = (inv_left  / max(inv_left));
            norm_right = (inv_right / max(inv_right));
          
            % Scale marker sizes (adjust 200 as needed)
            sz_left  = 200 * norm_left;
            sz_right = 200 * norm_right;
            
            % Define colors for sides
            color_left  = [0 0.7 0];   % greenish
            color_right = [0.85 0 0];  % reddish

            % Define Marker Parameters
            marker = "o";

            % Start plotting
            axes_counter = 0;
            fig_counter = 0;
            for feature_index=1:n_features
                for label_index=1:n_labels
                    % Get feature data
                    x = features{:, feature_index};
                    x_left  = x(sides=="left");
                    x_right = x(sides=="right");
                    x_unit = replace(feature_units{feature_index}, "_", " ");
                    x_name = replace(feature_names{feature_index}, "_", " ");
                    x_type = feature_types{feature_index};
                    x_numeric = (strcmp(x_type, "double") || strcmp(x_type, "doublenan"));
                    
                    % Get label data
                    y = labels{:, label_index};
                    y_left  = y(sides=="left");
                    y_right = y(sides=="right");
                    y_unit = replace(label_units{label_index}, "_", " ");
                    y_name = replace(label_names{label_index}, "_", " ");
                    y_type = label_types{label_index};
                    y_numeric = (strcmp(y_type, "double") || strcmp(y_type, "doublenan"));
                                                           
                    % Create new figure for new set of axes
                    if axes_counter == 0
                        fig_counter = fig_counter + 1;
                        fig  = figure(Name=x_name + " vs " + strjoin(replace(label_names, "_", " "), ", ") + " Plot " + fig_counter);
                        tiledlayout(fig)
                        sgtitle(fig, fig.Name)
                    end
                    
                    % Initialize axis
                    ax = nexttile;
                    hold(ax, "on");
                    
                    % Set axis labels
                    x_label = x_name;
                    if ~isempty(x_unit)
                       x_label = x_label + " [" + x_unit + "]";
                    end
                    y_label = y_name;
                    if ~isempty(y_unit)
                       y_label = y_label + " [" + y_unit + "]";
                    end

                    % Plot
                    % if ~x_numeric && ~iscategorical(x)
                    %     x = categorical(replace(string(x), "_", " "));
                    % end
                    % if ~y_numeric && ~iscategorical(y)
                    %     y = categorical(replace(string(y), "_", " "));
                    % end

                    % Plot both sides
                    h_left = scatter(x_left,  y_left,  sz_left,  color_left, marker, 'filled', MarkerFaceAlpha=0.6);
                    h_right = scatter(x_right, y_right, sz_right, color_right, marker, 'filled', MarkerFaceAlpha=0.6);

                    xlim padded
                    ylim padded
                    xlabel(x_label);
                    ylabel(y_label);
                    grid(ax, "on");

                    % Increment counter
                    axes_counter = axes_counter + 1;

                    % % Create legend/colorbar
                    if axes_counter == number_of_axes_in_fig || (feature_index==n_features && label_index==n_labels)
                        legend([h_left h_right], ["Left" "Right"], Location="east", FontSize=12)
                        axes_counter = 0;
                    end
                end
            end
        end
        function plot_ros(obj, who_to_plot, number_of_axes_in_fig)
        %PLOT_ROS plots the ros of all given data with their fitted arcs.
        % Input :
        %   who_to_plot - a cell array with pairs of dataset id and 
        %                 list of participants to plot. Example:
        %                 {1, [1 2 3 4]}
        %   number_of_axes_in_fig - number of axes per figure to plot.
            
            % Prep plotting list
            disp("Plotting ROS...")
            if nargin < 3
                number_of_axes_in_fig = 10;
            end
            if nargin < 2 || isempty(who_to_plot)
                n_data_records = length(obj.DataRecords);
                who_to_plot = cell(n_data_records, 2);
                who_to_plot(:, 1) = {obj.DataRecords.Dataset_id}';
            end           
            for who_index=1:size(who_to_plot, 1)
                if size(who_to_plot, 2) == 1 || isempty(who_to_plot{who_index, 2})
                    dataset_id = who_to_plot{who_index, 1};
                    dataset = obj.get_dataset(dataset_id);
                    who_to_plot{who_index, 2} = [dataset.Data.Participant_id];
                end
            end
            
            % Set plot parameters
            x_limits = [-100 200];
            y_limits = [-100 50];
            color_scatter = dictionary(["right" "left"], {[0 0.5 0.4] [0.5, 0.0, 0.4]});
            color_arc = dictionary(["right" "left"], {[0.0, 1.0, 0.0] [1.0, 0.0, 0.0]});
            marker_size = 7;
            line_width = 2;
            markers = '.o+*xsd^v><ph';
            x_label = "x [mm]";
            y_label = "z [mm]";

            % Start plotting
            fig_counter = 0;
            for who=who_to_plot'
                axes_counter = 0;
                dataset_id = who{1};
                dataset_name = obj.get_dataset_name(dataset_id);
                participants = who{2};
                for participant_id=participants
                    [samples, entry_numbers] = obj.get_sample_entry(dataset_id, participant_id);
                    if isempty(samples)
                        continue
                    end
                    
                    % Create new figure for new set of axes
                    if axes_counter == 0
                        fig_counter = fig_counter + 1;
                        fig  = figure(Name="ROS Plot " + fig_counter);
                        tiledlayout(fig)
                        % sgtitle_name = "Point Clouds and Fitted Arcs " + fig_counter;
                        % sgtitle(fig, sgtitle_name)
                    end

                    % Initialize axis
                    ax = nexttile;
                    
                    % Set axis parameters
                    hold(ax, "on")
                    grid(ax, "on")
                    axis(ax, "equal");
                    pbaspect(ax, [1 1 1]);
                    xticks(ax, x_limits(1):50:x_limits(2));
                    yticks(ax, y_limits(1):50:y_limits(2));
                    ax.XLim = x_limits;
                    ax.YLim = y_limits;
                    text(ax, x_limits(1), y_limits(2) - 10, erase(dataset_name, "_") + "P" + participant_id, FontSize=9, FontWeight="bold")
  
                    % Plot trials of participant
                    for i=1:height(samples)
                        entry_number = entry_numbers(i);
                        sample = samples(i, :);
                        
                        % get point cloud of corresponding entry in samples table.
                        point_cloud = obj.PointClouds{entry_number};
 
                        % Assuming point_cloud is an Nx3 matrix with columns: x, z, num_trial
                        x = point_cloud(:, 1);
                        z = point_cloud(:, 2);
                       
                        % Get arc parameters
                        arc_data = num2cell(sample{:, ["Radius", "Center_x", "Center_z", "Ang_start", "Ang_end"]});
                        [radius, center_x, center_z, ang_start, ang_end] = arc_data{:};

                        % Set color
                        side = sample.Side;

                        % Plot point cloud and arc
                        color1 = color_scatter{side};
                        color2 = color_arc{side};
                        scatter(ax, x, z, marker_size, color1 , markers(1));
                        xlabel(ax, x_label);
                        ylabel(ax, y_label);
                        ang_vec = linspace(ang_start, ang_end, length(x));
                        arc_points = [center_x + radius*sind(ang_vec); center_z - radius*cosd(ang_vec)];
                        plot(ax, arc_points(1, :), arc_points(2, :), '-', Color=color2, LineWidth=line_width, DisplayName=string(side) + " fitted arc")
                        text(ax, 0.5*(x_limits(1) + x_limits(2)), y_limits(2) - 10 - (i - 1)*15, "residual: " + sample.Residual, Color=color_arc{side}, FontSize=9, FontName="FixedWidth", FontWeight="bold")
                    end

                    axes_counter = axes_counter + 1;

                    % Create legend
                    if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                        % Dummy plots for legend in last axes
                        sides = ["right", "left"];
                        h = gobjects(4, 1);
                        for i=1:2
                            side = sides(i);
                            color1 = color_scatter{side};
                            color2 = color_arc{side};
                            h(i) = scatter(ax, NaN, NaN, marker_size, color1(1, :), "filled", DisplayName=side);
                            h(i + 2) = plot(ax, NaN, NaN, '-', Color=color2(1, :), LineWidth=line_width, DisplayName=string(side) + " fitted arc");
                        end                   
                        
                        lgd = legend(h, FontSize=9);
                        lgd.Layout.Tile = 'east';
                        axes_counter = 0;
                    end
                end
            end
        end
        function [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = pls_analysis(obj)
        %PLS_ANALYSIS calculates the Partial Least Squares regression of
        % the sample data and plots percent variance.
        % Output :
        %   XL, YL, XS, YS, BETA, PCTVAR, MSE, stats – PLS regression 
        %   parameters as described in the plsregress documentation.

            % Get features
            [features, feature_names, ~, features_types] = obj.get_features();
            feature_names = string(feature_names);
            X = [];
            X_continuous = features{:, strcmp(features_types, 'double')};
           
            X = [X_continuous dummyvar(features.Gender) dummyvar(features.Is_shod)];
            % for k = 1:numel(feature_names)
            %     feature = features.(feature_names(k));
            % 
            %     if ~strcmp(features_types{k}, 'double')
            %         % continue
            %         X = [X dummyvar(categorical(feature))];
            %     else
            %         X = [X feature];
            %     end
            % end
            % Standardize X
            [Xz, muX, sigmaX] = zscore(X);

            % Get labels
            [labels, label_names, label_units, ~] = obj.get_labels();
            Y = table2array(labels);
            label_names = string(replace(label_names, "_", " "));
            label_units = string(replace(label_units, "_", " "));

            % Standardize Y
            [Yz, muY, sigmaY] = zscore(Y);

            % Calculate PLS regression
            ncomp = width(Xz);
            [~, ~, ~, ~, ~, PCTVAR, MSE, ~] = plsregress(Xz, Yz, ncomp, Intercept=false);
            
            % Show percent variance explained in features
            % figure(Name="PLS Percent Variance in X")
            % plot(1:ncomp, cumsum(100*PCTVAR(1, :)), '-bo');
            % xlabel('Number of PLS components');
            % ylabel('Percent Variance Explained in X');
            % grid on

            % Show percent variance explained in labels
            figure(Name="PLS Percent Variance in Y")
            plot(1:ncomp, cumsum(100*PCTVAR(2, :)), '-bo');
            xlabel('Number of PLS components');
            ylabel('Percent Variance Explained in Y');
            grid on
            
            figure
            yyaxis left
            plot(0:ncomp, MSE(1,:),'-o')
            yyaxis right
            plot(0:ncomp, MSE(2,:),'-o')
            legend('MSE Predictors','MSE Response')
            xlabel('Number of Components')

            % Calculate PLS regression
            ncomp = 8;
            [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = plsregress(Xz, Yz, ncomp, Intercept=false);
                        
            figure(Name="PLS Fit v.s. Data")
            tiledlayout
            cmap = lines(numel(label_names));
            marker_size = 5;

            % yfit = XS*YL'.*sigmaY + muY; 
            yfit = Xz*BETA.*sigmaY + muY;
            TSS = sum((Y - mean(Y, 1)).^2, 1);
            RSS = sum((Y - yfit()).^2, 1);
            Rsquared = round(1 - RSS./TSS, 3);
            for k=1:numel(label_names)
                y_k = Y(:, k);
                yfit_k = yfit(:, k);
                ax = nexttile;
                hold(ax, "on")
                axis(ax, "equal")
                yyaxis left
                plot(ax, y_k, 'o', MarkerSize=marker_size, DisplayName=label_names(k));
                ylabel("DATA")
                yyaxis right
                plot(ax, yfit_k, 'o', MarkerSize=marker_size, DisplayName=label_names(k));
                ylabel("FIT")
                x_limits = xlim(ax);
                y_limits = ylim(ax);
                text(ax, x_limits(1), y_limits(2), "Rsquared = " + Rsquared(k), FontSize=12, FontWeight="bold", Color=cmap(k, :))   
                
                % Set axis labels
                x_label = "Data";
                y_label = "Fit";
                if ~isempty(label_units(k))
                    x_label = x_label  + " [" + label_units(k) + "]";
                    y_label = y_label  + " [" + label_units(k) + "]";
                end
                % xlabel(ax, x_label)
                % ylabel(ax, y_label)
                title(label_names(k))
                grid(ax, "on");
            end
        end

        %% --------- Is Functions -----------------------------------------
        function tf = dataset_exists(obj, dataset_id)
        %DATASET_EXISTS returns whether the dataset with the ID dataset_id
        % exists in the data records.
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer
        %                number.
        % Output :
        %   tf - true (logical 1) if the dataset exists and false (logical 1)
        %        otherwise.

            if isnumeric(dataset_id) && isscalar(dataset_id)
                tf = isKey(obj.DataRecordsIDLookup, dataset_id);
            else
                error("ROSAnalyzer:DatasetID:WrongFormat",...
                      "Dataset ID must be a positive integer number.");
            end
        end
        function tf = is_in_samples_table(obj, dataset_id, participant_id, side, anatomical_side)
        %IS_IN_SAMPLES_TABLE returns whether a trial is in the samples table. A 
        % trial is a combination of dataset_id, participant_id, side and 
        % anatomical_side.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        %   participant_id - the ID of the participant for the given dataset. A 
        %                    positive integer number.
        %   side - Either "left" or "right".
        %   anatomical_side - the anatomical side(s). Either "lateral", "medial" 
        %                     or "mean".
        % Output :
        %   tf - true (logical 1) if trial is in the samples table and false 
        %        (logical 0) otherwise.

            if nargin < 5
                anatomical_side = ["lateral" "medial" "mean"];
            end
            if nargin < 4
                side = ["left" "right"];
            end
            if nargin < 3
                dataset = obj.dataset_exists(dataset_id);
                if ~obj.dataset_exists(dataset_id)
                    tf = false;
                    return
                end
                participant_id = [dataset.Data(:).Participant_id];
            end
            side_rows = ismember(obj.SamplesTable.Side, side);
            anatomical_side_rows = ismember(obj.SamplesTable.Anatomical_side, anatomical_side);
            participant_rows = ismember(obj.SamplesTable.Participant_id, participant_id);
            dataset_rows = ismember(obj.SamplesTable.Dataset_id, dataset_id);
            entry_numbers = find(dataset_rows & participant_rows & side_rows & anatomical_side_rows, 1, 'first');
            tf = isempty(entry_numbers);
        end
        function tf = is_in_summary_table(obj, dataset_id)
        %IS_IN_SUMMARY_TABLE returns whether a dataset is in the summary table.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        % Output :
        %   tf - true (logical 1) if the dataset has an entry in the summary 
        %        table and false (logical 0) otherwise.

            if isnumeric(dataset_id) && isscalar(dataset_id)
                tf = ismember(obj.SummaryTable.Dataset_id, dataset_id);
            else
                error("ROSAnalyzer:DatasetID:WrongFormat",...
                      "Dataset ID must be a positive integer number.");
            end
        end
        function tf = is_ignored(obj, dataset_id, participant_id, side)
        %IS_IGNORED Returns whether a trial is in the ignore list and 
        % should be ignored. A trial is a combination of dataset_id, 
        % participant_id and side.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        %   participant_id - the ID of the participant for the given 
        %                    dataset. A positive integer number.
        %   side - Either "left" or "right".
        % Output :
        %   tf - true (logical 1) if trial should be ignored and false 
        %        (logical 0) otherwise.
            
            % Check if ignore_list exists
            if isempty(obj.IgnoreList)
                tf = false;
                return
            end
            % Check that the dataset ID is in the right format and only
            % a single ID was given
            if ~isscalar(dataset_id) && ~isnumeric(dataset_id)
                error("ROSAnalyzer:DatasetID:WrongFormat", ...
                      "Dataset ID should be a positive integer number.")
            end
            
            % Check that the participant ID is in the right format and only
            % a single ID was given
            if ~isscalar(participant_id) && ~isnumeric(participant_id)
                error("ROSAnalyzer:ParticipantID:WrongFormat", ...
                      "Participant ID should be a positive integer number.")
            end            

            % Convert side to relevant index in ignore_list
            if strcmp(side, "left")
                side = 2;
            elseif strcmp(side, "right")
                side = 3;
            else
                error("ROSAnalyzer:Side:WrongFormat", "Side should be either 'left' or 'right'.")
            end

            % Check if participant is a member of the ignore list for the 
            % given dataset and side
            dataset_name = obj.get_dataset_name(dataset_id);
            ignore_index = find(strcmp(string(obj.IgnoreList(:, 1)), dataset_name), 1);
            if isempty(ignore_index)
                tf = false;
                return
            end
            tf = ismember(participant_id, obj.IgnoreList{ignore_index, side});
        end
        function tf = has_medial(obj, dataset_id)
        %HAS_MEDIAL returns true if the given dataset has medial marker 
        % data and false otherwise.
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        % Output :
        %   tf - true (logical 1) if dataset has medial marker trajectory 
        %        data and false (logical 0) otherwise.

            summary = obj.get_summary_entry(dataset_id);
            tf = summary.Has_medial;
        end
    end

    %% PRIVATE METHODS
    methods (Access = public) % TODO: Change to private after testing
        function fit_to_circular_arc(obj, entry_number)
        %FIT_TO_CIRCULAR_ARC circle fitting from BAPAT 2022 
        % First approximate solution based on linear least squares approach
        % - Coope 1993 paper.
        % I got this code from a file named "main_ROS_curve.m" that I got 
        % from Dana.
        % -----------------------------------------------------------------
        % this function receives the 2D point cloud and fits this to a 
        % circular arc, this function returns the parameters of the fitted 
        % circular arc and fills the samples table with them.
        % Input :
        %   entry_number - the row number in the samples table where the
        %                  fitted data is entered.
        %  Output : 
        %   circular arc parameters:
        %       radius [m]
        %       center_x [m]
        %       center_z [m]
        %       ang_start [deg]
        %       ang_end [deg]
        %       arc_length [deg]
            
            % Check if participant exists
            if entry_number > size(obj.SamplesTable, 1)
                error("ROSAnalyzer:DataTable:MissingParticipant", ...
                      "Participant number %d is too large.\nSamples table has %d rows.", entry_number, size(obj.SamplesTable, 1));
            end

            % Check for NaN or Inf values in the point cloud
            % get point cloud of corresponding entry in samples table.
            point_cloud = obj.PointClouds{entry_number};
            % point_cloud = point_cloud(:, 1:2);
            if any(isnan(point_cloud(:))) || any(isinf(point_cloud(:)))
                error("ROSAnalyzer:PointCloud:ContainsNaNInfs", ...
                      "Point cloud contains NaN or Inf values");
            end
            
            % 1) Find first approximate solution based on LLS approach
            % Coope 1993 paper:
            n_points = size(point_cloud, 1);
            B = [point_cloud'; ones(1, n_points)]';
            d = point_cloud(:, 1).^2 + point_cloud(:, 2).^2;
            y = (B'*B)\(B'*d); % B is rectangular matrix hence multiplied by B'
            center_x = y(1)/2;
            center_y = y(2)/2;
            y(3) = 0; % Actual residual = y(3), but set to zero after first approximation
            ros_rad = sqrt(y(3) + center_x^2 + center_y^2);
        
            % 2) Optimize the solution:
                % Initial guess from linear least squares approach
            initial_guess = [center_x; center_y; ros_rad];
            options = optimoptions('lsqnonlin', 'Display', 'off');
            % options = optimoptions(options,'TolFun',1e-10,'TolX',1e-10,'MaxFunEvals',100000,'MaxIter',40000);
            % Ensure initial guess does not contain NaN or Inf values
            if any(isnan(initial_guess)) || any(isinf(initial_guess))
                error("ROSAnalyzer:CircleFit:ContainsNaNInfs", ...
                      "Initial guess contains NaN or Inf values");
            end

                % Function that calculates non-linear LSQ residual.
                % (this function is also copied from Dana's code)
            circle_fit_fun = @(params)(params(3) - sqrt((point_cloud(:, 1) - params(1)).^2 + (point_cloud(:, 2) - params(2)).^2));
            
                % Unconstrained Least squares nonlinear fit algorithm
            [params, residual_norm, residual] = lsqnonlin(circle_fit_fun, initial_guess,[],[], options);
            % obj.PointClouds{entry_number}(:, 3) = residual;
                
                % Normalize residual by number of data points
            residual_norm = sqrt(residual_norm / n_points);

            % 3) Get ROS parameters: angles, arc length:
                % find ROS start point and end point
            [~, ind] = min(point_cloud(:, 1));
            ros_start = point_cloud(ind, :);
            [~, ind] = max(point_cloud(:, 1));
            ros_end = point_cloud(ind, :);
        
                % calculate vectors from center to start and end points
            vec_start = ros_start - params(1:2)';
            vec_end = ros_end - params(1:2)';
        
                % calculate the arc angles (relative to the vector from the center straight down) and arc length
            cross_product = cross([0, -1, 0], [vec_start/norm(vec_start), 0]);
            ang_start = rad2deg(asin(cross_product(3)));
            cross_product = cross([0, -1, 0], [vec_end/norm(vec_end), 0]);
            ang_end = rad2deg(asin(cross_product(3)));
            arc_length = ang_end - ang_start;
            radius = params(3);
            center_x = params(1);
            center_z = params(2);
            
            % 4) Fill samples table
            obj.SamplesTable.Radius(entry_number) = radius;
            obj.SamplesTable.Center_x(entry_number) = center_x;
            obj.SamplesTable.Center_z(entry_number) = center_z;
            obj.SamplesTable.Ang_start(entry_number) = ang_start;
            obj.SamplesTable.Ang_end(entry_number) = ang_end;
            obj.SamplesTable.Arc_length(entry_number) = arc_length;
            obj.SamplesTable.Residual(entry_number) = residual_norm;
        end
        function make_point_cloud(obj, good_steps, entry_number, anatomical_side)
        %MAKE_POINT_CLOUD receives an array of good "steps" (structures)
        % and extracts all the ROS points in the sagital (XZ) plane into a
        % "point_cloud" - a 2 x length(good_steps)*101 matrix. The data is
        % saved into the point_clouds property.
        %   Input :
        %       good_steps - a structure array of the good steps from
        %                    multiple measurements for a given participant.
        %       entry_number - the row in the samples table that the point
        %                      cloud corresponds to.
        %       anatomical_side - the side to use for fitting. Either
        %                         lateral, medial or mean. 
        %                         (Default = lateral).

            n_temporal = 101;
            cut_length = 15;
            
            trial_size = (n_temporal - 2*cut_length);

            if nargin < 4
                anatomical_side = "lateral";
            end

            % for each of the good steps we want to save the x and z values
            point_cloud = zeros(length(good_steps)*trial_size, 2);
            for step_num=1:length(good_steps)
                step = good_steps(step_num);
                % ROS = step.ROS.(anatomical_side);
                ROS = obj.cop_to_shank_frame(step, anatomical_side);

                % add this step to the point cloud.
                point_cloud((1 + (step_num - 1)*trial_size):(step_num*trial_size), :) = [ROS.x(1+cut_length:end-cut_length)', ROS.z(1+cut_length:end-cut_length)'];
            end
            
            % Check for NaN or Inf values in the lateral point cloud
            num_NaNs = sum(isnan(point_cloud(:)));
            num_Inf = sum(isinf(point_cloud(:)));
            total_points = numel(point_cloud);
            if ((num_NaNs > 0) || (num_Inf > 0))
                if ((num_NaNs > 0.1*total_points) || (num_Inf > 0.1*total_points))
                    warning("ROSAnalyzer:PointCloud:TooManyNaNInfs", ...
                            "Too many NaNs or Infs in point cloud. More than 10\%.\n" +...
                            "Number of NaN values: %d out of %d\n" + ...
                            "Number of Inf values: %d out of %d\n", num_NaNs, total_points, num_Inf, total_points);
                end

                % Remove rows with NaN or Inf values
                point_cloud(any(isnan(point_cloud) | isinf(point_cloud), 2), :) = [];
            end
            
            % Add to point_clouds cell array. Each entry corresponds to the
            % entry number in the samples table and the
            if isempty(point_cloud)
                error("ROSAnalyzer:PointCloud:EmptyPointCloud", ...
                      "Something went wrong with the point cloud calculation. It is empty.")
            end
            obj.PointClouds(entry_number) = {point_cloud};
        end
        function populate_table(obj, dataset_id, start_row, anatomical_sides)
        %POPULATE_TABLE processes the dataset and adds new rows to 
        % samples table.
        %  Input :
        %   dataset_id - the ID of the dataset to add to the samples table. 
        %                A positive integer number.
        %   start_row - the row where the new data starts in samples table.
        %   anatomical_sides - which anatomical side to to use for the
        %                      samples table. either "lateral", "medial" or 
        %                      "mean".

            % Check that dataset is in data records.
            dataset = obj.get_dataset(dataset_id);
            if isempty(dataset)
                error("ROSAnalyzer:DataRecords:MissingDataset", ...
                      "Dataset %d not in data records.", dataset_id)
            end
            
            % Default anthropometric side is just lateral
            if nargin < 4
                anatomical_sides = "lateral";
            end

            % Check table is large enough for new data
            n_participants = length(dataset.Data);
            if size(obj.SamplesTable, 1) < start_row + obj.NUM_SIDES*n_participants - obj.get_num_ignored(dataset_id) - 1
                error("ROSAnalyzer:DataTable:NotEnoughRows", ...
                      "Not enough rows allocated to samples table.\n""" + ...
                      "Expected at least %d rows, but actual table size is %d", start_row + n_participants*2 - 1, size(obj.SamplesTable, 1));
            end
            
            % Loop over participants of dataset and process data of each
            % one
            entry_num = start_row;
            for participant_number=1:n_participants % get to each participant
                data = dataset.Data(participant_number);
                participant_id = data.Participant_id;
                processed_data = data.Processed_data;
                anthropometric_data = data.Anthropometric_data;

                for side=["right", "left"]
                    % Check in ignore list
                    if obj.is_ignored(dataset_id, participant_id, side)
                        continue
                    end

                    % Get data
                    steps = processed_data.(side).step; % get the steps
                    % Not all participants have measurements from both
                    % legs.
                    if isempty(steps)
                        continue
                    end

                    % Get rid of the steps with a speed that is too low (lower 
                    % than 2.5 km/hour)
                    good_steps = obj.get_good_steps(steps);%, 2.5);
                    % If in general they were too slow, good_steps is empty so
                    % ignore participant
                    if isempty(good_steps)
                        continue
                    end

                    % Get anthropometric data
                    [age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod] = obj.get_metadata(anthropometric_data, side); % get anthropometric data
                    
                    for anatomical_side=anatomical_sides
                        % Check if anatomical_side exists
                        if ~obj.has_medial(dataset_id) && anatomical_side == "medial"
                            continue
                        end

                        % Add trial parameters to data entry
                        obj.SamplesTable(entry_num, {'Dataset_id', 'Participant_id', 'Side', 'Anatomical_side'}) = {dataset_id, participant_id, side, anatomical_side};
    
                        % Add features to data entry
                        new_row_features = {age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod};
                        obj.SamplesTable(entry_num, {'Age', 'Gender', 'Height', 'Mass', 'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod'}) = new_row_features;
    
                        % Make all the "good steps" into a 2D point cloud in the XZ plane (the sagital plane)
                        obj.make_point_cloud(good_steps, entry_num, anatomical_side);
    
                        % Fit the point cloud to a circular arc
                        % (notice that the angles ang_start and ang_end are relative to a vector pointing straight down from the center of the arc)
                        % try
                        obj.fit_to_circular_arc(entry_num);
                        % catch ME
                            % disp(ME.message)
                            % error("something's wrong with the fit function")
                        % end
    
                        % Advance row number
                        entry_num = entry_num + 1;
                    end
                end
            end

            % Update size of populated portion of samples table
            % there are extra rows in table which are empty
            obj.SamplesTableSize = entry_num - 1;
        end
        function index = add_to_data_records(obj, dataset_name, dataset)
        %ADD_TO_DATA_RECORDS adds new dataset to data records.
        % Input : 
        %   dataset_name - the name of the dataset.
        %   dataset - the dataset to load.

            index = length(obj.DataRecords) + 1;
            dataset_id = obj.FirstUniqueDatasetId;
            obj.FirstUniqueDatasetId = obj.FirstUniqueDatasetId + 1;
            obj.DataRecordsIDLookup(dataset_id) = index;
            
            obj.DataRecords(index).Dataset_id = dataset_id;
            obj.DataRecords(index).Dataset_name = dataset_name;
            obj.DataRecords(index).Article_data = dataset.Article_data;
            obj.DataRecords(index).Lab_system = dataset.Lab_system;
            obj.DataRecords(index).Experiment_protocol = dataset.Experiment_protocol;
            
            participants = fieldnames(dataset.Data);
            n_participants = length(participants);
            obj.DataRecords(index).Data(n_participants) = struct;
            for participant_id = 1:n_participants
                participant_name = participants{participant_id};
                original_participant_name = dataset.Data.(participant_name).participant_ID_in_original_structure;
                processed_data = dataset.Data.(participant_name).processed_data;
                metadata = dataset.Data.(participant_name).metadata;

                obj.DataRecords(index).Data(participant_id).Participant_id = participant_id;
                obj.DataRecords(index).Data(participant_id).Participant_name = original_participant_name;
                obj.DataRecords(index).Data(participant_id).Anthropometric_data = metadata;
                obj.DataRecords(index).Data(participant_id).Processed_data = processed_data;
            end
        end
        function delete_from_data_records(obj, dataset_id, index)
            obj.DataRecords(index) = [];
            obj.DataRecordsIDLookup(dataset_id) = [];
            
            if numEntries(obj.DataRecordsIDLookup) > 0
                obj.DataRecordsIDLookup(obj.DataRecordsIDLookup.keys) = obj.DataRecordsIDLookup.values - 1; % Update remaining indices in lookup table
                obj.FirstUniqueDatasetId = max(obj.DataRecordsIDLookup.keys) + 1; % Update first unique ID NOTE: might not be needed
            else
                obj.FirstUniqueDatasetId = 1;
            end
        end
        function add_to_summary_table(obj, dataset_id)
            %ADD_TO_SUMMARY_TABLE adds new dataset info to summary table.
            % Input :
            %   dataset_id - the ID of the dataset in data records to add. 
            %                A positive integer number.
            
            dataset = obj.get_dataset(dataset_id);
            if isempty(dataset)
                error("ROSAnalyzer:DataRecords:MissingEntry", ...
                      "dataset entry %d doesn't exist in data records.", dataset_id)
            end
            
            % If summary table has no empty rows, allocate new row
            if obj.SummaryTableSize == height(obj.SummaryTable)
                new_table = table('Size', [1, width(obj.SummaryTable)], ...
                    'VariableTypes', varfun(@class, obj.SummaryTable, 'OutputFormat', 'cell'), ...
                    'VariableNames', obj.SummaryTable.Properties.VariableNames);
                obj.SummaryTable = [obj.SummaryTable; new_table];
            end

            % Set the entry number to the first empty row in the table
            entry_number = obj.SummaryTableSize + 1;
            obj.SummaryTableSize = obj.SummaryTableSize + 1;
            
            % Populate summary table
            obj.SummaryTable.Dataset_id(entry_number) = dataset_id;
            obj.SummaryTable.Dataset_name(entry_number) = dataset.Dataset_name;
            obj.SummaryTable.Article_name(entry_number) = dataset.Article_data.article_name;
            obj.SummaryTable.Authors(entry_number) = dataset.Article_data.authors;
            obj.SummaryTable.Article_url(entry_number) = dataset.Article_data.link_to_paper;
            obj.SummaryTable.Dataset_url(entry_number) = dataset.Article_data.link_to_dataset;
            obj.SummaryTable.Published_year(entry_number) = dataset.Article_data.published_year;
            obj.SummaryTable.Speed_categories(entry_number) = {dataset.Experiment_protocol.speed_categories};
            obj.SummaryTable.Num_participants(entry_number) = dataset.Experiment_protocol.num_participants;
            obj.SummaryTable.Num_forceplates(entry_number) = dataset.Lab_system.num_forceplates;

            % Example participant for existing data to check if participants are 
            % shod and medial markers exist
            participant = dataset.Data(1);
            obj.SummaryTable.Is_shod(entry_number) = participant.Anthropometric_data.Is_shod.value;
            if ~isempty(participant.Processed_data.right.step)
                step = participant.Processed_data.right.step(1);
            elseif ~isempty(participant.Processed_data.left.step)
                step = participant.Processed_data.left.step(1);
            end
            obj.SummaryTable.Has_medial(entry_number) = ~isempty(step.Markers.Ankle.medial);
        end
        function delete_from_summary_table(obj, index)
            obj.SummaryTable(index, :) = [];
            obj.SummaryTableSize = obj.SummaryTableSize - 1;
        end
        function add_to_samples_table(obj, dataset_id)
            %ADD_TO_SAMPLES_TABLE processes the dataset and adds to samples 
            % table.
            % Input :
            %   dataset_id - the ID of the dataset to add to the samples
            %                table. A positive integer number.

            % Get the dataset
            dataset = obj.get_dataset(dataset_id);

            % Calculate number of rows needed to add to table
            n_participants = length(dataset.Data);
            start_row = obj.SamplesTableSize + 1;
            if isempty(start_row)
                start_row = 1;
            end
            numRows = obj.NUM_SIDES*n_participants - (height(obj.SamplesTable) - obj.SamplesTableSize);
            ignore_num = obj.get_num_ignored(dataset_id);
            numRows = numRows - ignore_num;

            % Allocate new rows to samples table
            if numRows > 0
                new_table = table('Size', [numRows, width(obj.SamplesTable)], ...
                    'VariableTypes', replace(obj.SamplesTable.Properties.VariableTypes, 'double', 'doublenan'), ...
                    'VariableNames', obj.SamplesTable.Properties.VariableNames);
                obj.SamplesTable = [obj.SamplesTable; new_table];
            end

            % Add new data
            obj.populate_table(dataset_id, start_row);
        end
        function delete_from_samples_table(obj, varargin)
        %DELETE_FROM_SAMPLES_TABLE deletes the given entries from the samples 
        %DELETE_FROM_SAMPLES_TABLE deletes the sample entries from the 
        % samples table given the dataset IDs, participant IDs, sides and 
        % anatomical sides.
        % Input :
        %   dataset_id - the dataset ID for the requested entry. A positive 
        %                integer number. Could be a vector of IDs.
        %   participant_id - the participant ID for the requested entry. A 
        %                    positive integer number. Could be a vector of IDs.
        %                    Default: all participants of the dataset with 
        %                    ID dataset_id (except those ignored).
        %   side - the side for the requested entry. Could be a vector of both
        %          "left" and "right".
        %          Default: ["left", "right"].
        %   anatomical_side - the anatomical side for the requested entry. Could
        %                     be a vector of multiple anatomical sides.
        %                     Default: ["lateral", "medial", "mean"].
        % OR :
        %   entry_flag - 'e', indicates the samples are identified by entry.
        %   entry_numbers - entry numbers in table to delete.
        % Example usage :
        %   obj.delete_from_samples_table(1, [1 2 3], "left")
        %   obj.delete_from_samples_table(1)
        %   obj.delete_from_samples_table('e', [1 10 25])
            
            % Extract Inputs
            if length(varargin) == 2 && strcmp(varargin{1}, 'e')
                entry_numbers = varargin{2};
            else
                [~, entry_numbers] = obj.get_sample_entry(varargin{:});
            end

            if isempty(entry_numbers)
                return
            end
            obj.SamplesTable(entry_numbers, :) = [];
            obj.SamplesTableSize = obj.SamplesTableSize - length(entry_numbers);
            obj.PointClouds(entry_numbers) = [];
        end
        function add_to_ignore_list(obj, ignore)
        %ADD_TO_IGNORE_LIST
            % Check input format
            if all(size(ignore) == [1 3]) && ...
               (isStringScalar(ignore{1}) || (~ischar(ignore{1}) && isrow(ignore{1}))) && ...
               (isnumeric(ignore{2}) && isnumeric(ignore{3}))
                obj.IgnoreList(end, :) = ignore;
            else
                error("ROSAnalyzer:IgnoreList:WrongFormat", ...
                      "Ignore should be in the format: {""DB Name"", [participants_to_ignore_left], [participants_to_ignore_right]}")
            end
        end
        function tf = is_in_summary(obj, dataset_id)
        %IS_IN_SUMMARY returns whether the dataseit with ID dataset_id is in the
        % summary table.
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer
        %                number.
        % Output :
        %   tf - true (logical 1) if the dataset exists and false (logical 1)
        %        otherwise.
        
            tf =  ~isempty(find(obj.SummaryTable.Dataset_id == dataset_id, 1, 'first'));
        end
        function ignore_data(obj, ignore_list)
            % Delete sample table trials from ignore list
            obj.IgnoreList = ignore_list;
            for idx=1:height(ignore_list)
                dataset_id = ignore_list{idx, 1};
                participants_left = ignore_list{idx, 2};
                participants_right = ignore_list{idx, 3};
                obj.delete_from_samples_table(dataset_id, participants_left, "left");
                obj.delete_from_samples_table(dataset_id, participants_right, "right");
            end
        end
        function filter_data(obj, list, method)
            if nargin < 3
                method = "median";
            end

            % Filter outlier parameters
            idx = ismember(list, string(obj.SamplesTable.Properties.VariableNames));
            if ~any(idx)
                return
            end
            outliers = any(isoutlier(obj.get_sample_var(list(idx)), method), 2);
            entry_numbers = find(outliers);
            obj.delete_from_samples_table('e', entry_numbers)
         end
    end
    
    %% STATIC METHODS
    methods(Static)
        function [good_steps] = get_good_steps(steps, min_speed)
        %GET_GOOD_STEPS receives all the steps of the participant from a 
        % single side, and saves and returns only the steps with a speed 
        % higher than min_speed in [km/h]. By default min_speed = 2.5 [km/h]
        % -----------------------------------------------------------------

            % Set default value for min_speed
            if nargin == 1
                min_speed = 2.5; % [km/hr]
            end

            % good_steps = steps(steps(:).speed.km_per_hour.value >= min_speed);

            % start "good_steps" as having the same length as "steps":
            good_steps(length(steps)) = steps(1);
            counter = 1;
            for step_num=1:length(steps)
                step = steps(step_num);
                step_speed = step.speed.km_per_hour.value;
                if step_speed >= min_speed 
                    % add this step:
                    good_steps(counter) = step;
                    counter = counter + 1;
                end
            end

            % Remove unused elements from "good_steps":
            good_steps = good_steps(1:counter - 1);
        end
        function [age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod] = get_metadata(metadata, side)
        %GET_METADATA get anthropometric metadata parameters.
        % Input :
        %   metadata - struct with the anthropometric data of a participant.
        %   side - the side of the leg measurements (leg, thigh or shank 
        %          lengths) to return. Either"right" or "left".
        % Output :
        %   age - the participant's age in years.
        %   gender - the participant's gender (Male or Female).
        %   height - the participant's height in m.
        %   mass - the participant's weight in kg.
        %   leg_length - the participant's leg length in m of side "side".
        %   thigh_length - the participant's thigh length in m of side "side".
        %   shank_length - the participant's shank length in m of side "side".
        %   is_shod - whether the participant was shod (Yes) or barefoot (No).

            age = metadata.Age.value; assert(metadata.Age.unit == "years"); % [years]
            gender = categorical(metadata.Gender.value); % "Male" or "Female"
            height = metadata.Height.value; assert(metadata.Height.unit == "m"); % [m]
            mass = metadata.Mass.value; assert(metadata.Mass.unit == "kg"); % [kg]
            leg_length = metadata.Leg_length.(side).value; assert(metadata.Leg_length.unit == "m"); % [m]
            thigh_length = metadata.Thigh_length.(side).value; assert(metadata.Thigh_length.unit == "m"); % [m]
            shank_length = metadata.Shank_length.(side).value; assert(metadata.Shank_length.unit == "m"); % [m]
            is_shod = metadata.Is_shod.value; % "Yes" (shod) or "No" (barefoot)
        end
        function shank_cop = cop_to_shank_frame(step, anatomical_side)
        %COP_TO_SHANK_FRAME transforms the COP of the step to the shank
        % coordinate frame. The frame has the ankle as its origin with the
        % x direction pointing to the direction of walking, the z direction
        % is from the ankle to the knee (up) and the y direction completes
        % a right-handed system.
        % Input :
        %   step - the step data to transform. Includes COP and marker
        %          trajectories.
        %   anatomical_side - the anatomical side of the markers to use for 
        %                     the transformation.
        % Output :
        %   shank_cop - the COP in the Shank coordinate frame.

            % the new z direction is the direction from the ankle to the knee
            new_z = [(step.Markers.Knee.(anatomical_side).x - step.Markers.Ankle.(anatomical_side).x);...
                     (step.Markers.Knee.(anatomical_side).y - step.Markers.Ankle.(anatomical_side).y);...
                     (step.Markers.Knee.(anatomical_side).z - step.Markers.Ankle.(anatomical_side).z)];
            new_z = new_z./vecnorm(new_z);
            % the new y direction to the Left (in the mediolateral direction)
            new_y = 0.*new_z + [0; 1; 0];
            % and the new x is the cross product between them:
            new_x = cross(new_y, new_z);
            % the origin of the new coordinate system is the location of the ankle:
            new_origin = [step.Markers.Ankle.(anatomical_side).x; ...
                          step.Markers.Ankle.(anatomical_side).y; ...
                          step.Markers.Ankle.(anatomical_side).z];
            % get the original COP data:
            cop = [step.COP.x; step.COP.y; zeros(size(step.COP.z))];
            % now we will transform the COP into the new frame of reference in order to get the ROS.
            cop = cop - new_origin;
            shank_cop.x = dot(cop, new_x);
            shank_cop.y = dot(cop, new_y);
            shank_cop.z = dot(cop, new_z);

            is_in = ~isoutlier(shank_cop.x) & ~isoutlier(shank_cop.y) & ~isoutlier(shank_cop.z);
        end
 
    end
end