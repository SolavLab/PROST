function filter_data_by_ignore(obj)
%FILTER_DATA_BY_IGNORE Ignore all data in ignore list.

    n_datasets = length(obj.IgnoreObject.List);
    for i=1:n_datasets
        dataset_id = obj.IgnoreObject.List(i).Dataset_id;
        dataset_index = obj.DataRecordsIDLookup(dataset_id);
        n_participants = length(obj.IgnoreObject.List(i).Participants);
        for j=1:n_participants
            participant_id = obj.IgnoreObject.List(i).Participants(j).Participant_id;
            left_trials = obj.IgnoreObject.List(i).Participants(j).Left;
            right_trials = obj.IgnoreObject.List(i).Participants(j).Right;
            if isnan(left_trials)
                obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.left.Is_included = false;
                left_trials = ':';
            end
            [obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.left.step(left_trials).Is_included] = deal(false);
            if isnan(right_trials)
                obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.right.Is_included = false;
                right_trials = ':';
            end
            [obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.right.step(right_trials).Is_included] = deal(false);
        end
    end
end