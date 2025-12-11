function [summary, entry_number] = get_summary_entry(obj, dataset_id)
%GET_DATA_SUMMARY_ENTRY returns the entry number in the data
% summary table from the dataset ID. If there is no dataset with
% the given ID, returns an empty table and NaN.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
% Output :
%   summary - the entry in the summary table. Empty table if
%             doesn't exist.
%   entry_number - the row number in the summary table of the
%                  entry. NaN if entry doesn't exist.

    entry_number = find(obj.SummaryTable.Dataset_id == dataset_id);
    if isempty(entry_number)
        summary = table;
        entry_number = NaN;
    else
        summary = obj.SummaryTable(entry_number, :);
    end
end