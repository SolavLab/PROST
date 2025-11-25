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
    obj.delete_samples(dataset_id);

end