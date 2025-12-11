function set_dataset(obj, dataset_id, dataset)
%SET_DATASET sets the dataset object with the given ID in the data
% records. If there is no dataset with the ID, raises error.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
%   dataset - the dataset object.

    if ~obj.dataset_exists(dataset_id)
        error(PROST.PROSTError("DataRecords", "MissingDataset", ...
            "Dataset %d not in data records.", dataset_id));
    end
    index = obj.DataRecordsIDLookup(dataset_id);
    obj.DataRecords(index) = dataset;
end
