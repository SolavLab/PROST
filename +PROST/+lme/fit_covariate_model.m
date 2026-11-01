function results = fit_covariate_model(data, spec, baseline, n_all)
% RESULTS = FIT_COVARIATE_MODEL(DATA, SPEC, BASELINE, N_ALL)
% Fits one covariate model, prints its fixed effects and variance components and,
% if it has a baseline, the level-2 pseudo-R2 = 1 - tau2 / tau2_baseline: the
% share of the between-participant variance that the added terms explain. It is
% negative when tau2 grows.
%
% Input :
%   data - the rows of the model (see covariate_model_data).
%   spec - one element of covariate_models.
%   baseline - the results of the baseline model, or struct([]) for none. Must
%              have been fitted on the same rows.
%   n_all - number of legs before the cutoff and complete-case selection.
%
% Example usage :
%   r = PROST.lme.fit_covariate_model(model_data, spec, results.covariate_models.base_cc, height(data))

    fixed = string(spec.response) + " ~ 1";
    if numel(categories(data.DatasetID)) > 1 % a single dataset has no dataset effect
        fixed = fixed + " + DatasetID";
    end
    formula = strjoin([fixed, spec.terms, ...
                       "(1|DatasetID:ParticipantID)"], " + ");
    lme = fitlme(data, formula, 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
    [ICC, tau2, sigma2] = PROST.lme.model_metrics(lme, Display="off");

    n_participants = height(unique(data(:, ["DatasetID" "ParticipantID"])));
    fprintf('\n=== Covariate model %s: %s ===\n', spec.name, formula)
    fprintf('%d legs of %d participants (%d of %d legs without the cutoff/complete-case/dataset selection)\n', ...
        height(data), n_participants, n_all - height(data), n_all)
    disp(lme.Coefficients(:, {'Name', 'Estimate', 'SE', 'tStat', 'DF', 'pValue', 'Lower', 'Upper'}))
    fprintf('tau2 = %.4f, sigma2 = %.4f, ICC = %.4f\n', tau2, sigma2, ICC(1))

    results.formula = formula;
    results.lme = lme;
    results.n_legs = height(data);
    results.n_participants = n_participants;
    results.tau2 = tau2;
    results.sigma2 = sigma2;
    results.ICC = ICC(1);
    results.pseudo_R2 = NaN;
    if ~isempty(baseline)
        assert(isequal(baseline.lme.ObservationInfo.Excluded, lme.ObservationInfo.Excluded) && ...
               baseline.n_legs == height(data), "The model and its baseline must be fitted on the same rows.")
        results.pseudo_R2 = 1 - tau2 / baseline.tau2;
        fprintf('Level-2 pseudo-R2 vs %s: 1 - %.4f/%.4f = %.3f\n', spec.baseline, tau2, baseline.tau2, results.pseudo_R2)

        % Joint test of the added terms. REML likelihoods are not comparable
        % between different fixed effects, so both models are refitted with ML.
        lme_ml = fitlme(data, formula, 'FitMethod', 'ML', 'DummyVarCoding', 'effects');
        lme_base_ml = fitlme(data, char(baseline.lme.Formula), 'FitMethod', 'ML', 'DummyVarCoding', 'effects');
        lrt = compare(lme_base_ml, lme_ml);
        results.lrt = struct('LRStat', lrt.LRStat(2), 'deltaDF', lrt.deltaDF(2), 'pValue', lrt.pValue(2));
        fprintf('ML likelihood-ratio test vs %s: LR = %.3f, df = %d, p = %.4g\n', ...
            spec.baseline, lrt.LRStat(2), lrt.deltaDF(2), lrt.pValue(2))
    end

    % Scaling: test the slope of log H against proportional scaling as well
    is_slope = strcmp(lme.CoefficientNames, 'log_H_c');
    if any(is_slope)
        slope = lme.Coefficients.Estimate(is_slope);
        t1 = (slope - 1) / lme.Coefficients.SE(is_slope);
        p1 = 2 * tcdf(-abs(t1), lme.Coefficients.DF(is_slope));
        fprintf('Scaling slope of log r on log H = %.3f [%.3f, %.3f]; vs 1: t = %.3f, p = %.4g\n', ...
            slope, lme.Coefficients.Lower(is_slope), lme.Coefficients.Upper(is_slope), t1, p1)
    end
end
