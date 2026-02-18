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

        included_steps = 0;
        included_participants = 0;
        for pdx=1:numel([dataset.Data])
            participant = dataset.Data(pdx);
            right_steps = [participant.Uniform_data.right.step];
            left_steps = [participant.Uniform_data.left.step];

            if ~isempty(right_steps)
                included_right_steps = sum([right_steps.Is_included]);
            else
                included_right_steps = 0;
            end
            if ~isempty(left_steps)
                included_left_steps = sum([left_steps.Is_included]);
            else
                included_left_steps = 0;
            end

            included_participants = included_participants + (included_right_steps > 0 || included_left_steps > 0);
            included_steps = included_steps + included_right_steps + included_left_steps;
        end
        obj.SummaryTable.Num_included_participants(entry_number) = included_participants;
        obj.SummaryTable.Num_included_steps(entry_number) = included_steps;
    end
end

