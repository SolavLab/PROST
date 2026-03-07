function tf = dataset_exists(obj, dataset_id)
%DATASET_EXISTS returns whether the dataset with the ID dataset_id
% exists in the data records.
% Input :
%   dataset_id - the ID of the dataset to check. A positive integer
%                number.
% Output :
%   tf - true (logical 1) if the dataset exists and false (logical 1)
%        otherwise.

    if isscalar(dataset_id) && isnumeric(dataset_id) && dataset_id > 0 && dataset_id == floor(dataset_id)
        tf = isKey(obj.DataRecordsIDLookup, dataset_id);
    else
        throw(PROST.PROSTError("DatasetID", "WrongFormat",...
            "Dataset ID should be a positive integer number."));
    end
end