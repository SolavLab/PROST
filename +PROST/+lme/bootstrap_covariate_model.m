function boot_results = bootstrap_covariate_model(data, results, baseline, n_boot, boot_seed)
% BOOT_RESULTS = BOOTSTRAP_COVARIATE_MODEL(DATA, RESULTS, BASELINE, N_BOOT, BOOT_SEED)
% Cluster (participant-level), stratified-by-dataset bootstrap of a covariate
% model: SE and percentile CIs of its fixed effects, variance components, ICC and,
% with a baseline, of the pseudo-R2. The baseline is refitted on the same resample
% so the pseudo-R2 of a replicate compares the two models on the same legs. With
% the same seed every model on the same rows gets the same resamples.
%
% Example usage :
%   boot = PROST.lme.bootstrap_covariate_model(model_data, results.covariate_models.anthro, ...
%                                    results.covariate_models.base_cc, 5000, 20261006)

    lme = results.lme;
    lme_base = [];
    if ~isempty(baseline)
        lme_base = baseline.lme;
    end
    n_fixed = height(lme.Coefficients);

    gcp;
    tic
    [draws, fail_msg] = PROST.utils.cluster_bootstrap(data, @(boot_data, ~) ...
        PROST.lme.covariate_refit(boot_data, lme, lme_base), n_boot, boot_seed, NStat=n_fixed + 4, Parallel=true);
    toc

    valid = ~any(isnan(draws(:, 1:n_fixed + 3)), 2);
    fprintf('\n--- %s - Bootstrap (%.0f%% of %d refits converged, seed %d) ---\n', ...
        results.formula, 100*mean(valid), n_boot, boot_seed)
    names = [lme.CoefficientNames 'tau2' 'sigma2' 'ICC' 'pseudo_R2'];
    estimates = [lme.Coefficients.Estimate; results.tau2; results.sigma2; results.ICC; results.pseudo_R2];
    draws = draws(valid, :);
    CI = prctile(draws, [2.5 97.5], 1);
    boot_inferences = table(estimates, mean(draws, 1)', std(draws, 0, 1)', CI(1, :)', CI(2, :)', ...
        'VariableNames', {'LmeEstimate', 'BootEstimate', 'SE', 'CI_lower', 'CI_upper'}, 'RowNames', names);
    disp(boot_inferences)

    boot_results.seed = boot_seed;
    boot_results.n_boot = n_boot;
    boot_results.valid = valid;
    boot_results.fail_msg = fail_msg;
    boot_results.draws = draws;
    boot_results.names = names;
    boot_results.boot_inferences = boot_inferences;
end
