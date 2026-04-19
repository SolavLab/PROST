function [responses, names, units, types] = get_responses(obj, list)
%GET_RESPONSES returns all responses (ROS arc parameters) in list from
% the samples table.
% Input :
%   list - list of responses to return
% Output :
%   responses - the ROS parameters.
%   names - the names of the parameters.
%   units - the units of the parameters.
%   types - the parameter variable types.

    idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'response');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        throw(PROST.PROSTError("SamplesTable", "ResponseDoesNotExist", ...
            "The responses %s do not exist.", string(mat2str(list))));
    end
    names = obj.SamplesTable.Properties.VariableNames(idx);
    units = obj.SamplesTable.Properties.VariableUnits(idx);
    types = obj.SamplesTable.Properties.VariableTypes(idx);
    responses = obj.SamplesTable(1:obj.SamplesTableSize, names);
end