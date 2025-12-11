function tf = is_in_summary_table(obj, dataset_id)
%IS_IN_SUMMARY_TABLE returns whether a dataset is in the summary table.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
% Output :
%   tf - true (logical 1) if the dataset has an entry in the summary
%        table and false (logical 0) otherwise.

    if isscalar(dataset_id) && isnumeric(dataset_id) && dataset_id > 0 && dataset_id == floor(dataset_id)
        tf = ismember(obj.SummaryTable.Dataset_id, dataset_id);
    else
        error(PROST.PROSTError("DatasetID", "WrongFormat",...
            "Dataset ID should be a positive integer number."));
    end
end
