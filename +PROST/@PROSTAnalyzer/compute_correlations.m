function correlations = compute_correlations(predictors, responses)
%COMPUTE_CORRELATIONS computes pairwise Spearman, Pearson and R^2 correlation 
% coefficients between numeric predictors and responses. Also computes pairwise
% Wilcoxon rank-sum test between categorical predictors and responses, with the
% Mann-Whitney U and the rank-biserial correlation r_rb (equal to Cliff's delta)
% as effect size. W, U, z and r_rb all refer to the first category, so a
% positive r_rb means the first category tends to have larger responses.
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
    if n_numeric_predictors > 0
        [rho_spearman, p_spearman] = corr(numeric_predictors, responses, Type="Spearman", Rows="complete");
        [r_pearson, p_pearson] = corr(numeric_predictors, responses, Type="Pearson", Rows="complete");
    end

    numeric_variable_names = {'Spearman_rho', 'Spearman_p', 'Pearson_r', 'Pearson_p', 'Rsquared', 'FitSlope', 'FitIntercept', 'FitRMSE'};
    categorical_variable_names = {'Wilcoxon_H', 'Wilcoxon_p', 'Wilcoxon_z', 'Wilcoxon_W', 'MannWhitney_U', 'Wilcoxon_r_rb'};
    n_numeric_variables = numel(numeric_variable_names);
    n_categorical_variables = numel(categorical_variable_names);
    for r=1:numel(response_names)
        correlations.(response_names(r)) = struct;

        % Numeric correlation tests (Spearman, Pearson, Rsquared, ...)
        correlations.(response_names(r)).Numeric = ...
        table('Size', [n_numeric_predictors n_numeric_variables], ...
              'VariableTypes', convertStringsToChars("doublenan" + strings(1, n_numeric_variables)), ...
              'VariableNames', numeric_variable_names);
        correlations.(response_names(r)).Numeric.Properties.RowNames = numeric_predictor_names;

        if n_numeric_predictors > 0
            correlations.(response_names(r)).Numeric.Spearman_rho = rho_spearman(:, r);
            correlations.(response_names(r)).Numeric.Spearman_p = p_spearman(:, r);
            correlations.(response_names(r)).Numeric.Pearson_r = r_pearson(:, r);
            correlations.(response_names(r)).Numeric.Pearson_p = p_pearson(:, r);
        end
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
        correlations.(response_names(r)).Categorical = ...
        table('Size', [n_categorical_predictors n_categorical_variables], ...
              'VariableTypes', convertStringsToChars("doublenan" + strings(1, n_categorical_variables)), ...
              'VariableNames', categorical_variable_names);
        correlations.(response_names(r)).Categorical.Properties.RowNames = categorical_predictor_names;
        
        if n_categorical_predictors > 0
            p_wilcoxon = zeros(n_categorical_predictors, 1);
            h_wilcoxon = zeros(n_categorical_predictors, 1);
            z_wilcoxon = zeros(n_categorical_predictors, 1);
            w_wilcoxon = zeros(n_categorical_predictors, 1);
            u_mannwhitney = zeros(n_categorical_predictors, 1);
            r_rb_wilcoxon = zeros(n_categorical_predictors, 1);
            for p=1:n_categorical_predictors
                predictor = categorical(categorical_predictors{:, p});
                predictor_categories = categories(predictor, OutputType="categorical");
                y1 = responses(predictor == predictor_categories(1), r);
                y2 = responses(predictor == predictor_categories(2), r);
                [p_wilcoxon(p), h_wilcoxon(p), stat] = ranksum(y1, y2);
                z_wilcoxon(p) = stat.zval;
                w_wilcoxon(p) = stat.ranksum; % rank sum of y1 (ranksum returns it for X)
                % ranksum drops NaNs, so count only the samples it used
                n1 = sum(~isnan(y1));
                n2 = sum(~isnan(y2));
                u_mannwhitney(p) = stat.ranksum - n1*(n1 + 1)/2;
                % Rank-biserial correlation (Glass, 1965; Kerby, 2014)
                r_rb_wilcoxon(p) = 2*u_mannwhitney(p)/(n1*n2) - 1;
            end
            correlations.(response_names(r)).Categorical.Wilcoxon_H = h_wilcoxon;
            correlations.(response_names(r)).Categorical.Wilcoxon_p = p_wilcoxon;
            correlations.(response_names(r)).Categorical.Wilcoxon_z = z_wilcoxon;
            correlations.(response_names(r)).Categorical.Wilcoxon_W = w_wilcoxon;
            correlations.(response_names(r)).Categorical.MannWhitney_U = u_mannwhitney;
            correlations.(response_names(r)).Categorical.Wilcoxon_r_rb = r_rb_wilcoxon;
        end
        % correlations.(response_names(r)).Categorical = table(...
        %                             h_wilcoxon, p_wilcoxon, ...
        %                             VariableNames=["Wilcoxon_H", "Wilcoxon_p"], ...
        %                             RowNames=categorical_predictor_names);
    end
end
