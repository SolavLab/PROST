function [samples, row_numbers] = get_sample_entry(obj, dataset_id, participant_id, side)
%GET_SAMPLE_ENTRY returns the sample entries and row numbers from the
% samples table given the dataset IDs, participant IDs and sides.
% Returns empty table and empty array if does not exist.
% Input :
%   dataset_id - the dataset ID for the requested entries. A positive
%                integer number. Leave empty for all datasets.
%   participant_id - the participant ID for the requested entry. A
%                    positive integer number. Could be a vector of IDs.
%                    Default: all participants of the dataset with
%                    ID dataset_id.
%   side - the side for the requested entry. Either "left", "right" or a
%          vector containing both "left" and "right" (default).
% Output :
%   samples - the entries in the samples table.
%   row_numbers - the row numbers of the entries in the samples table.

    if nargin < 2 || isempty(dataset_id)
        row_numbers = 1:obj.SamplesTableSize;
        samples = obj.SamplesTable(row_numbers, :);
    else
        row_numbers = 1:obj.SamplesTableSize;
        samples = obj.SamplesTable(obj.SamplesTable.Dataset_id == dataset_id, :);
    end
    if nargin < 4
        side = ["left" "right"];
    end
    if nargin < 3 || isempty(participant_id)
        if ~obj.dataset_exists(dataset_id)
            row_numbers = [];
            samples = table;
            return
        end
        dataset = obj.get_dataset(dataset_id);
        participant_id = [dataset.Data(:).Participant_id];
    end

    side_rows = ismember(obj.SamplesTable.Side, side);
    participant_rows = ismember(obj.SamplesTable.Participant_id, participant_id);
    dataset_rows = ismember(obj.SamplesTable.Dataset_id, dataset_id);
    row_numbers = find(dataset_rows & participant_rows & side_rows);
    if isempty(row_numbers)
        samples = table;
    else
        samples = obj.SamplesTable(row_numbers, :);
    end
end