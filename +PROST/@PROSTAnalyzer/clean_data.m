function clean_data(obj, ignore_list)
%CLEAN_DATA filters trials in ignore list from data records (marks them as not 
% included.
% Input :
%   ignore_list - ROSIgnore object containing trials to ignore.

    obj.IgnoreObject = ignore_list;
    disp("Filtering ignored data...")
    obj.filter_data_by_ignore();
    disp("Data filtered.")
end