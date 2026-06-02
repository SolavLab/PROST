function update_num_included_summary(obj, dataset_ids)
%UPDATE_NUM_INCLUDED_SUMMARY updates the summary table to the number of included
% participants and steps. This is for use after filtering bad
% participants\trials etc and should be called after each filtering function.
    
    if nargin < 2 || isempty(dataset_ids)
        dataset_ids = [obj.DataRecords.Dataset_id];
    end
    for dataset_id=dataset_ids
        dataset = obj.get_dataset(dataset_id);
        dataset_index = obj.DataRecordsIDLookup(dataset_id);

        % Count number of included participants
        included_idx = [dataset.Data.Is_included];
        included_participants = [dataset.Data(included_idx)];
        num_included_participants = sum(included_idx);
        obj.SummaryTable.N_participants_included(dataset_index) = num_included_participants;

        num_included_steps = zeros(1, num_included_participants);
        for participant_num=1:num_included_participants
            participant = included_participants(participant_num);

            num_included_right_steps = 0;
            num_included_left_steps = 0;

            if participant.Uniform_data.right.Is_included
                num_included_right_steps = sum([participant.Uniform_data.right.step.Is_included]);
            end
            if participant.Uniform_data.left.Is_included
                num_included_left_steps = sum([participant.Uniform_data.left.step.Is_included]);
            end

            num_included_steps(participant_num) = num_included_right_steps + num_included_left_steps;
        end
        obj.SummaryTable.N_steps_included(dataset_index) = sum(num_included_steps);
        obj.SummaryTable.Steps_pp_mean(dataset_index) = mean(num_included_steps);
        obj.SummaryTable.Steps_pp_std(dataset_index) = std(num_included_steps);
    end
end

