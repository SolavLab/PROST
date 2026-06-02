function delete_from_data_records(obj, dataset_id)
%DELETE_FROM_DATA_RECORDS deletes the dataset with the given ID from the data records and updates the lookup table.
% Input :
%   dataset_id - the ID of the dataset to delete. A positive integer number.

    dataset_index = obj.DataRecordsIDLookup(dataset_id);
    obj.DataRecords(dataset_index) = [];
end