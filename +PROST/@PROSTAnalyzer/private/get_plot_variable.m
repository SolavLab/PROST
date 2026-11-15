function [value, value_name, value_units, value_type] = get_plot_variable(obj, var_name, normalizer_name)
%GET_PLOT_VARIABLE returns an IPD variable for plotting, optionally normalized by
% another IPD variable, with its display name and units. Shared by the plotters
% that draw a single variable (plot_stats, plot_summary_histogram).
%
% Input :
%   var_name - the name of the numeric IPD variable.
%   normalizer_name - the name of the numeric IPD variable to divide by. Leave
%                     empty for no normalization.
%
% Output :
%   value - the (normalized) values, one per IPD row (1:IPDTableSize).
%   value_name - display name, e.g. "Radius / Height".
%   value_units - the units: "-" when the normalizer's units convert to the
%                 variable's, otherwise "<var units>/<normalizer units>".
%   value_type - the variable's VariableDescriptions tag ("predictor",
%                "response" or "").
    arguments
        obj
        var_name            {mustBeTextScalar}
        normalizer_name     = []
    end

    var = obj.get_IPD_samples(var_name);
    if ~strcmp(var.Properties.VariableTypes, "double")
        throw(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen variable must be of numeric type but is of type %s", var.Properties.VariableTypes));
    end
    value = var.(var_name);
    value_name = replace(replace(var_name, "_", " "), "rms", "RMS");
    value_units = var.Properties.VariableUnits;
    value_type = var.Properties.VariableDescriptions;

    if ~isempty(normalizer_name)
        normalizer = obj.get_IPD_samples(normalizer_name);
        if ~strcmp(normalizer.Properties.VariableTypes, "double")
            throw(PROST.PROSTError("SamplesVariable", "WrongVariableType", ...
                "The chosen normalizer must be of numeric type but is of type %s", var.Properties.VariableTypes));
        end
        try
            value = value ./ PROST.utils.convert_units(normalizer.(normalizer_name), normalizer.Properties.VariableUnits, var.Properties.VariableUnits);
            value_units = "-";
        catch
            value = value ./ normalizer;
            value_units = value_units + "/" + normalizer.Properties.VariableUnits;
        end
        value_name = value_name + " / " +  replace(normalizer_name, "_", " ");
    end
end
