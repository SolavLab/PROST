function add_to_summary_table(obj, dataset_id)
%ADD_TO_SUMMARY_TABLE adds new dataset info to summary table.
% Input :
%   dataset_id - the ID of the dataset in data records to add.
%                A positive integer number.

    % Get dataset
    dataset = obj.get_dataset(dataset_id);

    % If summary table has no empty rows, allocate new row
    if obj.SummaryTableSize == height(obj.SummaryTable)
        new_table = table('Size', [1, width(obj.SummaryTable)], ...
            'VariableTypes', varfun(@class, obj.SummaryTable, 'OutputFormat', 'cell'), ...
            'VariableNames', obj.SummaryTable.Properties.VariableNames);
        obj.SummaryTable = [obj.SummaryTable; new_table];
    end

    % Set the entry number to the first empty row in the table
    entry_number = obj.SummaryTableSize + 1;
    obj.SummaryTableSize = obj.SummaryTableSize + 1;

    % Populate summary table
    obj.SummaryTable.Dataset_id(entry_number) = dataset_id;
    obj.SummaryTable.Dataset_name(entry_number) = dataset.Dataset_name;
    obj.SummaryTable.Article_name(entry_number) = dataset.Article_data.article_name;
    obj.SummaryTable.Authors(entry_number) = dataset.Article_data.authors;
    obj.SummaryTable.Article_url(entry_number) = dataset.Article_data.link_to_paper;
    obj.SummaryTable.Dataset_url(entry_number) = dataset.Article_data.link_to_dataset;
    obj.SummaryTable.Published_year(entry_number) = dataset.Article_data.published_year;
    if ~iscell(dataset.Experiment_protocol.speed_categories)
        dataset.Experiment_protocol.speed_categories = {dataset.Experiment_protocol.speed_categories};
    end
    obj.SummaryTable.Speed_categories(entry_number) = dataset.Experiment_protocol.speed_categories;
    obj.SummaryTable.N_participants(entry_number) = dataset.Experiment_protocol.num_participants;
    obj.SummaryTable.N_steps(entry_number) = dataset.Experiment_protocol.num_steps;
    obj.SummaryTable.N_forceplates(entry_number) = dataset.Lab_system.num_forceplates;
    
    % Example participant for existing data to check if participants are
    % shod
    participant = dataset.Data(1);
    obj.SummaryTable.Footwear_condition(entry_number) = participant.Anthropometric_data.Footwear_condition.value;
    
    % Check whether medial markers exist.
    participants = [dataset.Data.Uniform_data];
    right_steps = [participants.right];
    left_steps = [participants.left];
    steps = [right_steps.step left_steps.step];
    if ~isempty(steps(1).Markers.Ankle.medial)
        obj.SummaryTable.Has_medial(entry_number) = true;
    else
        obj.SummaryTable.Has_medial(entry_number) = false;
    end

    % Count mean +- SD of age, height and mass.
    metadata = [dataset.Data.Anthropometric_data];
    ages = [metadata.Age]; ages = [ages.value];
    heights = [metadata.Height]; heights = [heights.value];
    masses = [metadata.Mass]; masses = [masses.value];

    obj.SummaryTable.Age_mean(entry_number) = mean(ages);
    obj.SummaryTable.Age_std(entry_number) = std(ages);
    obj.SummaryTable.Height_mean(entry_number) = mean(heights);
    obj.SummaryTable.Height_std(entry_number) = std(heights);
    obj.SummaryTable.Mass_mean(entry_number) = mean(masses);
    obj.SummaryTable.Mass_std(entry_number) = std(masses);

    % Count all included participants and steps in dataset
    obj.update_num_included_summary(dataset_id);
end