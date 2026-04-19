function add_to_samples_table(obj, dataset_id)
%ADD_TO_SAMPLES_TABLE processes the dataset and adds to samples table.
% Input :
%   dataset_id - the ID of the dataset to add to the samples
%                table. A positive integer number.

    % Get the dataset
    dataset = obj.get_dataset(dataset_id);
    dataset_name = dataset.Dataset_name;
    fprintf("Adding dataset %s to samples table...\n", dataset_name);
    % Calculate number of rows needed to add to table
    n_participants = length(dataset.Data);
    start_row = obj.SamplesTableSize + 1;
    if isempty(start_row)
        start_row = 1;
    end
    numRows = obj.NUM_SIDES*n_participants - (height(obj.SamplesTable) - obj.SamplesTableSize);

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