function dataset = get_dataset(obj, dataset_id)
%GET_DATASET returns the dataset object from the data records with
% the given ID. If there is no dataset with the ID, raises an error.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
% Output :
%   dataset - the dataset in the data records. Empty struct if
%             doesn't exist.

    if ~obj.dataset_exists(dataset_id)
        throw(PROST.PROSTError("DataRecords", "MissingDataset", ...
            "Dataset %d not in data records.", dataset_id));
    end
    index = obj.DataRecordsIDLookup(dataset_id);
    dataset = obj.DataRecords(index);
end