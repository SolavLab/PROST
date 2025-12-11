function filter_data_by_ignore(obj)
%FILTER_DATA_BY_IGNORE Ignore all data in ignore list.

    n_datasets = length(obj.IgnoreObject.IgnoreList);
    for i=1:n_datasets
        dataset_id = obj.IgnoreObject.IgnoreList(i).Dataset_id;
        dataset_index = obj.DataRecordsIDLookup(dataset_id);
        n_participants = length(obj.IgnoreObject.IgnoreList(i).Participants);
        for j=1:n_participants
            participant_id = obj.IgnoreObject.IgnoreList(i).Participants(j).Participant_id;
            left_trials = obj.IgnoreObject.IgnoreList(i).Participants(j).Left;
            right_trials = obj.IgnoreObject.IgnoreList(i).Participants(j).Right;
            if isnan(left_trials)
                left_trials = ':';
            end
            [obj.DataRecords(dataset_index).Data(participant_id).Processed_data.left.step(left_trials).Is_included] = deal(false);
            if isnan(right_trials)
                right_trials = ':';
            end
            [obj.DataRecords(dataset_index).Data(participant_id).Processed_data.right.step(right_trials).Is_included] = deal(false);
        end
    end
end