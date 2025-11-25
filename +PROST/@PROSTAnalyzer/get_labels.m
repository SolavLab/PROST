function [labels, names, units, types] = get_labels(obj, list)
%GET_LABELS returns all labels (ROS arc parameters) in list from
% the samples table.
% Input :
%   list - list of labels to return
% Output :
%   labels - the ROS parameters.
%   names - the names of the ROS parameters.
%   units - the units of the ROS parameters.
%   types - the ROS parameter types.

    idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'label');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        error(PROST.PROSTError("SamplesTable", "LabelDoesNotExist", ...
            "The labels %s do not exist.", string(mat2str(list))));
    end
    names = obj.SamplesTable.Properties.VariableNames(idx);
    units = obj.SamplesTable.Properties.VariableUnits(idx);
    types = obj.SamplesTable.Properties.VariableTypes(idx);
    labels = obj.SamplesTable(1:obj.SamplesTableSize, names);
end