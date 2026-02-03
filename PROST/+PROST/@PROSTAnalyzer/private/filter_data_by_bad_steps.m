function filter_data_by_bad_steps(obj, dataset_id, bad_step_min_duration, anatomical_side)
%FILTER_DATA_BY_BAD_STEPS Filter data in records by bad steps. Bad steps
% are steps where the CoP in shank frame does not have the circular arc
% shape.
% Input :
%   dataset_id - the ID of the dataset to filter.
%   bad_step_min_duration - min duration when COP of step goes backwards
%                           (from walking direction - x). This indicates
%                           a bad measurement of the step.
%   anatomical_side - the anatomical side of the shank frame. Either
%                     "lateral" (default), "medial" or "mean".

    if ~obj.dataset_exists(dataset_id)
        error(PROST.PROSTError("DataRecords", "MissingDataset", ...
            "Dataset %d not in data records.", dataset_id));
    end

    if nargin < 4
        anatomical_side = "lateral";
    end
    if nargin < 3
        bad_step_min_duration = 10;
    end

    dataset_index = obj.DataRecordsIDLookup(dataset_id);
    dataset_name = obj.DataRecords(dataset_index).Dataset_name;
    n_participants = length(obj.DataRecords(dataset_index).Data);
    for participant_num=1:n_participants
        participant_name = obj.DataRecords(dataset_index).Data(participant_num).Participant_name;
        for side=["left" "right"]
            trials = obj.DataRecords(dataset_index).Data(participant_num).Uniform_data.(side).step;
            n_trials = length(trials);
            for trial_num=1:n_trials
                step = trials(trial_num);
                trial_name = step.source.original_trial;
                step_number = step.source.step_number;
                plate_number = step.source.plate_number;
                s = sprintf("DB%d (%s) P%d (%s) %s, T%d (%s), Step %d FP%d\n", dataset_id, dataset_name, participant_num, participant_name, side, trial_num, replace(trial_name, "_", " "),step_number, plate_number);

                shank_cop = step.Shank_cop.(anatomical_side);

                x = shank_cop.x(~isnan(shank_cop.x));
                dx = diff(x);
                sign_d = sign(dx);
                idx_switch = find(diff(sign_d) ~= 0);
                if isempty(idx_switch)
                    if sign_d(1) < 0
                        obj.DataRecords(dataset_index).Data(participant_num).Uniform_data.(side).step(trial_num).Is_included = false;
                        % disp("-1 " + s);
                    end
                    continue
                else
                    idx_switch = [0 idx_switch];
                    idx_switch = [idx_switch length(sign_d)];
                    if any(sign_d(idx_switch(1:end-1) + 1) < 0 & diff(idx_switch) > bad_step_min_duration)
                        obj.DataRecords(dataset_index).Data(participant_num).Uniform_data.(side).step(trial_num).Is_included = false;
                        % disp(s);
                    end
                end
            end
        end
    end
end