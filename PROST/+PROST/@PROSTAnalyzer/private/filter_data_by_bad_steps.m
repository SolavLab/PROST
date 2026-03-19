function filter_data_by_bad_steps(obj, dataset_ids, bad_step_min_duration, anatomical_side)
%FILTER_DATA_BY_BAD_STEPS Filter data in records by bad steps. Bad steps
% are steps where the CoP in shank frame does not have the circular arc
% shape.
% Input :
%   dataset_id - the ID of the dataset to filter. A positive integer number or
%                vector of positive integer numbers. By default filters all
%                datasets in the data record.
%   bad_step_min_duration - min duration when COP of step loops backwards
%                           (from walking direction = x). This indicates
%                           a bad measurement of the step. Default: 10.
%   anatomical_side - the anatomical side of the shank frame. Either
%                     "lateral" (default), "medial" or "mean".


    if nargin < 4 || isempty(anatomical_side)
        anatomical_side = "lateral";
    end
    if nargin < 3 || isempty(bad_step_min_duration)
        bad_step_min_duration = 10;
    end
    if nargin < 2 || isempty(dataset_ids)
        dataset_ids = [obj.DataRecords.Dataset_id];
    end
    
    for dataset_id=dataset_ids
        if ~obj.dataset_exists(dataset_id)
            throw(PROST.PROSTError("DataRecords", "MissingDataset", ...
                "Dataset %d not in data records.", dataset_id));
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

                    % Ignore steps that have already been filtered
                    if ~step.Is_included
                        continue
                    end

                    trial_name = step.source.original_trial;
                    step_number = step.source.step_number;
                    plate_number = step.source.plate_number;
                    s = sprintf("%s P%d (%s), %s step %d (%s)", dataset_name, participant_num, participant_name, side, trial_num, replace(trial_name, "_", " "));
    
                    shank_cop = step.Shank_cop.(anatomical_side);
    
                    x = shank_cop.u(~isnan(shank_cop.u));
                    dx = diff(x);
                    sign_d = sign(dx);
                    idx_switch = find(diff(sign_d) ~= 0);
                    if isempty(idx_switch)
                        if sign_d(1) < 0
                            obj.DataRecords(dataset_index).Data(participant_num).Uniform_data.(side).step(trial_num).Is_included = false;
                            % fprintf("%s : -1\n", s);
                        end
                        continue
                    else
                        idx_switch = [0 idx_switch];
                        idx_switch = [idx_switch length(sign_d)];
                        if any(sign_d(idx_switch(1:end-1) + 1) < 0 & diff(idx_switch) > bad_step_min_duration)
                            obj.DataRecords(dataset_index).Data(participant_num).Uniform_data.(side).step(trial_num).Is_included = false;
                            % fprintf("%s\n", s);
                        end
                    end
                end
            end
        end
    end
end