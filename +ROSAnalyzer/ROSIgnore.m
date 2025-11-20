classdef ROSIgnore < handle
    properties(Access=public)
        IgnoreList = struct([]);
        DatasetIDLookup = configureDictionary("double", "double"); % Lookup dataset_id -> index
    end
    methods
        function ig = ROSIgnore() 
        end

        function add_ignored(ig, dataset_id, participants, trials, side)
        %ADD_IGNORED adds the 'trials' of 'participants' in 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset to ignore. A positive integer 
        %                number.
        %   participants - the ID or IDs of the participants to ignore. A 
        %                  positive integer number or vector of integer numbers. 
        %   trials - the trials to add for each participant of the dataset. A
        %            vector of positive integer numbers.
        %   side - the side of the trials to add. Either 'Left' or 'Right'. If 
        %          missing then adds to both Left and Right.
        % Usage :
        %   add_ignored(dataset_id, participants, trials, side)
        %   add_ignored(dataset_id, participants, trials)
        %   add_ignored(dataset_id, participants, trials, [])
        %   add_ignored(dataset_id, participants, [], side)

            if ~ig.is_ignored_dataset(dataset_id)
                dataset_index = length(ig.IgnoreList) + 1;
                ig.DatasetIDLookup(dataset_id) = dataset_index;
                ig.IgnoreList(dataset_index).Dataset_id = dataset_id;
                ig.IgnoreList(dataset_index).ParticipantIDLookup = configureDictionary("double", "double"); % Lookup dataset_id -> index
                ig.IgnoreList(dataset_index).Participants = struct([]);
            else
                dataset_index = ig.DatasetIDLookup(dataset_id);
            end
            
            % if ~ismember('ParticipantIDLookup', fieldnames(obj.IgnoreList(index)))
            %     obj.IgnoreList(index).ParticipantIDLookup = configureDictionary("double", "double"); % Lookup dataset_id -> index
            % end
            
            if nargin == 4 || isempty(side) || ismissing(side)
                side = ["Right" "Left"];
            end
            side = convertCharsToStrings(side);
            
            if ~isstring(side) || (length(side) ~= 1 && length(side) ~= 2) || ...
               ~all(strcmp(side, "Left") | strcmp(side, "Right"))
                error("ROSIgnore:WrongFormat", "'side' should be either 'Left' or 'Right' or both.")
            end

            n_participants = length(participants);
            for pdx=1:n_participants
                participant_id = participants(pdx);

                if ~ig.is_ignored_participants(dataset_id, participant_id)
                    participant_index = length(ig.IgnoreList(dataset_index).Participants) + 1;
                    ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id) = participant_index;
                    ig.IgnoreList(dataset_index).Participants(participant_index).Participant_id = participant_id;
                    ig.IgnoreList(dataset_index).Participants(participant_index).Left = [];
                    ig.IgnoreList(dataset_index).Participants(participant_index).Right = [];
                else
                    participant_index = ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id);
                end

                for s=side
                    if isempty(trials)
                         ig.IgnoreList(dataset_index).Participants(participant_index).(s) = Inf;
                    else
                        ig.IgnoreList(dataset_index).Participants(participant_index).(s) = unique([ig.IgnoreList(dataset_index).Participants(participant_index).(s) trials]);
                    end
                end
            end
        end
        
        function delete_ignored(ig, dataset_id, participants, trials, side)
        %DELETE_IGNORED deletes the 'trials' of 'participants' in 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset in the ignore list. A positive 
        %                integer number.
        %   participants - the ID or IDs of the participants in the ignore list.
        %                  A positive integer number or vector of integer
        %                  numbers. If missing, then deletes the entire dataset.
        %   trials - the trials to delete for each participant of the dataset. A
        %            vector of positive integer numbers. If missing then deletes
        %            the participant.
        %   side - the side of the trials to delete. Either 'Left' or 'Right'.
        % Usage :
        %   delete_ignored(dataset_id, participants, trials, side)
        %   delete_ignored(dataset_id, participants, trials)
        %   delete_ignored(dataset_id, participants, trials, [])
        %   delete_ignored(dataset_id, participants, [], side)
        %   delete_ignored(dataset_id)
        %   delete_ignored(dataset_id, participants, [], side)
        
            if ~ig.is_ignored_dataset(dataset_id)
                return
            end
            dataset_index = ig.DatasetIDLookup(dataset_id);

            if nargin == 2
                ig.IgnoreList(dataset_index) = [];
                ig.DatasetIDLookup(dataset_id) = [];
                if numEntries(ig.DatasetIDLookup) > 0
                    keys = ig.DatasetIDLookup.keys';
                    values = ig.DatasetIDLookup.values';
                    idx = values > dataset_index;
                    ig.DatasetIDLookup(keys(idx)) = values(idx) - 1; % Update remaining indices in lookup table
                end
                return
            end

            tf = ig.is_ignored_participants(dataset_id, participants);
            ignored_participants = participants(tf);
            if isempty(ignored_participants)
                return
            end
            n_participants = length(ignored_participants);

            if nargin == 3
                for pdx=1:n_participants
                    participant_id = ignored_participants(pdx);
                    participant_index = ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id);
                    ig.IgnoreList(dataset_index).Participnats(participant_index) = [];
                    ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id) = [];
                    if numEntries(ig.IgnoreList(dataset_index).ParticipantIDLookup) > 0
                        keys = ig.IgnoreList(dataset_index).ParticipantIDLookup.keys';
                        values = ig.IgnoreList(dataset_index).ParticipantIDLookup.values';
                        idx = values > participant_index;
                        ig.IgnoreList(dataset_index).ParticipantIDLookup(keys(idx)) = values(idx) - 1; % Update remaining indices in lookup table
                    end
                end
                return
            end
            
            if nargin == 4 || isempty(side) || ismissing(side)
                side = ["Right" "Left"];
            end
            
            for pdx=1:n_participants
                participant_id = ignored_participants(pdx);
                participant_index = ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id);
                for s=side
                    if isempty(trials)
                        ig.IgnoreList(dataset_index).Participnats(participant_index).(s) = [];
                    else
                        tf = ig.is_ignored_trials(ig, dataset_id, participant_id, trials, s);
                        ig.IgnoreList(dataset_index).Participnats(participant_index).(s)(tf) = [];
                    end
                end
            end
        end

        function tf = is_ignored_dataset(ig, dataset_id)
        %IS_IGNORED_DATASET returns logical 1 (true) if the dataset with ID 
        % 'dataset_id' is in the ignored list. Otherwise, returns logical 0
        % (false).
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        % Output :
        %   tf - is logical 1 (true) if the dataset is in the ignore list, and
        %        otherwise is logical 0 (false).

            if ~isnumeric(dataset_id) || ~isscalar(dataset_id) || dataset_id <= 0 || dataset_id ~= floor(dataset_id)
                error("ROSIgnore:WrongFormat", "Dataset ID should be a positive integer.")
            end
            if ~isKey(ig.DatasetIDLookup, dataset_id)
                tf = false;
            else
                tf = true;
            end
        end

        function tf = is_ignored_participants(obj, dataset_id, participants)
        %IS_IGNORED_PARTICIPANTS returns an array containing logical 1 (true) 
        % where the participant in 'participants' of the dataset with ID 
        % 'dataset_id' is in the ignore list. Elsewhere, the array contains 
        % logical 0 (false).
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        %   participants - the ID or IDs of the participants to check. A 
        %                  positive integer number or vector of integer numbers. 
        %                  If missing, then deletes the entire dataset.
        % Output :
        %   tf - a logical array of the same size as 'participants' containing 
        %        logical 1 (true) wherever the values in 'participants' are in
        %        the ignore list. Elsewhere, it contains logical 0 (false).

            if ~isnumeric(participants) || ~isvector(participants) || any(participants <= 0) || any(participants ~= floor(participants))
                error("ROSIgnore:WrongFormat", "'participants' should be a positive integer or vector of positive integers.")
            end
            if ~obj.is_ignored_dataset(dataset_id)
                error("ROSIgnore:MissingDataset", "Dataset %d doesn't exist.", dataset_id)
            end
            dataset_index = obj.DatasetIDLookup(dataset_id);
            
            tf = isKey(obj.IgnoreList(dataset_index).ParticipantIDLookup, participants);
        end

        function tf = is_ignored_trials(ig, dataset_id, participant_id, trials, side)
        %IS_IGNORED_TRIALS returns an array containing logical 1 (true) where 
        % 'trials' is in the ignore list. Elsewhere, the array contains logical 
        % 0 (false). The trials are of 'side' of the participant with ID
        % 'participant_id' in the dataset with ID 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        %   participant_id - the ID of the participant to check. A positive 
        %                    integer number.
        %   trials - the trials to check. A vector of positive integer numbers.
        %   side - the side of the trials to check. Either 'Left' or 'Right'.
        % Output :
        %   tf - a logical array of the same size as 'trials' containing 
        %        logical 1 (true) wherever the values in 'trials' are in
        %        the ignore list. Elsewhere, it contains logical 0 (false).

            if ~isnumeric(trials) ||  ~isvector(trials) || any(trials <= 0) || any(trials ~= floor(trials))
                error("ROSIgnore:WrongFormat", "'trials' should be a positive integer or vector of positive integers.")
            end
            if ~strcmp(side, "Left") && ~strcmp(side, "Right")
                error("ROSIgnore:WrongFormat", "'side' should be either 'Left' or 'Right'.")
            end
            if ~isscalar(participant_id)
                error("ROSIgnore:WrongFormat", "Participant ID should be a scalar value.")
            end
            if ~ig.is_ignored_participants(dataset_id, participant_id)
                error("ROSIgnore:MissingParticipant", "Participant %d in dataset %d doesn't exist.", participant_id, dataset_id)
            end

            participant_index = ig.IgnoreList(dataset_index).ParticipantIDLookup(participant_id);
            if isinf(ig.IgnoreList(dataset_index).Participants(participant_index).(side))
                tf = true;
            else
                tf = ismember(trials, ig.IgnoreList(dataset_index).Participants(participant_index).(side));
            end
        end
    end
end
