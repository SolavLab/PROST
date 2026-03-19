function delete_from_summary_table(obj, dataset_id)
    index = obj.DataRecordsIDLookup(dataset_id);
    obj.SummaryTable(index, :) = [];
    obj.SummaryTableSize = obj.SummaryTableSize - 1;
end