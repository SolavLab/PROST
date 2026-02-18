function clean_data(obj, ignore_list)
%CLEAN_DATA filters trials in ignore list from data records (marks them as not 
% included.
% Input :
%   ignore_list - ROSIgnore object containing trials to ignore.

    obj.IgnoreObject = ignore_list;
    fprintf("Filtering ignored data...\n");
    obj.filter_data_by_ignore();
    obj.filter_data_by_bad_steps();
    obj.update_num_included_summary();
    fprintf("Data filtered.\n");
end