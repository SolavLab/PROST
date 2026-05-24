function [samples, var_names] = get_IPD_variable(obj, var_list)
%GET_IPD_VARIABLE returns the samples of all variables in var_list from
% the IPD table. Also returns a list of the existing variable names.
% If a name in the list is not a variable in IPD table, ignores it.
% Returns empty table and empty array if no variable names exist.
% Input :
%   var_list - the variable name or list of variable names. Must be a
%              string array or character cell array.
% Output :
%   samples - the sample table entries for the variables in list.
%   var_names - the names of the variables that are returned.

    idx = ismember(var_list, string(obj.IPDTable.Properties.VariableNames));
    if ~any(idx)
        var_names = [];
        samples = table;
    else
        var_names = var_list(idx);
        samples = obj.IPDTable(1:obj.IPDTableSize, var_list(idx));
    end
end