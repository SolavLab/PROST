function [features, names, units, types] = get_features(obj, list)
%GET_FEATURES returns a table of all features (anthropometric data) in
% list from the samples table.
% Input :
%   list - list of features to return
% Output :
%   features - the anthropometric parameters.
%   names - the names of the anthropometric parameters.
%   units - the units of the anthropometric parameters.
%   types - the anthropometric parameter types.

    idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'feature');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        error(PROST.PROSTError("SamplesTable", "FeatureDoesNotExist", ...
            "The features %s do not exist.", string(mat2str(list))));
    end
    names = obj.SamplesTable.Properties.VariableNames(idx);
    units = obj.SamplesTable.Properties.VariableUnits(idx);
    types = obj.SamplesTable.Properties.VariableTypes(idx);
    features = obj.SamplesTable(1:obj.SamplesTableSize, names);
end