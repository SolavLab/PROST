function var = get_summary_var(obj, var_name)
%GET_SSUMMARY_VAR returns all entries of var_name from summary
% table.
% Input :
%   var_name - the variable name. Must be a string scalar or
%              character row vector.
% Output :
%   var - the summary table entries for variable var_name.

    if ~isStringScalar(var_name) && (~ischar(var_name) || isrow(var_name))
        throw(PROST.PROSTError("SummaryTable", "WrongFormat", ...
            "Summary table variable name must be a string scalar or character row vector."));
    elseif ~ismember(var_name, obj.SummaryTable.Properties.VariableNames)
        throw(PROST.PROSTError("SummaryTable", "UnrecognizedVariableName", ...
            "'%s' is not a variable name of the summary table.", var_name));
    end
    var = obj.SummaryTable.(var_name)(1:obj.SummaryTableSize);
end