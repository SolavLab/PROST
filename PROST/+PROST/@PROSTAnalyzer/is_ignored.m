function tf = is_ignored(obj, dataset_id, participant_id, trials, side)
%IS_IGNORED Returns whether a dataset, a participant or trials of a
% participant are in the ignore list and should be ignored.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
%   participant_id - the ID of the participant for the given
%                    dataset. A positive integer number.
%   trials - the trials of the participant. A vector of positive integer
%            numbers.
%   side - the side of the trials to delete. Either "left" or "right".
% Output :
%   tf - logical 1 (true) if trials should be ignored and logical 0
%        (false) otherwise.


    % Check if ignore_list exists
    if isempty(obj.IgnoreObject)
        tf = false;
        return
    end

    % Is specific dataset ignored
    if nargin == 2
        tf = obj.IgnoreObject.is_in_list_dataset(dataset_id);
        return
    end

    % Is specific participant ignored
    if nargin == 3
        tf = obj.IgnoreObject.is_in_list_participants(dataset_id, participant_id);
        return
    end

    % Are specific trials ignored
    side = PROST.utils.capitalize(side);
    tf = obj.IgnoreObject.is_in_list_trials(dataset_id, participant_id, trials, side);
end