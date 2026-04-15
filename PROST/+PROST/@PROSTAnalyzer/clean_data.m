function clean_data(obj, ignore_list, opts)
%CLEAN_DATA filters trials in ignore list from data records (marks them as not 
% included.
% Input :
%   ignore_list - PROSTDatasetList object containing trials to ignore.
%   opts - Name-Value pair options for filtering data by outliers or by bad
%          steps.
%       opts.BadSteps - whether to filter data by bad steps. Bad steps are those
%                       that have a non characteristic shape to the ROS arc
%                       causing arc fitting failures. Logical 1 (true) to filter
%                       bad steps, and logical 0 (false) otherwise.
%                       Default: 1 (true).

    arguments
        obj
        ignore_list    {mustBeScalarOrEmpty, mustBeAOrEmpty(ignore_list, "PROST.PROSTDatasetList")} = []
        opts.BadSteps  (1, 1) logical = true
    end
    
    if ~isempty(ignore_list)
        obj.IgnoreObject.merge_lists(ignore_list);
    end
    fprintf("Filtering data...\n");
    obj.filter_data_by_ignore();
    if opts.BadSteps
        obj.filter_data_by_bad_steps();
    end
    obj.update_num_included_summary();
    fprintf("Data filtered.\n");
end

% --------- helper functions ------------
function mustBeAOrEmpty(value, classname)
%MUSTBEAOREMPTY Validate that value comes from one of specified classes or is an
% empty array.
    if isempty(value)
        return
    end
    mustBeA(value, classname);
end