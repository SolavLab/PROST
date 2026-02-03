classdef PROSTDatasetList < handle
    properties(Access=public)
        List = struct([]);
        DatasetID2IndexLookup = configureDictionary("double", "double"); % Lookup dataset_id -> index
    end
    methods
        function ig = PROSTDatasetList() 
        %PROSTDatasetList default constructor
        end

        function add_to_list(ig, dataset_id, participants, trials, side)
        %ADD_TO_LIST adds the dataset with ID 'dataset_id' to the list, or the
        % participant\s with ID 'participants' of that dataset or 'trials' of
        % 'side' of 'participants' in 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset. A positive integer number.
        %   participants - the ID or IDs of the participants. A positive integer 
        %                  number or vector of positive integer numbers. If
        %                  missing, all participants of 'dataset_id' are added
        %                  to the list.
        %   trials - the trials to add for each participant of the dataset. A
        %            vector of positive integer numbers. If missing, then all
        %            trials for 'side' of the participant of 'dataset_id' are 
        %            added to the list.
        %   side - the side of the trials to add. Either 'Left' or 'Right'. If 
        %          missing then adds to both Left and Right.
        % Usage :
        %   ig.add_to_list(dataset_id, participants, trials, side)
        %   ig.add_to_list(dataset_id, participants, trials)
        %   ig.add_to_list(dataset_id, participants, [], side)
        %   ig.add_to_list(dataset_id, participants)
        %   ig.add_to_list(dataset_id)

            if ~ig.is_in_list_dataset(dataset_id)
                dataset_index = length(ig.List) + 1;
                ig.DatasetID2IndexLookup(dataset_id) = dataset_index;
                ig.List(dataset_index).Dataset_id = dataset_id;
                ig.List(dataset_index).ParticipantID2IndexLookup = configureDictionary("double", "double"); % Lookup dataset_id -> index
                ig.List(dataset_index).Participants = struct([]);
            else
                dataset_index = ig.DatasetID2IndexLookup(dataset_id);
            end
            
            if nargin == 2 || isempty(participants)
                ig.List(dataset_index).ParticipantID2IndexLookup(NaN) = 1;
                ig.List(dataset_index).Participants = struct("Participant_id", NaN, "Left", NaN, "Right", NaN);
                return
            end
            
            if nargin < 5 || isempty(side) || ismissing(side)
                side = ["Right" "Left"];
            end
            side = convertCharsToStrings(side);
            
            if ~isstring(side) || (length(side) ~= 1 && length(side) ~= 2) || ...
               ~all(strcmpi(side, "Left") | strcmpi(side, "Right"))
                error("PROSTDatasetList:Side:WrongFormat", "'side' should be either 'Left' or 'Right' or both.")
            end
            
            n_participants = length(participants);
            for pdx=1:n_participants
                participant_id = participants(pdx);

                if ~ig.is_in_list_participants(dataset_id, participant_id)
                    participant_index = length(ig.List(dataset_index).Participants) + 1;
                    ig.List(dataset_index).ParticipantID2IndexLookup(participant_id) = participant_index;
                    ig.List(dataset_index).Participants(participant_index).Participant_id = participant_id;
                    ig.List(dataset_index).Participants(participant_index).Left = [];
                    ig.List(dataset_index).Participants(participant_index).Right = [];
                else
                    participant_index = ig.List(dataset_index).ParticipantID2IndexLookup(participant_id);
                end

                for s=side
                    if nargin == 3 || isempty(trials)
                         ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(s)) = NaN;
                    else
                        ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(s)) = unique([ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(s)) trials]);
                    end
                end
            end
        end
        
        function delete_from_list(ig, dataset_id, participants, trials, side)
        %DELETE_FROM_LIST deletes the dataset with ID 'dataset_id' from the 
        % list, or the participant\s with ID 'participants' of that dataset or 
        % 'trials' of 'side' of 'participants' in 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset in the list. A positive integer 
        %                number.
        %   participants - the ID or IDs of the participants in the list. A 
        %                  positive integer number or vector of integer numbers. 
        %                  If missing, then deletes the entire dataset.
        %   trials - the trials to delete for each participant of the dataset. A
        %            vector of positive integer numbers. If missing then deletes
        %            the participant\s.
        %   side - the side of the trials to delete. Either 'Left' or 'Right'. 
        %          If missing then deletes both Left and Right trials.
        % Usage :
        %   ig.delete_from_list(dataset_id, participants, trials, side)
        %   ig.delete_from_list(dataset_id, participants, trials)
        %   ig.delete_from_list(dataset_id, participants, [], side)
        %   ig.delete_from_list(dataset_id, participants)
        %   ig.delete_from_list(dataset_id)
        
            if ~ig.is_in_list_dataset(dataset_id)
                return
            end
            dataset_index = ig.DatasetID2IndexLookup(dataset_id);

            if nargin == 2
                ig.List(dataset_index) = [];
                ig.DatasetID2IndexLookup(dataset_id) = [];
                if numEntries(ig.DatasetID2IndexLookup) > 0
                    keys = ig.DatasetID2IndexLookup.keys';
                    values = ig.DatasetID2IndexLookup.values';
                    idx = values > dataset_index;
                    ig.DatasetID2IndexLookup(keys(idx)) = values(idx) - 1; % Update remaining indices in lookup table
                end
                return
            end

            tf = ig.is_in_list_participants(dataset_id, participants);
            participants_in_list = participants(tf);
            if isempty(participants_in_list)
                return
            end
            n_participants = length(participants_in_list);

            if nargin == 3
                for pdx=1:n_participants
                    participant_id = participants_in_list(pdx);
                    participant_index = ig.List(dataset_index).ParticipantID2IndexLookup(participant_id);
                    ig.List(dataset_index).Participnats(participant_index) = [];
                    ig.List(dataset_index).ParticipantID2IndexLookup(participant_id) = [];
                    if numEntries(ig.List(dataset_index).ParticipantID2IndexLookup) > 0
                        keys = ig.List(dataset_index).ParticipantID2IndexLookup.keys';
                        values = ig.List(dataset_index).ParticipantID2IndexLookup.values';
                        idx = values > participant_index;
                        ig.List(dataset_index).ParticipantID2IndexLookup(keys(idx)) = values(idx) - 1; % Update remaining indices in lookup table
                    end
                end
                return
            end
            
            if nargin < 5 || isempty(side) || ismissing(side)
                side = ["Right" "Left"];
            end
            
            for pdx=1:n_participants
                participant_id = participants_in_list(pdx);
                participant_index = ig.List(dataset_index).ParticipantID2IndexLookup(participant_id);
                for s=side
                    if isempty(trials)
                        ig.List(dataset_index).Participnats(participant_index).(PROST.utils.capitalize(s)) = [];
                    else
                        tf = ig.is_in_list_trials(ig, dataset_id, participant_id, trials, s);
                        ig.List(dataset_index).Participnats(participant_index).(PROST.utils.capitalize(s))(tf) = [];
                    end
                end
            end
        end

        function tf = is_in_list_dataset(ig, dataset_id)
        %IS_IN_LIST_DATASET returns logical 1 (true) if the dataset with ID 
        % 'dataset_id' is in the list. Otherwise, returns logical 0
        % (false).
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        % Output :
        %   tf - is logical 1 (true) if the dataset is in the list, and
        %        otherwise is logical 0 (false).
        % Usage :
        %   ig.is_in_list_dataset(dataset_id)

            if ~isnumeric(dataset_id) || ~isscalar(dataset_id) || dataset_id <= 0 || dataset_id ~= floor(dataset_id)
                error("PROSTDatasetList:Dataset:WrongFormat", "Dataset ID should be a positive integer number.")
            end
            if ~isKey(ig.DatasetID2IndexLookup, dataset_id)
                tf = false;
            else
                tf = true;
            end
        end

        function [tf, all_flag] = is_in_list_participants(ig, dataset_id, participants)
        %IS_IN_LIST_PARTICIPANTS returns an array containing logical 1 (true) 
        % where the participant in 'participants' of the dataset with ID 
        % 'dataset_id' is in the list. Elsewhere, the array contains logical 0 
        % (false).
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        %   participants - the ID or IDs of the participants to check. A 
        %                  positive integer number or vector of integer numbers. 
        %                  If missing, then deletes the entire dataset.
        % Output :
        %   tf - a logical array of the same size as 'participants' containing 
        %        logical 1 (true) wherever the values in 'participants' are in
        %        the list. Elsewhere, it contains logical 0 (false).
        %   all_flag - flag that is logical 1 (true) if every participant in
        %              'dataset_id' is in the list, and logical 0 (false)
        %              otherwise.
        % Usage :
        %   ig.is_in_list_participants(dataset_id, participants)

            if ~isnumeric(participants) || ~isvector(participants) || any(participants <= 0) || any(participants ~= floor(participants))
                error("PROSTDatasetList:Participant:WrongFormat", "'participants' should be a positive integer or vector of positive integers.")
            end
            if ~ig.is_in_list_dataset(dataset_id)
                error("PROSTDatasetList:Dataset:MissingValue", "Dataset %d doesn't exist.", dataset_id)
            end
            dataset_index = ig.DatasetID2IndexLookup(dataset_id);           
            if isKey(ig.List(dataset_index).ParticipantID2IndexLookup, NaN)
                tf = true(size(participants));
                all_flag = true;
            else
                tf = isKey(ig.List(dataset_index).ParticipantID2IndexLookup, participants);
                all_flag = false;
            end
        end

        function [tf, all_flag] = is_in_list_trials(ig, dataset_id, participant_id, trials, side)
        %IS_IN_LIST_TRIALS returns an array containing logical 1 (true) where 
        % 'trials' is in the list. Elsewhere, the array contains logical 0 
        % (false). The trials are of 'side' of the participant with ID
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
        %        logical 1 (true) wherever the values in 'trials' are in the 
        %        list. Elsewhere, it contains logical 0 (false).
        %   all_flag - flag that is logical 1 (true) if every trial os 'side' in
        %              'participant_id' is in the list, and logical 0 (false)
        %              otherwise.
        % Usage :
        %   ig.is_in_list_participants(dataset_id, participant_id, trials, side)

            if ~isnumeric(trials) || ~isvector(trials) || any(trials <= 0) || any(trials ~= floor(trials))
                error("PROSTDatasetList:Trial:WrongFormat", "'trials' should be a positive integer or vector of positive integers.")
            end
            if ~strcmpi(side, "Left") && ~strcmpi(side, "Right")
                error("PROSTDatasetList:Side:WrongFormat", "'side' should be either 'Left' or 'Right'.")
            end
            if ~isscalar(participant_id)
                error("PROSTDatasetList:Participant:WrongFormat", "Participant ID should be a positive integer number.")
            end
            try
                [tf, participant_all] = ig.is_in_list_participants(dataset_id, participant_id);
            catch ME
                if contains(ME.identifier, "Participant")
                    ME.message = "Participant ID should be a positive integer number.";
                    throw(ME)
                end
            end
            if ~tf
                error("PROSTDatasetList:Participant:MissingValue", "Participant %d in dataset %d doesn't exist.", participant_id, dataset_id)
            end

            if participant_all
                tf = true(size(trials));
                all_flag = true;
                return
            end

            dataset_index = ig.DatasetID2IndexLookup(dataset_id);
            participant_index = ig.List(dataset_index).ParticipantID2IndexLookup(participant_id);
            if isnan(ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(side)))
                tf = true(size(trials));
                all_flag = true;
            else
                tf = ismember(trials, ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(side)));
                all_flag = false;
            end
        end

        function [tf, all_flag] = is_in_list_side(ig, dataset_id, participant_id, side)
        %IS_IN_LIST_SIDE returns logical 1 (true) if there are any trials in the 
        % list of side 'side'. Otherwise, returns logical 0 (false). The trial 
        % of 'side' is of the participant with ID 'participant_id' in the 
        % dataset with ID 'dataset_id'.
        % Input :
        %   dataset_id - the ID of the dataset to check. A positive integer 
        %                number.
        %   participant_id - the ID of the participant to check. A positive 
        %                    integer number.
        %   side - the side to check. Either 'Left' or 'Right'.
        % Output :
        %   tf - logical 1 (true) if there is a trial of side 'side' in the 
        %        list. Otherwise, it contains logical 0 (false).
        %   all_flag - flag that is logical 1 (true) if every trial of 'side' in
        %              'participant_id' is in the list, and logical 0 (false)
        %              otherwise.
        % Usage :
        %   ig.is_in_list_participants(dataset_id, participant_id, side)

            if ~strcmpi(side, "Left") && ~strcmpi(side, "Right")
                error("PROSTDatasetList:Side:WrongFormat", "'side' should be either 'Left' or 'Right'.")
            end
            if ~isscalar(participant_id)
                error("PROSTDatasetList:Participant:WrongFormat", "Participant ID should be a positive integer number.")
            end
            try
                [tf, participant_all] = ig.is_in_list_participants(dataset_id, participant_id);
            catch ME
                if contains(ME.identifier, "Participant")
                    ME.message = "Participant ID should be a positive integer number.";
                    throw(ME)
                end
            end
            if ~tf
                error("PROSTDatasetList:Participant:MissingValue", "Participant %d in dataset %d doesn't exist.", participant_id, dataset_id)
            end

            if participant_all
                tf = true;
                all_flag = true;
                return
            end

            dataset_index = ig.DatasetID2IndexLookup(dataset_id); 
            participant_index = ig.List(dataset_index).ParticipantID2IndexLookup(participant_id);
            if isempty(ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(side)))
                tf = false;
                all_flag = false;
            else
                tf = true;
                all_flag = all(isnan(ig.List(dataset_index).Participants(participant_index).(PROST.utils.capitalize(side))));
            end
        end
    end
end
