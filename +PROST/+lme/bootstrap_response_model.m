function boot_results = bootstrap_response_model(data, spec, results, n_boot, boot_seed)
% BOOT_RESULTS = BOOTSTRAP_RESPONSE_MODEL(DATA, SPEC, RESULTS, N_BOOT, BOOT_SEED)
% Cluster (participant-level), stratified-by-dataset bootstrap of a fitted response
% model: SE and percentile CIs of the fixed effects, variance components and ICC
% (and of the original-scale ICC for a log-scale response). Prints the results.
%
% Input :
%   data - the data table the model was fitted on.
%   spec - struct with fields name (the response column) and scale ("linear"
%          or "log").
%   results - the output of fit_response_model for this response.
%   n_boot - number of bootstrap replicates.
%   boot_seed - the seed of the bootstrap random stream (see PROST.utils.boot_stream).
%
% Example usage :
%   boot = PROST.lme.bootstrap_response_model(data_final, spec, results.log_R, 5000, 20261006)

    response_name = spec.name;
    is_log = PROST.lme.is_log_scale(spec);
    lme = results.lme;
    beta4 = results.beta4.Estimate;
    tau2 = results.tau2;
    sigma2 = results.sigma2;
    ICC = results.ICC;
    if is_log
        ICC_original = results.ICC_original;
    end

    gcp; % start the parallel pool here, so toc times only the bootstrap
    tic

    % lme_refit picks the weights of the resampled rows by row number
    assert(height(data) == height(lme.ObservationInfo), ...
        "data must be the table the model was fitted on.")

    % Columns: fixed effects (grand mean + dataset IDs), tau2, sigma2, ICC
    n_fixed = height(lme.Coefficients) + 1;
    [boot_draws, fail_msg] = PROST.utils.cluster_bootstrap(data, @(boot_data, boot_rows) ...
        PROST.lme.lme_refit(boot_data, boot_rows, lme), n_boot, boot_seed, NStat=n_fixed + 3, Parallel=true);
    toc
    beta_boot   = boot_draws(:, 1:n_fixed);
    tau2_boot   = boot_draws(:, n_fixed + 1); % participant-level random intercept variance
    sigma2_boot = boot_draws(:, n_fixed + 2); % residual variance
    ICC_boot    = boot_draws(:, n_fixed + 3); % ICC on the model scale

    valid = ~any(isnan([beta_boot, tau2_boot, sigma2_boot]), 2);
    fprintf('\n--- %s - Bootstrapping Inferences Results ---\n', response_name)
    fprintf('%.0f%% (of %d) bootstrap refits converged (seed %d)\n', 100*mean(valid), n_boot, boot_seed);
    if any(~valid)
        reasons = fail_msg(~valid);
        reasons(reasons == "") = "<refit returned NaN without an error>";
        [reasons, ~, k] = unique(reasons);
        fprintf('Discarded refits by reason:\n');
        for m = 1:numel(reasons)
            fprintf('  %d x %s\n', sum(k == m), reasons(m));
        end
    end

    names = [lme.CoefficientNames 'DatasetID_4' 'tau2' 'sigma2' 'ICC'];
    estimates = [lme.Coefficients.Estimate; beta4; tau2; sigma2; ICC];
    draws = [beta_boot, tau2_boot, sigma2_boot, ICC_boot];
    if is_log
        names = [names 'ICC_original'];
        estimates = [estimates; ICC_original];
        draws = [draws, PROST.lme.icc_original_scale(tau2_boot, sigma2_boot)];
    end
    draws = draws(valid, :);

    % Percentile method
    CI = prctile(draws, [2.5 97.5], 1);
    boot_inferences = table(estimates, mean(draws, 1)', std(draws, 0, 1)', CI(1, :)', CI(2, :)', ...
                       'VariableNames', {'LmeEstimate', 'BootEstimate' 'SE', 'CI_lower', 'CI_upper'}, ...
                       'RowNames', names);
    disp(boot_inferences)

    ICC_draws = draws(:, strcmp(names, 'ICC'));
    PROST.lme.normality_check(ICC_draws, "Bootstrap ICC - " + response_name, 'anderson')
    fprintf('\nICC (%s scale): Bootstrap mean: %.4f, median: %.4f, original point estimate: %.4f\n', ...
            spec.scale, mean(ICC_draws), median(ICC_draws), ICC);
    if is_log
        ICC_original_draws = draws(:, strcmp(names, 'ICC_original'));
        PROST.lme.normality_check(ICC_original_draws, "Bootstrap ICC original scale - " + response_name, 'anderson')
        fprintf('ICC (original scale): Bootstrap mean: %.4f, median: %.4f, original point estimate: %.4f\n', ...
                mean(ICC_original_draws), median(ICC_original_draws), ICC_original);
    end

    boot_results.seed = boot_seed;
    boot_results.n_boot = n_boot;
    boot_results.valid = valid;
    boot_results.fail_msg = fail_msg;
    boot_results.beta = beta_boot(valid, :);
    boot_results.tau2 = tau2_boot(valid);
    boot_results.sigma2 = sigma2_boot(valid);
    boot_results.ICC = ICC_draws;
    if is_log
        boot_results.ICC_original = ICC_original_draws;
    end
    boot_results.boot_inferences = boot_inferences;
end
