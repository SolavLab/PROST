function covariate_diagnostics(data, results, baseline, spec, unit)
% COVARIATE_DIAGNOSTICS(DATA, RESULTS, BASELINE, SPEC, UNIT)
% Assumption checks of one covariate model, beyond what the case bootstrap makes
% robust: normality of the residuals and random effects, residuals vs fitted and
% homoscedasticity across datasets, linearity in each continuous covariate
% (marginal residuals vs the covariate, and the CI of an added quadratic term),
% collinearity (VIF), and the leave-one-participant-out range of the pseudo-R2.
% Prints the results and plots the residual figures.
% UNIT is the unit of the response for the axis labels (default "[-]").
%
% Example usage :
%   PROST.lme.covariate_diagnostics(model_data, results.covariate_models.anthro, ...
%                         results.covariate_models.side, covariate_models(3))

    if nargin < 5
        unit = "[-]";
    end
    lme = results.lme;
    name = "Covariate model " + spec.name;
    fprintf('\n===== Diagnostics: %s =====\n', name)

    % Normality
    res = residuals(lme, 'ResidualType', 'Pearson');
    PROST.lme.normality_check(res, name + " Residual [-]", 'anderson')
    PROST.lme.normality_check(randomEffects(lme), name + " Random Effects " + unit, 'anderson')

    % Residuals vs fitted, and equal residual variance across datasets
    figure(Name=name + " Residuals vs Fitted")
    scatter(fitted(lme), res, 15, data.DatasetID, 'filled')
    yline(0, '--r')
    xlabel("Fitted values " + unit)
    ylabel('Pearson residuals [-]')
    title(name + " Residuals vs Fitted", 'Interpreter', 'none')
    if numel(categories(data.DatasetID)) > 1
        p = vartestn(res, data.DatasetID, "Display", "off", "TestType", "BrownForsythe");
        fprintf('Brown-Forsythe test of equal residual variance across datasets: p = %.4g\n', p)
    end

    % Linearity: marginal residuals (response - fixed part) carry both the leg
    % and the participant deviations, so a missed curve in a participant-level
    % covariate shows in them as well
    res_marginal = residuals(lme, 'Conditional', false);
    continuous = spec.terms(endsWith(spec.terms, "_c") & ~contains(spec.terms, ":"));
    for term = continuous
        figure(Name=name + " Marginal Residuals vs " + term)
        scatter(data.(term), res_marginal, 15, data.DatasetID, 'filled')
        hold on
        [x_sorted, order] = sort(data.(term));
        plot(x_sorted, smoothdata(res_marginal(order), 'loess', ceil(0.3*height(data))), 'r-', 'LineWidth', 1.5)
        yline(0, '--k')
        xlabel(term, 'Interpreter', 'none')
        ylabel("Marginal residuals " + unit)
        title(name + " Marginal Residuals vs " + term, 'Interpreter', 'none')

        data_q = data;
        data_q.quad = data.(term).^2;
        formula_q = replace(char(lme.Formula), ' + (', ' + quad + ('); % fixed terms precede the random ones
        lme_q = fitlme(data_q, formula_q, 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
        q = lme_q.Coefficients(strcmp(lme_q.CoefficientNames, 'quad'), :);
        fprintf('Quadratic term in %s: %.4g, 95%% CI [%.4g, %.4g]\n', term, q.Estimate, q.Lower, q.Upper)
    end

    % Collinearity of the fixed effects (excluding the intercept)
    X = designMatrix(lme, 'Fixed');
    X = X(:, 2:end);
    if size(X, 2) > 1
        vif = diag(inv(corrcoef(X)))';
        fprintf('VIF: %s\n', strjoin(string(lme.CoefficientNames(2:end)) + " = " + compose("%.2f", vif), ', '))
    end

    % Influence of single participants on the pseudo-R2
    if ~isempty(baseline)
        participant = findgroups(data.DatasetID, data.ParticipantID);
        n_participants = max(participant);
        pseudo_R2 = nan(n_participants, 1);
        for k = 1:n_participants
            keep = participant ~= k;
            lme_k = fitlme(data(keep, :), char(lme.Formula), 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
            lme_base_k = fitlme(data(keep, :), char(baseline.lme.Formula), 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
            [~, tau2_k] = PROST.lme.model_metrics(lme_k, Display="off");
            [~, tau2_base_k] = PROST.lme.model_metrics(lme_base_k, Display="off");
            pseudo_R2(k) = 1 - tau2_k / tau2_base_k;
        end
        [~, k_max] = max(abs(pseudo_R2 - results.pseudo_R2));
        first = find(participant == k_max, 1);
        fprintf('Leave-one-participant-out pseudo-R2: %.3f to %.3f (full %.3f); largest change %.3f without dataset %s participant %s\n', ...
            min(pseudo_R2), max(pseudo_R2), results.pseudo_R2, pseudo_R2(k_max) - results.pseudo_R2, ...
            string(data.DatasetID(first)), string(data.ParticipantID(first)))
    end
end
