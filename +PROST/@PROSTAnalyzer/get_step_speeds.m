function speed_table = get_step_speeds(obj, dataset_ids)
%GET_STEP_SPEEDS returns the measured walking speed of every valid step, i.e.
% every step whose participant, side and step are all included.
% Speed is a property of the trial that is copied into each of its steps, so
% statistics over the returned rows weight participants by their step counts.
% Input :
%   dataset_ids - the IDs of the datasets to include. Default: all datasets.
% Output :
%   speed_table - a table with one row per valid step and the columns:
%       Dataset_id     - the ID of the dataset.
%       Participant_id - the ID of the participant within the dataset.
%       Side           - the walking side, "right" or "left".
%       Speed_category - the source speed condition/category of the step.
%       Speed          - the measured walking speed [km/hour].

    arguments
        obj
        dataset_ids (1, :) double = [obj.DataRecords.Dataset_id]
    end

    dataset_col = [];
    participant_col = [];
    side_col = strings(0, 1);
    category_col = strings(0, 1);
    speed_col = [];
    for dataset_id = dataset_ids
        dataset = obj.get_dataset(dataset_id);
        for participant = dataset.Data
            if ~participant.Is_included
                continue
            end
            for side = ["right", "left"]
                if ~participant.Uniform_data.(side).Is_included
                    continue
                end
                steps = participant.Uniform_data.(side).step;
                steps = steps([steps.Is_included]);
                speeds = [steps.speed];
                n_steps = numel(steps);
                dataset_col = [dataset_col; repmat(dataset_id, n_steps, 1)]; %#ok<AGROW>
                participant_col = [participant_col; repmat(participant.Participant_id, n_steps, 1)]; %#ok<AGROW>
                side_col = [side_col; repmat(side, n_steps, 1)]; %#ok<AGROW>
                category_col = [category_col; string({speeds.speed_category})']; %#ok<AGROW>
                speed_col = [speed_col; [speeds.value]']; %#ok<AGROW>
            end
        end
    end

    speed_table = table(dataset_col, participant_col, side_col, category_col, speed_col, ...
        VariableNames=["Dataset_id", "Participant_id", "Side", "Speed_category", "Speed"]);
end
