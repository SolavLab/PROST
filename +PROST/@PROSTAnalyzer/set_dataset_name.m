function set_dataset_name(obj, dataset_id, dataset_name)
%SET_DATASET_NAME sets the name of the dataset with the given
% dataset ID to the new name.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
%   dataset_name - the new name to set.

    if ~obj.dataset_exists(dataset_id)
        error(PROST.PROSTError("DataRecords", "MissingDataset", ...
            "Dataset %d not in data records.", dataset_id));
    end
    index = obj.DataRecordsIDLookup(dataset_id);
    obj.DataRecords(index).Dataset_name = dataset_name;
end