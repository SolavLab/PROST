function correlations = compute_correlations(predictors, responses)
%COMPUTE_CORRELATIONS computes pairwise Spearman, Pearson and R^2 correlation 
% coefficients between numeric predictors and responses. Also computes pairwise 
% Wilcoxon rank-sum test between categorical predictors and responses.
%
% Input :
%   predictors - table of all predictors data.
%   responses - table of all responses data.
%
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
    n_numeric_predictors = numel(numeric_predictor_names);

    categorical_predictors = predictors(:, ~idx);
    categorical_predictor_names= predictor_names(~idx);
    n_categorical_predictors = numel(categorical_predictor_names);

    % Regression and Spearman rank coefficients for numeric data
    [rho_spearman, p_spearman] = corr(numeric_predictors, responses, Type="Spearman", Rows="complete");
    [r_pearson, p_pearson] = corr(numeric_predictors, responses, Type="Pearson", Rows="complete");

    correlation_variable_names = {'Spearman_rho', 'Spearman_p', 'Pearson_r', 'Pearson_p', 'Rsquared', 'FitSlope', 'FitIntercept', 'FitRMSE'};
    n_correlation_variables = numel(correlation_variable_names);
    for r=1:numel(response_names)
        correlations.(response_names(r)) = struct;
        correlations.(response_names(r)).Numeric = ...
        table('Size', [n_numeric_predictors n_correlation_variables], ...
              'VariableTypes', convertStringsToChars("doublenan" + strings(1, n_correlation_variables)), ...
              'VariableNames', correlation_variable_names);
        correlations.(response_names(r)).Numeric.Properties.RowNames = numeric_predictor_names;

        correlations.(response_names(r)).Numeric.Spearman_rho = rho_spearman(:, r);
        correlations.(response_names(r)).Numeric.Spearman_p = p_spearman(:, r);
        correlations.(response_names(r)).Numeric.Pearson_r = r_pearson(:, r);
        correlations.(response_names(r)).Numeric.Pearson_p = p_pearson(:, r);
        correlations.(response_names(r)).Numeric.Pearson_r = r_pearson(:, r);

        for p=1:n_numeric_predictors
            x = numeric_predictors(:, p);
            y = responses(:, r);
            [pol, S] = polyfit(x, y, 1);
            y_fit = polyval(pol, x);
            rmse = sqrt(mean((y - y_fit).^2));
            pol = pol(:)';
            correlations.(response_names(r)).Numeric.Rsquared(p) = S.rsquared;
            correlations.(response_names(r)).Numeric.FitSlope(p) = pol(1);
            correlations.(response_names(r)).Numeric.FitIntercept(p) = pol(2);
            correlations.(response_names(r)).Numeric.FitRMSE(p) = rmse;
        end

        % Wilcoxon rank sum test (equivalent to the Mann-Whitney U-test) for
        % categorical data
        p_wilcoxon = zeros(numel(categorical_predictor_names), 1);
        h_wilcoxon = zeros(numel(categorical_predictor_names), 1);
        for p=1:n_categorical_predictors
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
