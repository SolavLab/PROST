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
        dataset_name = obj.get_dataset_name(dataset_id);
        included_idx = [obj.DataRecords(dataset_index).Data.Is_included];
        included_participants = obj.DataRecords(dataset_index).Data(included_idx);
        n_participants = length(included_participants);
        for p=1:n_participants
            participant_id = included_participants(p).Participant_id;
            participant_name = included_participants(p).Participant_name;
            num_excluded_sides = 0;
            for side=["left" "right"]
                if ~included_participants(p).Uniform_data.(side).Is_included
                    continue
                end
                steps = included_participants(p).Uniform_data.(side).step;
                n_steps = length(steps);
                for step_num=1:n_steps
                    step = steps(step_num);

                    % Ignore steps that have already been filtered
                    if ~step.Is_included
                        continue
                    end

                    trial_name = step.source.original_trial;
                    s = sprintf("%s P%d (%s), %s step %d (%s)", dataset_name, participant_id, participant_name, side, step_num, replace(trial_name, "_", " "));
                    shank_cop = step.Shank_cop.(anatomical_side);
                    u = shank_cop.u(~isnan(shank_cop.u));
                    du = diff(u);
                    sign_d = sign(du); % u derivative sign. States at each sample point if the step is moving forward to backward.
                    idx_switch = find(diff(sign_d) ~= 0); % indices where the step changes direction (forward to backwards or backwards to forwards).
                    if isempty(idx_switch)
                        if sign_d(1) < 0
                            obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(step_num).Is_included = false;
                            obj.IgnoreObject.add_to_list(dataset_id, participant_id, step_num, side);
                            PROST.PROSTWarning.warn("DataRecords", "ExcludedStep", "%s excluded. Full toe-to-heel step recorded.", s);
                        end
                        continue
                    else
                        idx_switch = [0 idx_switch];
                        idx_switch = [idx_switch length(sign_d)];
                        if any(sign_d(idx_switch(1:end-1) + 1) < 0 & diff(idx_switch) > bad_step_min_duration)
                            obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step(step_num).Is_included = false;
                            obj.IgnoreObject.add_to_list(dataset_id, participant_id, step_num, side);
                            PROST.PROSTWarning.warn("DataRecords", "ExcludedStep", "%s excluded. Partial toe-to-heel step recorded for max %d samples.", s, max(diff(idx_switch)));
                        end
                    end % isempty(idx_switch)
                end % step_num

                % If all trials of "side" are not included, exclude side
                if obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).Is_included && ...
                   all(~[obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).step.Is_included])
                    obj.DataRecords(dataset_index).Data(participant_id).Uniform_data.(side).Is_included = false;
                    num_excluded_sides = num_excluded_sides + 1;
                end
            end % side
            % If all sides of participant are not included, exclude participant
            if num_excluded_sides == 2
                obj.DataRecords(dataset_index).Data(participant_id).Is_included = false;
                disp(dataset_name + " P" + participant_id + " (" + participant_name + ") Entire participant excluded!")

            end
        end % p
    end % dataset_id
end