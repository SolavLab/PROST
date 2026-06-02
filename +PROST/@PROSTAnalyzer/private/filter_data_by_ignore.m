function filter_data_by_ignore(obj, ignore_list)
%FILTER_DATA_BY_IGNORE Ignore all data in ignore list.

    n_datasets = length(ignore_list.List);
    for d=1:n_datasets
        dataset_id = ignore_list.List(d).Dataset_id;
        dataset_index = obj.DataRecordsIDLookup(dataset_id);
        dataset_name = obj.get_dataset_name(dataset_id);
        n_participants = length(ignore_list.List(d).Participants);
        for p=1:n_participants
            participant_id = ignore_list.List(d).Participants(p).Participant_id;
            participant_name = obj.DataRecords(dataset_index).Data(participant_id).Participant_name;
            if ~obj.DataRecords(dataset_index).Data(participant_id).Is_included % Skip if entire participant is already excluded
                continue
            end
            num_excluded_sides = 0;
            for side=["left", "right"]
                ignored_steps = ignore_list.List(d).Participants(p).(PROST.utils.capitalize(side));
                if ~isempty(ignored_steps) && (obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).Is_included)
                    if isnan(ignored_steps)
                        obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).Is_included = false;
                        [obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(:).Is_included] = deal(false);
                        num_excluded_sides = num_excluded_sides + 1;
                        PROST.PROSTWarning.warn("DataRecords", "ExcludedStep", "%s P%d (%s), all %s steps ignored.", dataset_name, participant_id, participant_name, side)
                    elseif any([obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(ignored_steps).Is_included])
                        ignored_steps = ignored_steps([obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(ignored_steps).Is_included]);
                        [obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(ignored_steps).Is_included] = deal(false);
                        PROST.PROSTWarning.warn("DataRecords", "ExcludedStep", "%s P%d (%s), %s steps %s ignored.", dataset_name, participant_id, participant_name, side, join(string(ignored_steps), ", "))
                    end
                end
            end
            if num_excluded_sides == 2
                obj.DataRecords(dataset_index).Data(participant_id).Is_included = false;
            end
        end
    end
end