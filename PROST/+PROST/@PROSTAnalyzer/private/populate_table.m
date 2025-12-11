function populate_table(obj, dataset_id, start_row, anatomical_side)
%POPULATE_TABLE processes the dataset and adds new rows to
% samples table.
%  Input :
%   dataset_id - the ID of the dataset to add to the samples table.
%                A positive integer number.
%   start_row - the row where the new data starts in samples table.
%   anatomical_side - which anatomical side to to use for the
%                     samples table. Either "lateral" (default),
%                     "medial" or "mean".

    % Get dataset
    dataset = obj.get_dataset(dataset_id);

    % Default anthropometric side is just lateral
    if nargin < 4
        anatomical_side = "lateral";
    end

    % Check table is large enough for new data
    n_participants = length(dataset.Data);
    if size(obj.SamplesTable, 1) < start_row + obj.NUM_SIDES*n_participants - 1
        error(PROST.PROSTError("SamplesTable", "AllocationError", ...
            "Not enough rows allocated to samples table.\n""" + ...
            "Expected at least %d rows, but actual table size is %d", start_row + obj.NUM_SIDES*n_participants - 1, size(obj.SamplesTable, 1)));
    end

    % Check if anatomical_side exists
    if ~obj.has_medial(dataset_id) && anatomical_side == "medial"
        error(PROST.PROSTError("SamplesTable", "MissingMedial", ...
            "Dataset does not contain medial markers."));
    end

    % Loop over participants of dataset and process data of each
    % one
    row_num = start_row;
    for participant_number=1:n_participants % get to each participant
        data = dataset.Data(participant_number);
        participant_id = data.Participant_id;
        processed_data = data.Processed_data;
        anthropometric_data = data.Anthropometric_data;

        for side=["right", "left"]
            % Get data
            steps = processed_data.(side).step; % get the steps
            % Not all participants have measurements from both
            % legs.
            if isempty(steps)
                continue
            end

            % Get rid of the steps with a speed that is too low or that
            % should be ignored
            good_steps = PROST.PROSTAnalyzer.get_good_steps(steps);%, 2.5);

            % If in general they were too slow, good_steps is empty so
            % ignore participant
            if isempty(good_steps)
                continue
            end

            % Get anthropometric data
            [age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod] = PROST.PROSTAnalyzer.get_metadata(anthropometric_data, side); % get anthropometric data

            % Add trial parameters to data entry
            obj.SamplesTable(row_num, {'Dataset_id', 'Participant_id', 'Side', 'Anatomical_side'}) = {dataset_id, participant_id, side, anatomical_side};

            % Add features to data entry
            new_row_features = {age, gender, height, mass, leg_length, thigh_length, shank_length, is_shod};
            obj.SamplesTable(row_num, {'Age', 'Gender', 'Height', 'Mass', 'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod'}) = new_row_features;

            % Make all the "good steps" into a 2D point cloud in the XZ plane (the sagital plane)
            obj.make_point_cloud(dataset_id, participant_id, side, good_steps, row_num, anatomical_side);

            % Fit the point cloud to a circular arc
            % (notice that the angles ang_start and ang_end are relative to a vector pointing straight down from the center of the arc)
            obj.fit_to_circular_arc(row_num);

            % Advance row number
            row_num = row_num + 1;
        end
    end

    % Update size of populated portion of samples table
    % there are extra rows in table which are empty
    obj.SamplesTableSize = row_num - 1;
end