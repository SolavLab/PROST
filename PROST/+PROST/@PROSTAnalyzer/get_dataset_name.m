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
        dataset_name = missing;
    end
end