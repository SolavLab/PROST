function per_dataset = per_dataset_icc(data, spec, n_boot, boot_seed, do_boot)
% PER_DATASET = PER_DATASET_ICC(DATA, SPEC, N_BOOT, BOOT_SEED, DO_BOOT)
% Fits the response of SPEC to each dataset alone, with only the participant
% random intercept, and reports its variance components and ICC. With DO_BOOT,
% adds participant-cluster bootstrap SEs and percentile CIs.
% All datasets are resampled in one stratified bootstrap, not one bootstrap per
% dataset: a replicate then draws each dataset from its own segment of the
% random stream, so the datasets are resampled independently and quantities that
% pair draws across datasets (differences, heterogeneity) are valid. Separate
% calls with one seed would reuse the same random numbers in every dataset.
%
% Input :
%   data - the data table of measurements, after the cutoff.
%   spec - struct with fields name (the response column) and scale ("linear"
%          or "log"). Only "log" gets the ICC back-transformed to the original scale.
%   n_boot - number of bootstrap replicates.
%   boot_seed - the seed of the bootstrap random stream (see PROST.utils.boot_stream).
%   do_boot - whether to run the bootstrap.
%
% Output :
%   per_dataset - struct with fields:
%                 table - one row per dataset: counts, tau2, sigma2, ICC (and
%                         ICC_original for log), and with DO_BOOT the SE, CI and
%                         share of converged and of boundary (tau2 = 0) replicates.
%                 boot  - with DO_BOOT, the valid draws of tau2, sigma2 and ICC
%                         per dataset (n_boot x n_datasets each, NaN if failed).
%
% Example usage :
%   per_dataset = PROST.lme.per_dataset_icc(data_final, struct('name', 'log_R', 'scale', "log"), 5000, 20261006, true)

    response_name = spec.name;
    is_log = PROST.lme.is_log_scale(spec);
    datasets = categories(removecats(data.DatasetID));
    n_datasets = numel(datasets);

    % Point estimates. Fitted outside a try, so a systematic error stops here
    % instead of passing silently as failed bootstrap refits.
    stat = PROST.lme.per_dataset_icc_refit(data, response_name, datasets, false);
    estimates = reshape(stat, 3, n_datasets)'; % rows: datasets; columns: tau2, sigma2, ICC

    n_participants = zeros(n_datasets, 1);
    n_legs = zeros(n_datasets, 1);
    n_bilateral = zeros(n_datasets, 1);
    for d = 1:n_datasets
        legs_per_participant = countcats(removecats(data.ParticipantID(data.DatasetID == datasets{d})));
        legs_per_participant = legs_per_participant(legs_per_participant > 0);
        n_participants(d) = numel(legs_per_participant);
        n_legs(d) = sum(legs_per_participant);
        n_bilateral(d) = sum(legs_per_participant == 2);
    end

    T = table(string(datasets), n_participants, n_legs, n_bilateral, ...
              estimates(:, 1), estimates(:, 2), estimates(:, 3), ...
              'VariableNames', {'DatasetID', 'n_participants', 'n_legs', 'n_bilateral', 'tau2', 'sigma2', 'ICC'});
    if is_log
        T.ICC_original = PROST.lme.icc_original_scale(T.tau2, T.sigma2);
    end

    per_dataset = struct();
    if do_boot
        gcp; % start the parallel pool here, so toc times only the bootstrap
        tic
        [boot_draws, fail_msg] = PROST.utils.cluster_bootstrap(data, @(boot_data, ~) ...
            PROST.lme.per_dataset_icc_refit(boot_data, response_name, datasets, true), ...
            n_boot, boot_seed, NStat=3*n_datasets, Parallel=true);
        toc
        if all(fail_msg ~= "")
            error("Every per-dataset bootstrap replicate failed: %s", fail_msg(1))
        end

        tau2_boot   = boot_draws(:, 1:3:end);
        sigma2_boot = boot_draws(:, 2:3:end);
        ICC_boot    = boot_draws(:, 3:3:end);
        valid = ~isnan(ICC_boot);

        ICC_CI = prctile(ICC_boot, [2.5 97.5], 1)'; % prctile ignores NaN per column
        T.ICC_SE = std(ICC_boot, 0, 1, 'omitnan')';
        T.ICC_CI_lower = ICC_CI(:, 1);
        T.ICC_CI_upper = ICC_CI(:, 2);
        if is_log
            ICC_original_boot = PROST.lme.icc_original_scale(tau2_boot, sigma2_boot);
            ICC_original_CI = prctile(ICC_original_boot, [2.5 97.5], 1)';
            T.ICC_original_CI_lower = ICC_original_CI(:, 1);
            T.ICC_original_CI_upper = ICC_original_CI(:, 2);
        end
        T.pct_converged = 100*mean(valid, 1)';
        % Replicates at the boundary tau2 = 0 pile up at ICC = 0 and make the
        % percentile CI less reliable; reported so their share can be judged
        T.pct_boundary = 100*(sum(valid & ICC_boot < 1e-6, 1) ./ sum(valid, 1))';

        per_dataset.boot = struct('seed', boot_seed, 'n_boot', n_boot, 'fail_msg', fail_msg, ...
                                  'tau2', tau2_boot, 'sigma2', sigma2_boot, 'ICC', ICC_boot);
    end
    per_dataset.table = T;

    fprintf('\n--- %s - Per-Dataset ICC (participant random intercept only) ---\n', response_name)
    disp(T)
end
