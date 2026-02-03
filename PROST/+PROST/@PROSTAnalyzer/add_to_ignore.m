function add_to_ignore(obj, dataset_id, participants, trials, side)
%ADD_TO_IGNORE a wrapper function that adds the 'trials' of
% 'participants' in 'dataset_id' to the ignore list.
% Input :
%   dataset_id - the ID of the dataset. A positive integer number.
%   participants - the ID or IDs of the participants. A positive integer
%                  number or vector of integer numbers.
%   trials - the trials for each participant of the dataset. A vector of
%            positive integer numbers.
%   side - the side of the trials. Either "left" or "right". If missing
%          then adds to both Left and Right.

    side = PROST.utils.capitalize(side);
    obj.IgnoreObject.add_to_list(dataset_id, participants, trials, side);
end