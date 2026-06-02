function add_to_IPD_table(obj, dataset_id)
%ADD_TO_IPD_TABLE processes the dataset and adds to IPD table.
% Input :
%   dataset_id - the ID of the dataset to add to the IPD table. A positive 
%                integer number.

    % Get the dataset
    dataset = obj.get_dataset(dataset_id);
    dataset_name = dataset.Dataset_name;
    fprintf("Adding dataset %s to IPD table...\n", dataset_name);
    % Calculate number of rows needed to add to table
    n_participants = length(dataset.Data);
    start_row = obj.IPDTableSize + 1;
    if isempty(start_row)
        start_row = 1;
    end
    n_rows = obj.NUM_SIDES*n_participants - (height(obj.IPDTable) - obj.IPDTableSize);

    % Allocate new rows to IPD table
    if n_rows > 0
        new_table = table('Size', [n_rows, width(obj.IPDTable)], ...
            'VariableTypes', replace(obj.IPDTable.Properties.VariableTypes, 'double', 'doublenan'), ...
            'VariableNames', obj.IPDTable.Properties.VariableNames);
        obj.IPDTable = [obj.IPDTable; new_table];
    end

    % Add new data
    obj.populate_table(dataset_id, start_row);
end