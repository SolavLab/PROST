function update_num_included_summary(obj, dataset_ids)
%UPDATE_NUM_INCLUDED_SUMMARY updates the summary table to the number of included
% participants and steps. This is for use after filtering bad
% participants\trials etc and should be called after each filtering function.
    
    if nargin < 2 || isempty(dataset_ids)
        dataset_ids = [obj.DataRecords.Dataset_id];
    end
    for dataset_id=dataset_ids
        dataset = obj.get_dataset(dataset_id);
        entry_number = obj.DataRecordsIDLookup(dataset_id);

        % Count number of included participants
        included_participants = [dataset.Data.Is_included];
        num_included_participants = sum(included_participants);
        obj.SummaryTable.Num_included_participants(entry_number) = num_included_participants;

        num_included_steps = 0;
        for participant=[dataset.Data(included_participants)]
            num_included_right_steps = 0;
            num_included_left_steps = 0;

            if participant.Uniform_data.right.Is_included
                num_included_right_steps = sum([participant.Uniform_data.right.step.Is_included]);
            end
            if participant.Uniform_data.left.Is_included
                num_included_left_steps = sum([participant.Uniform_data.left.step.Is_included]);
            end

            num_included_steps = num_included_steps + num_included_right_steps + num_included_left_steps;
        end
        obj.SummaryTable.Num_included_steps(entry_number) = num_included_steps;
    end
end

