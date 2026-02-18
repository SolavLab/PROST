function dataset_id = add_dataset(obj, dataset_name, dataset)
%ADD_DATASET Adds a new dataset to this object by adding it to the data records,
% updating the summary table, and populating the samples table.
% Input :
%   dataset_name - the name of the dataset to add.
%   dataset - struct containing dataset data in a uniform internal format.
% Output :
%   dataset_id - a generated unique ID of the added dataset. A positive integer 
%                number.
% NOTE:
% Internal dataset indices are assigned in add_to_data_records and are
% shared across data records and summary tables. DataRecordsIDLookup
% provides the authoritative mapping from public dataset_id to internal
% index.

    fprintf("Adding dataset %s...\n", dataset_name);
    
    dataset_id = obj.add_to_data_records(dataset_name, dataset);
    obj.add_to_summary_table(dataset_id);
    obj.add_samples(dataset_id);
end