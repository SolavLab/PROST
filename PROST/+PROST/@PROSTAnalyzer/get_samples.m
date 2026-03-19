function [samples, row_numbers, var_names] = get_samples(obj, var_list, varargin)
%GET_SAMPLES returns a table with the sample entries and row numbers from the 
% samples table. 
% Either the specified variables in 'var_list' or specified rows defined
% by 'dataset_id', 'participant_id', and 'side' or a combination of them.
% Only returns the variables and rows that exist in the samples table.
% Returns empty table and empty array if the specified variables or entries
% don't exist.
% Input :
%   var_list - the variable name or list of variable names. Must be a
%              string array or character cell array.
%   dataset_id - the dataset ID for the requested entries. A positive
%                integer number. Could be a vector of IDs.
%   participant_id - the participant ID for the requested entry. A
%                    positive integer number. Could be a vector of IDs.
%                    Default: all participants of the dataset with
%                    ID dataset_id included in the samples data.
%   side - the side for the requested entry. Either "left", "right" or a
%          vector containing both "left" and "right" (default).
% Output :
%   samples - the entries in the samples table.
%   row_numbers - the row numbers of the entries in the samples table.
%   var_names - the names of the variables that are returned.
% Usage :
%   get_samples(var_list, dataset_id, participant_id, side)
%   get_samples(var_list, dataset_id, participant_id)
%   get_samples(var_list, dataset_id)
%   get_samples(var_list)
%   get_samples([], dataset_id, participant_id, side)
%   get_samples([], dataset_id, participant_id)
%   get_samples([], dataset_id)

    row_numbers = 1:obj.SamplesTableSize;
    var_names = string(obj.SamplesTable.Properties.VariableNames);
    if nargin > 2 && ~isempty(varargin)
        [~, row_numbers] = obj.get_sample_entry(varargin{:});
    end
    if ~isempty(var_list)
        [~, var_names] = obj.get_sample_var(var_list);
    end
    samples = obj.SamplesTable(row_numbers, var_names);
end