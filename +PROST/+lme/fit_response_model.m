function results = fit_response_model(data, spec)
% RESULTS = FIT_RESPONSE_MODEL(DATA, SPEC)
% Fits the final LME model of one response and prints its fixed effects and
% variance decomposition.
%
% Input :
%   data - the data table of measurements, after the cutoff.
%   spec - struct with fields:
%          name  - the response column name, e.g. 'log_R_H'.
%          scale - "linear" or "log". Only "log" gets the ICC back-transformed
%                  to the original scale.
%
% Output :
%   results - struct with fields lme, beta4 (estimate, SE, t, p, CI of the
%             effects-coded DatasetID 4), tau2, sigma2, ICC (model scale) and
%             ICC_original (log scale only).
%
% Example usage :
%   results = PROST.lme.fit_response_model(data_final, struct('name', 'log_R_H', 'scale', "log"))

    response_name = spec.name;
    is_log = PROST.lme.is_log_scale(spec);

    formula = [response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];

    % Final Cutoff LME Model
    lme = fitlme(data, formula, ...
        'FitMethod', 'REML', ...
        'DummyVarCoding', 'effects');

    disp(lme)

    % Extract estimates and covariance for the three estimated DatasetID coefficients
    coefNames = lme.Coefficients.Name;
    idx = contains(coefNames, 'DatasetID');

    b = lme.Coefficients.Estimate(idx);       % [b1; b2; b3]
    V = lme.CoefficientCovariance(idx, idx);  % 3x3 covariance submatrix

    % Contrast vector: beta4 = -(b1+b2+b3) = c' * b, where c = [-1;-1;-1]
    c = [-1; -1; -1];

    beta4 = c' * b;
    se_beta4 = sqrt(c' * V * c);

    df = lme.Coefficients.DF(find(idx,1));  % use same residual DF as other fixed effects
    tstat = beta4 / se_beta4;
    pval = 2 * (1 - tcdf(abs(tstat), df));
    ci_lower = beta4 - tinv(0.975, df) * se_beta4;
    ci_upper = beta4 + tinv(0.975, df) * se_beta4;

    fprintf('\n--- %s - Fixed Effects Values ---\n', response_name);
    for idx=2:4
        fprintf('%s: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
            lme.Coefficients.Name{idx}, ...
            lme.Coefficients.Estimate(idx), ...
            lme.Coefficients.SE(idx), ...
            lme.Coefficients.tStat(idx), ...
            lme.Coefficients.pValue(idx), ...
            lme.Coefficients.Lower(idx), ...
            lme.Coefficients.Upper(idx));
    end
    fprintf('DatasetID_4: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
        beta4, se_beta4, tstat, pval, ci_lower, ci_upper);

    % Display metrics formatted for publication
    [ICC, tau2, sigma2] = PROST.lme.model_metrics(lme, "Final LME Model - " + response_name);
    ICC = ICC(1); % ICC1 = tau2 / (tau2 + sigma2), the definition the bootstrap also uses

    results.lme = lme;
    results.beta4 = struct('Estimate', beta4, 'SE', se_beta4, 'tStat', tstat, ...
                           'pValue', pval, 'Lower', ci_lower, 'Upper', ci_upper);
    results.tau2 = tau2;
    results.sigma2 = sigma2;
    results.ICC = ICC;

    if is_log
        ICC_original = PROST.lme.icc_original_scale(tau2, sigma2);
        fprintf('ICC back-transformed to the original scale:          %8.4f\n', ICC_original);
        results.ICC_original = ICC_original;
    end
end
