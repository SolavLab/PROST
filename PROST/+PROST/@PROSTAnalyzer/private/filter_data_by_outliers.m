function filter_data_by_outliers(obj, var_list, method)
%FILTER_DATA_BY_OUTLIERS Filter all data entries in the samples table by
% outliers in the given variables. Filters entries if at least one of
% the variables' value is an outlier.
% Input :
%   var_list - list of variables to filter the outliers by.
%   method - the method for calculating the outliers. Default: 'median'.

    if nargin < 3
        method = "median";
    end

    % Filter outlier parameters
    idx = ismember(var_list, string(obj.SamplesTable.Properties.VariableNames));
    if ~any(idx)
        return
    end
    samples = obj.get_samples(var_list);
    outliers = any(isoutlier(obj.get_sample_var(var_list(idx)), method), 2);
    row_numbers = find(outliers);
    if isempty(row_numbers)
        return
    end

    for entry=row_numbers
        dataset_id = obj.get_samples

    obj.delete_samples('r', row_numbers)
end