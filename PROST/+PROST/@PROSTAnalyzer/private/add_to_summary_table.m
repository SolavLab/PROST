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
    obj.SummaryTable.Speed_categories(entry_number) = dataset.Experiment_protocol.speed_categories;
    obj.SummaryTable.Num_participants(entry_number) = dataset.Experiment_protocol.num_participants;
    obj.SummaryTable.Num_forceplates(entry_number) = dataset.Lab_system.num_forceplates;
    
    % Example participant for existing data to check if participants are
    % shod and medial markers exist
    participant = dataset.Data(1);
    obj.SummaryTable.Is_shod(entry_number) = participant.Anthropometric_data.Is_shod.value;
    if ~isempty(participant.Uniform_data.right.step)
        step = participant.Uniform_data.right.step(1);
    elseif ~isempty(participant.Uniform_data.left.step)
        step = participant.Uniform_data.left.step(1);
    end
    obj.SummaryTable.Has_medial(entry_number) = ~isempty(step.Markers.Ankle.medial);

    % Count all included participants and steps in dataset
    obj.update_num_included_summary(dataset_id);
end