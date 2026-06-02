function correlations = compute_correlations(predictors, responses)
%COMPUTE_CORRELATIONS computes pairwise Spearman, Pearson and R^2 correlation 
% coefficients between numeric predictors and responses.
% Computes pairwise Wilcoxon rank-sum test between categorical predictors and 
% responses. 
% Input :
%   predictors - table of all predictors data.
%   responses - table of all responses data.
% Output :
%   correlations - struct containing a 'Numeric' table of correlation 
%                  coefficients of all numeric predictors and a 'Categorical' 
%                  table of Wilcoxon test results of all categorical predictors 
%                  for each response.

    arguments
        predictors      table
        responses       table  
    end

    predictor_names = string(predictors.Properties.VariableNames);
    response_names = string(responses.Properties.VariableNames);
    predictor_types = string(predictors.Properties.VariableTypes);

    responses = table2array(responses);

    idx = (strcmp(predictor_types, "double") | strcmp(predictor_types, "doublenan"));

    numeric_predictors = table2array(predictors(:, idx));
    numeric_predictor_names = predictor_names(idx);

    categorical_predictors = predictors(:, ~idx);
    categorical_predictor_names= predictor_names(~idx);

    % Regression and Spearman rank coefficients for numeric data
    [rho_spearman, p_spearman] = corr(numeric_predictors, responses, Type="Spearman", Rows="complete");
    [rho_pearson, p_pearson] = corr(numeric_predictors, responses, Type="Pearson", Rows="complete");

    for r=1:numel(response_names)
        correlations.(response_names(r)) = struct;
        correlations.(response_names(r)).Numeric =  table( ...
                                                    rho_spearman(:, r), ...
                                                    p_spearman(:, r), ...
                                                    rho_pearson(:, r), ...
                                                    p_pearson(:, r), ...
                                                    rho_pearson(:, r).^2, ...
                                                    VariableNames=[ ...
                                                                    "Spearman_rho", ...
                                                                    "Spearman_p", ...
                                                                    "Pearson_rho", ...
                                                                    "Pearson_p", ...
                                                                    "Rsquared"], ...
                                                    RowNames=numeric_predictor_names);

        % Wilcoxon rank sum test (equivalent to the Mann-Whitney U-test) for
        % categorical data
        p_wilcoxon = zeros(numel(categorical_predictor_names), 1);
        h_wilcoxon = zeros(numel(categorical_predictor_names), 1);
        for p=1:numel(categorical_predictor_names)
            predictor = categorical(categorical_predictors{:, p});
            predictor_categories = categories(predictor, OutputType="categorical");
            y1 = responses(predictor == predictor_categories(1), r);
            y2 = responses(predictor == predictor_categories(2), r);
            [p_wilcoxon(p), h_wilcoxon(p)] = ranksum(y1, y2);
        end
        correlations.(response_names(r)).Categorical = table(...
                                    h_wilcoxon, p_wilcoxon, ...
                                    VariableNames=["Wilcoxon_H", "Wilcoxon_p"], ...
                                    RowNames=categorical_predictor_names);
    end
end
