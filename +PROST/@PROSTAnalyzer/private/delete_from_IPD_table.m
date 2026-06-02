function delete_from_IPD_table(obj, flag, varargin)
%DELETE_FROM_IPD_TABLE deletes the entries from the IPD table given the 
% entry identifiers.
% Input :
%   flag - indicates whether the entries are identified by row number or
%          by ('dataset_id', 'participant_id', 'side'). 'r' for row
%          number, 'i' for IDs.
%   dataset_id - the dataset ID for the requested entry. A positive
%                integer number. Could be a vector of IDs.
%   participant_id - the participant ID for the requested entry. A
%                    positive integer number. Could be a vector of IDs.
%                    Default: all participants of the dataset with
%                    ID dataset_id (except those ignored).
%   side - the side for the requested entry. Could be a vector of both
%          "left" and "right".
%          Default: ["left", "right"].
%   anatomical_side - the anatomical side for the requested entry. Could
%                     be a vector of multiple anatomical sides.
%                     Default: "lateral".
%   row_number - row numbers in IPD table to delete.
% Usage :
%   delete_from_IPD_table(1, [1 2 3], "left")
%   delete_from_IPD_table(1)
%   delete_from_IPD_table('r', [1 10 25])


    % Extract Inputs
    if strcmp(flag, 'r')
        row_numbers = varargin;
    elseif strcmp(flag, 'i')
        [~, row_numbers] = obj.get_IPD_samples_by_entry(varargin{:});
    else
        PROST.PROSTError("IPDTable", "InvalidIdentifierFlag", ...
            "%s is not a valid flag for identifying entries. Must be 'r' or 'i'.", flag)
    end

    if isempty(row_numbers)
        return
    end
    dataset_name = unique(obj.IPDTable.Dataset_name(row_numbers));
    fprintf("Deleting datasets: %s from IPD table...\n", join(dataset_name, ", "));
    obj.IPDTable(row_numbers, :) = [];
    obj.IPDTableSize = obj.IPDTableSize - length(row_numbers);
    obj.PointClouds(row_numbers) = [];
end