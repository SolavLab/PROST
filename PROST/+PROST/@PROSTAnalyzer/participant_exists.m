function tf = participant_exists(obj, dataset_id, participant_id)
%PARTICIPANT_EXISTS returns whether the participant with the ID
% 'participant_id' of the dataset with ID 'dataset_id' exists in the
% data records.
% Input :
%   dataset_id - the ID of the dataset to check. A positive integer
%                number.
%   participant_id - the ID of the participant to check. A positive
%                    integer number.
% Output :
%   tf - true (logical 1) if the participant exists in the dataset and
%        false (logical 1) otherwise.

    if ~obj.dataset_exists(dataset_id)
        throw(PROST.PROSTError("DataRecords", "MissingDataset", ...
            "Dataset %d not in data records.", dataset_id));
    end
    if isscalar(participant_id) && isnumeric(participant_id) && participant_id > 0 && participant_id == floor(participant_id)
        index = obj.DataRecordsIDLookup(dataset_id);
        participants = [obj.DataRecords(index).Data(:).Participant_id];
        tf = ismember(participant_id, participants);
    else
        throw(PROST.PROSTError("ParticipantID", "WrongFormat",...
            "Participant ID should be a positive integer number."));
    end

end