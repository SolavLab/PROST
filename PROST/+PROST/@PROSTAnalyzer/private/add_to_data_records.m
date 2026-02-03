function dataset_id = add_to_data_records(obj, dataset_name, dataset, anatomical_side)
%ADD_TO_DATA_RECORDS adds new dataset to data records.
% Input :
%   dataset_name - the name of the dataset.
%   dataset - the dataset to load.
%   anatomical_side - the anatomical side of the marker data. Either
%                     "lateral" (default), "medial" or "mean".
% Output :
%   dataset_id - the unique dataset ID  .

    if nargin < 4
        anatomical_side = "lateral";
    end

    index = length(obj.DataRecords) + 1;
    dataset_id = obj.FirstUniqueDatasetId;
    obj.FirstUniqueDatasetId = obj.FirstUniqueDatasetId + 1;
    obj.DataRecordsIDLookup(dataset_id) = index;

    obj.DataRecords(index).Dataset_id = dataset_id;
    obj.DataRecords(index).Dataset_name = dataset_name;
    obj.DataRecords(index).Article_data = dataset.Article_data;
    obj.DataRecords(index).Lab_system = dataset.Lab_system;
    obj.DataRecords(index).Experiment_protocol = dataset.Experiment_protocol;

    participants = fieldnames(dataset.Data);
    n_participants = length(participants);
    obj.DataRecords(index).Data(n_participants) = struct;
    for participant_num = 1:n_participants
        participant_name = participants{participant_num};
        original_participant_name = dataset.Data.(participant_name).participant_ID_in_original_structure;
        uniform_data = dataset.Data.(participant_name).uniform_data;
        metadata = dataset.Data.(participant_name).metadata;

        obj.DataRecords(index).Data(participant_num).Participant_id = participant_num;
        obj.DataRecords(index).Data(participant_num).Participant_name = original_participant_name;
        obj.DataRecords(index).Data(participant_num).Anthropometric_data = metadata;
        obj.DataRecords(index).Data(participant_num).Uniform_data = uniform_data;
        if ~isempty(obj.DataRecords(index).Data(participant_num).Uniform_data.left.step)
            [obj.DataRecords(index).Data(participant_num).Uniform_data.left.step(:).Is_included] = deal(true);
        end
        if ~isempty(obj.DataRecords(index).Data(participant_num).Uniform_data.right.step)
            [obj.DataRecords(index).Data(participant_num).Uniform_data.right.step(:).Is_included] = deal(true);
        end

        for side=["left" "right"]
            if ~isempty(obj.DataRecords(index).Data(participant_num).Uniform_data.(side).step)
                [obj.DataRecords(index).Data(participant_num).Uniform_data.(side).step(:).Is_included] = deal(true);
                for step_num=1:length(obj.DataRecords(index).Data(participant_num).Uniform_data.(side).step)
                    step = obj.DataRecords(index).Data(participant_num).Uniform_data.(side).step(step_num);
                    shank_cop.temporal_alignment = step.COP.temporal_alignment;
                    shank_cop.IC_index = step.COP.IC_index;
                    shank_cop.OIC_index = step.COP.OIC_index;
                    shank_cop.unit = step.COP.unit;
                    shank_cop.lateral = struct([]);
                    shank_cop.medial = struct([]);
                    shank_cop.mean = struct([]);
                    shank_cop.(anatomical_side) = PROST.PROSTAnalyzer.cop_to_shank_frame(step, anatomical_side);
                    obj.DataRecords(index).Data(participant_num).Uniform_data.(side).step(step_num).Shank_cop = shank_cop;
                end
            end
        end
    end
    obj.filter_data_by_bad_steps(dataset_id)
end