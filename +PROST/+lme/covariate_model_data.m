function data = covariate_model_data(data, spec)
% DATA = COVARIATE_MODEL_DATA(DATA, SPEC)
% The rows of one covariate model: its datasets, complete on SPEC.complete, with
% unused categories removed (effects coding needs every level present) and the
% "_c" terms added as their column centred within dataset.
%
% Example usage :
%   model_data = PROST.lme.covariate_model_data(data_final, covariate_models(3))

    if ~isempty(spec.datasets)
        data = data(ismember(double(string(data.DatasetID)), spec.datasets), :);
    end
    keep = true(height(data), 1);
    for column = spec.complete
        keep = keep & ~ismissing(data.(column));
    end
    data = data(keep, :);
    data.DatasetID = removecats(data.DatasetID);
    if ismember("Sex", data.Properties.VariableNames)
        data.Sex = removecats(data.Sex);
    end

    for term = spec.terms(endsWith(spec.terms, "_c"))
        column = extractBefore(term, strlength(term) - 1);
        dataset_mean = groupsummary(data, "DatasetID", "mean", column);
        [~, loc] = ismember(data.DatasetID, dataset_mean.DatasetID);
        data.(term) = data.(column) - dataset_mean.("mean_" + column)(loc);
    end
end
