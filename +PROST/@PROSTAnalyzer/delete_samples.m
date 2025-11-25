function delete_samples(obj, flag, varargin)
%DELETE_SAMPLES deletes the sample entries from the samples table given
% the dataset IDs, participant IDs, sides.
% Input :
%   flag - indicates whether the samples are identified by row_number or
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
%   row_number - row numbers in samples table to delete.
% Usage :
%   delete_from_samples_table(1, [1 2 3], "left")
%   delete_from_samples_table(1)
%   delete_from_samples_table('r', [1 10 25])


    % Extract Inputs
    if strcmp(flag, 'r')
        row_numbers = varargin;
    elseif strcmp(flag, 'i')
        [~, row_numbers] = obj.get_sample_entry(varargin{:});
    end

    if isempty(row_numbers)
        return
    end
    dataset_name = unique(obj.SamplesTable.Dataset_name(row_numbers));
    disp("Deleting dataset " + join(dataset_name, ", ") + " from samples table...")
    obj.SamplesTable(row_numbers, :) = [];
    obj.SamplesTableSize = obj.SamplesTableSize - length(row_numbers);
    obj.PointClouds(row_numbers) = [];
end