function dataset_id = add_dataset(obj, dataset_name, dataset, participants_to_ignore_left, participants_to_ignore_right)
%ADD_DATASET Adds a new dataset to data_records and to the feature
% table.
% Input :
%   dataset_name - the name of the dataset to add.
%   dataset - the dataset struct to add.
%   participants_to_ignore_left, participants_to_ignore_right -
%   vectors of participant numbers to ignore for left and right
%   steps respectively.
% Output :
%   dataset_id - the unique ID of the added dataset.

    disp("Adding dataset " + dataset_name + "...")

    % Add to data records
    dataset_id = obj.add_to_data_records(dataset_name, dataset);

    % Add to summary table
    obj.add_to_summary_table(dataset_id);

    % Add to samples table
    obj.add_samples(dataset_id);

    % Add to ignore list if there are participants to ignore
    if nargin == 4
        participants_to_ignore_right = [];
    end
    if nargin > 3 && (~isempty(participants_to_ignore_left) || ~isempty(participants_to_ignore_right))
        obj.add_to_ignore_list({dataset_id, participants_to_ignore_left, participants_to_ignore_right});
    end

end