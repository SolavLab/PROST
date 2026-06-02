function [predictors, names, units, types] = get_predictors(obj, list)
%GET_PREDICTORS returns a table of all listed predictors (anthropometric and 
% functional data) from the IPD table.
% Input :
%   list - list of predictors to return
% Output :
%   predictors - the anthropometric/functional parameters.
%   names - the names of the parameters.
%   units - the units of the parameters.
%   types - the parameter variable types (double or categorical).

    idx = matches(obj.IPDTable.Properties.VariableDescriptions, 'predictor');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.IPDTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        throw(PROST.PROSTError("IPDTable", "PredictorDoesNotExist", ...
            "The predictors %s do not exist.", string(mat2str(list))));
    end
    names = obj.IPDTable.Properties.VariableNames(idx);
    units = obj.IPDTable.Properties.VariableUnits(idx);
    types = obj.IPDTable.Properties.VariableTypes(idx);
    predictors = obj.IPDTable(1:obj.IPDTableSize, names);
end