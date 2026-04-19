function [predictors, names, units, types] = get_predictors(obj, list)
%GET_PREDICTORS returns a table of all listed predictors (anthropometric and 
% functional data) from the samples table.
% Input :
%   list - list of predictors to return
% Output :
%   predictors - the anthropometric/functional parameters.
%   names - the names of the parameters.
%   units - the units of the parameters.
%   types - the parameter variable types (double or categorical).

    idx = matches(obj.SamplesTable.Properties.VariableDescriptions, 'predictor');
    if nargin == 2 && ~isempty(list)
        idx = idx & ismember(string(obj.SamplesTable.Properties.VariableNames), list);
    end
    if ~any(idx)
        throw(PROST.PROSTError("SamplesTable", "PredictorDoesNotExist", ...
            "The predictors %s do not exist.", string(mat2str(list))));
    end
    names = obj.SamplesTable.Properties.VariableNames(idx);
    units = obj.SamplesTable.Properties.VariableUnits(idx);
    types = obj.SamplesTable.Properties.VariableTypes(idx);
    predictors = obj.SamplesTable(1:obj.SamplesTableSize, names);
end