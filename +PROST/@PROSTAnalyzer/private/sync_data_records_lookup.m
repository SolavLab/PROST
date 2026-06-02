function sync_data_records_lookup(obj, dataset_id)
    dataset_index = obj.DataRecordsIDLookup(dataset_id);
    obj.DataRecordsIDLookup(dataset_id) = [];

    if numEntries(obj.DataRecordsIDLookup) > 0
        keys = obj.DataRecordsIDLookup.keys';
        values = obj.DataRecordsIDLookup.values';
        idx = values > dataset_index;
        obj.DataRecordsIDLookup(keys(idx)) = values(idx) - 1; % Update remaining indices in lookup table
        obj.FirstUniqueDatasetId = max(obj.DataRecordsIDLookup.keys) + 1; % Update first unique ID NOTE: might not be needed
    else
        obj.FirstUniqueDatasetId = 1;
    end
end
