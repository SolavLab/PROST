function tf = is_in_IPD_table(obj, dataset_id, participant_id, side)
%IS_IN_IPD_TABLE returns whether a trial is in the IPD table. A
% trial is a combination of 'dataset_id', 'participant_id' and 'side'.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
%   participant_id - the ID of the participant for the given dataset. A
%                    positive integer number.
%   side - Either "left" or "right" or a vector containing both "left"
%          and "right" (default).
% Output :
%   tf - true (logical 1) if trial is in the IPD table and false
%        (logical 0) otherwise.

    if nargin < 4
        side = ["left" "right"];
    end
    if nargin < 3
        if ~obj.dataset_exists(dataset_id)
            tf = false;
            return
        end
        dataset = obj.get_dataset(dataset_id);
        participant_id = [dataset.Data(:).Participant_id];
    end
    
    side_rows = ismember(obj.IPDTable.Side, side);
    participant_rows = ismember(obj.IPDTable.Participant_id, participant_id);
    dataset_rows = ismember(obj.IPDTable.Dataset_id, dataset_id);
    row_numbers = find(dataset_rows & participant_rows & side_rows, 1, 'first');
    tf = isempty(row_numbers);
end