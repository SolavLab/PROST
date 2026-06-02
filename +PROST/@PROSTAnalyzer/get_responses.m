function [responses, names, units, types] = get_responses(obj, list)
%GET_RESPONSES returns all table of responses (ROS arc parameters) in list from
% the IPD table.
% Input :
%   list - list of responses to return
% Output :
%   responses - the ROS parameters.
%   names - the names of the parameters.
%   units - the units of the parameters.
%   types - the parameter variable types.

    idx = matches(obj.IPDTable.Properties.VariableDescriptions, 'response');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.IPDTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        throw(PROST.PROSTError("IPDTable", "ResponseDoesNotExist", ...
            "The responses %s do not exist.", string(mat2str(list))));
    end
    names = obj.IPDTable.Properties.VariableNames(idx);
    units = obj.IPDTable.Properties.VariableUnits(idx);
    types = obj.IPDTable.Properties.VariableTypes(idx);
    responses = obj.IPDTable(1:obj.IPDTableSize, names);
end