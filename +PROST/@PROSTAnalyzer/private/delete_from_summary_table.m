function delete_from_summary_table(obj, index)
    obj.SummaryTable(index, :) = [];
    obj.SummaryTableSize = obj.SummaryTableSize - 1;
end