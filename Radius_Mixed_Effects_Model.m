clearvars -except PROSTAnalyzer
close all
clc

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 
warning('off', 'backtrace')

% Set the default font name
set(groot, 'defaultAxesFontName',   'Times New Roman');
set(groot, 'defaultTextFontName',   'Times New Roman');
set(groot, 'defaultLegendFontName', 'Times New Roman');

% Set the default font size
set(groot, 'defaultAxesFontSize',   14);
set(groot, 'defaultTextFontSize',   14);
set(groot, 'defaultLegendFontSize', 14);

boot_flag = false; % run the bootstrap SE/CI computation
summary_flag = false; % calculate summary statistics of the data
cutoff_test_flag = true; % test the R_H cutoff of unstable radii on the initial model
weight_test_flag = false; % test the weight scheme of each response model
assumptions_flag = false; % test the LME assumptions of each response model
loo_flag = true; % leave-one-participant-out sensitivity of the ICC of each response model
per_dataset_icc_flag = true; % ICC of each dataset on its own (bootstrap CIs need boot_flag), with a forest plot
covariate_flag = true; % side, anthropometric, speed and scaling models of log_R (bootstrap CIs need boot_flag)
covariate_diagnostics_flag = false; % assumption checks of the covariate models and the per-dataset ICC models
self_test_flag = false; % run the synthetic-data checks of the helper functions and stop
save_flag = false; % save the complete results (needs boot_flag and loo_flag) to Radius_Mixed_Effects_Results.mat
boot_seed = 20261006; % fixed so the bootstrap SE/CI are reproducible (see PROST.utils.boot_stream)
n_boot = 5000; % number of bootstrap replicates

% The saved file is the record of the reported results: a partial run must not
% overwrite a complete one.
if save_flag && ~(boot_flag && loo_flag)
    error("save_flag needs boot_flag and loo_flag: the saved file must hold the complete reported results.")
end

% Responses to model. 'scale' decides which ICC back-transform applies:
%   "log"    - the ICC is also back-transformed to the original scale
%   "linear" - the model-scale ICC is already on the original scale
responses = struct('name', {'R', 'log_R'}, 'scale', {"linear", "log"});

% Covariate models (review 1a, 1b, 4). Each adds fixed effects to
%   response ~ 1 + DatasetID + terms + (1|DatasetID:ParticipantID)
% Fields:
%   terms    - added fixed effects; a "_c" suffix is the column centred within
%              dataset (centring leaves the slopes unchanged, as DatasetID is in
%              the model, and keeps the intercept at the dataset mean).
%   complete - columns that must be non-missing: defines the rows. A model and its
%              baseline must share them, so their tau2 compare on the same legs.
%   datasets - datasets used ([] = all).
%   cut      - apply the R_H <= 1 cutoff.
%   baseline - model whose tau2 the pseudo-R2 = 1 - tau2/tau2_baseline refers to,
%              and against which the ML likelihood-ratio test of the added terms runs.
% Height enters as log H, so its slope is the elasticity of r with respect to H:
% 1 is proportional scaling, 0 no association.
% The anthropometric block is tested against the side-only model, so its test and
% pseudo-R2 isolate the anthropometrics.
anthro_rows = ["Leg" "Age" "Sex" "Height" "Mass" "Leg_length"];
anthro_terms = ["Leg" "Age_c" "Sex" "log_H_c" "Mass_c"];
covariate_models = [ ...
    struct('name', 'base_cc',       'response', 'log_R',   'terms', {strings(1, 0)}, ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', '')
    struct('name', 'side',          'response', 'log_R',   'terms', "Leg", ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'base_cc')
    struct('name', 'anthro',        'response', 'log_R',   'terms', anthro_terms, ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'side')
    struct('name', 'anthro_leglen', 'response', 'log_R',   'terms', ["Leg" "Age_c" "Sex" "log_L_c" "Mass_c"], ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'side')
    % Slope heterogeneity: one slope per dataset, tested against the common slope
    struct('name', 'anthro_het',    'response', 'log_R',   'terms', [anthro_terms ...
                                                                      "Age_c:DatasetID" "Sex:DatasetID" "log_H_c:DatasetID" "Mass_c:DatasetID"], ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'anthro')
    % Dataset 4 alone: the largest dataset, with a precise ICC, so its pseudo-R2
    % does not average over datasets with different variance components
    struct('name', 'base_D4',       'response', 'log_R',   'terms', {strings(1, 0)}, ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', '')
    struct('name', 'side_D4',       'response', 'log_R',   'terms', "Leg", ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'base_D4')
    struct('name', 'anthro_D4',     'response', 'log_R',   'terms', anthro_terms, ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'side_D4')
    struct('name', 'speed_D4',      'response', 'log_R',   'terms', "v_star_c", ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'base_D4')
    struct('name', 'base_D34',      'response', 'log_R',   'terms', {strings(1, 0)}, ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', '')
    struct('name', 'speed_D34',     'response', 'log_R',   'terms', "v_star_c", ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', 'base_D34')
    struct('name', 'speed_D34_het', 'response', 'log_R',   'terms', ["v_star_c" "v_star_c:DatasetID"], ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', 'speed_D34')
    % Scaling: slope 1 = r proportional to H, slope 0 = r unrelated to H. The
    % cutoff selects on r/H, so the slope is also reported without it.
    struct('name', 'scaling',       'response', 'log_R',   'terms', "log_H_c", ...
           'complete', "Height", 'datasets', [], 'cut', true, 'baseline', '')
    struct('name', 'scaling_nocut', 'response', 'log_R',   'terms', "log_H_c", ...
           'complete', "Height", 'datasets', [], 'cut', false, 'baseline', '')
    ]';

if self_test_flag
    self_test()
    return
end

if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

%% Create Table for Statistical Analysis
data = PROST.lme.build_analysis_table(PROSTAnalyzer);

%% Initial Model and Cutoff of Unstable R
% Defined on R_H whatever the analyzed response: the cutoff flags degenerate arc
% fits, which are a property of the leg, not of the response.
formula_initial = ['R_H ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];

% Unweighted LME Model, specified as the final models: the cutoff is tested on the
% model that is reported, and the weight scheme is only tested after the cutoff.
lme_initial = fitlme(data, formula_initial, ...
    'FitMethod', 'REML', ...
    'DummyVarCoding', 'effects');

% Test Cutoff of Unstable R
if cutoff_test_flag
    test_cutoff_unstable_R(data, lme_initial)
end

% A physiological cutoff was chosen as R > body height. This corresponds to ~5
% degree arc span
idx = data.R_H <= 1;
data_final = data(idx, :);

fprintf('Excluded %d of %d observations (%.1f%%) with R_H > 1\n', ...
    height(data) - height(data_final), height(data), ...
    100*(height(data) - height(data_final)) / height(data));

%% Linear Mixed Effects Model per Response
results = struct();
for spec = responses
    if summary_flag
        PROST.lme.describe_response(data_final, spec)
    end

    % Test Weight Scheme After Cutoff
    if weight_test_flag
        test_weight_scheme(data_final, spec.name)
    end

    results.(spec.name) = PROST.lme.fit_response_model(data_final, spec);

    % Sensitivity of the ICC to Single Participants
    if loo_flag
        results.(spec.name).loo = PROST.lme.icc_leave_one_out(results.(spec.name).lme, "Final LME - " + spec.name);
    end

    % Test Linear Mixed-Effects Model Assumptions
    if assumptions_flag
        PROST.lme.assumptions_check(results.(spec.name).lme, "Final LME - " + spec.name + ":")
    end

    if boot_flag
        results.(spec.name).boot = PROST.lme.bootstrap_response_model(data_final, spec, results.(spec.name), n_boot, boot_seed);
    end

    % Per-dataset ICC: the pooled ICC is a dataset-weighted summary under
    % dataset-dependent residual variance, so each dataset is also fitted alone
    if per_dataset_icc_flag
        results.(spec.name).per_dataset = PROST.lme.per_dataset_icc(data_final, spec, n_boot, boot_seed, boot_flag);
        PROST.lme.plot_icc_forest(results.(spec.name), spec)
    end
end

% Assumption checks of the per-dataset ICC models
if covariate_diagnostics_flag
    PROST.lme.per_dataset_diagnostics(data_final, 'log_R')
end

%% Covariate Models: Side, Anthropometrics, Speed and Scaling
% How much of the between-participant variance tau2 the covariates explain
if covariate_flag
    results.covariate_models = struct();
    for model_spec = covariate_models
        if model_spec.cut
            model_data = PROST.lme.covariate_model_data(data_final, model_spec);
        else
            model_data = PROST.lme.covariate_model_data(data, model_spec);
        end
        baseline = struct([]);
        if ~isempty(model_spec.baseline)
            baseline = results.covariate_models.(model_spec.baseline);
        end
        results.covariate_models.(model_spec.name) = PROST.lme.fit_covariate_model(model_data, model_spec, baseline, height(data));
        if covariate_diagnostics_flag && ismember(model_spec.name, ["anthro" "anthro_D4" "speed_D34" "speed_D4" "scaling"])
            PROST.lme.covariate_diagnostics(model_data, results.covariate_models.(model_spec.name), baseline, model_spec)
        end
        if boot_flag
            results.covariate_models.(model_spec.name).boot = PROST.lme.bootstrap_covariate_model(model_data, ...
                results.covariate_models.(model_spec.name), baseline, n_boot, boot_seed);
        end
    end
end

% Distinct variable names, so loading the file next to other results cannot clash
if save_flag
    saved.radius_lme_results = results;
    saved.radius_lme_provenance = PROST.utils.provenance();
    save("Radius_Mixed_Effects_Results", "-struct", "saved")
end

% PROST.utils.save_all_open_figures("C:\Users\chenr\Documents\PROST\figures\ROS Analysis\Mixed-Effects Plots\Radius", ".", "file_type", "pdf", "prepare","on", "append", "off")

%% -----------------------------------------------------------------------------
% Helper Functions
% ------------------------------------------------------------------------------
function test_weight_scheme(data, response_name)
% TEST_WEIGHT_SCHEME(DATA, RESPONSE_NAME) 
% Tests which weights to use for the LMM fit. The optimal weights are those that 
% are roughly ~ 1/Var(x).
%
% Input :
%   data - the data table of measurements.
%   response_name - the name of the response variable to model.
%
% Example usage:
%   test_weight_scheme(data, "R_H")

    figure(Name="Weight Scheme - " + response_name)
    tl = tiledlayout('TileSpacing', 'compact', 'Padding', 'compact');

    % --------------------------------------------------------------------------
    % Direct empirical check: does observed RMS/variance scale as 1/n, 1/sqrt(n), 
    % or log(n)?
    % --------------------------------------------------------------------------
    % Check RMS vs number of steps used per observation
    nexttile(tl)
    scatter(data.n_steps, data.RMS, 20, 'filled');
    xlabel('n\_steps');
    ylabel('RMS');
    title('RMS vs Sample Size');
    
    [rho, p_corr] = corr(data.n_steps, data.RMS, 'Type', 'Spearman');
    fprintf('\n--- Correlation: RMS vs n_steps ---\n')
    fprintf('Spearman correlation RMS vs n_steps: rho=%.3f, p=%.4f\n', rho, p_corr);
    fprintf(['Correlation > 0 means RMS grows with n_steps since more steps means ' ...
             'capturing more data variability durring circular arc fit.\n'])
    
    % Also check at the Dataset level, since this is where the confound is most severe
    groupStats = grpstats(data(:,{'DatasetID', 'RMS', 'n_steps'}), ...
                          'DatasetID', {'mean', 'std'});
    disp(groupStats);

    % Log-log plot: slope reveals power-law relationship
    nexttile(tl)
    scatter(log(data.n_steps), log(data.RMS), 15, 'filled');
    xlabel('log(n\_steps)'); 
    ylabel('log(RMS)'); 
    title('Log-Log: check power-law slope');

    fprintf('\n--- Log-Log Correlation: log(RMS) vs log(n_steps) ---\n')
    [p, S] = polyfit(log(data.n_steps), log(data.RMS), 1);
    fprintf('Estimated power-law exponent: %.3f, R2 = %.3f\n', p(1), S.rsquared);
    % fprintf('If RMS ~ n^(0.5), exponent should be near 0.5 (supports 1/n variance, i.e. w=n)\n')
    % fprintf('If RMS ~ n^(0.25) or similar shallow slope, precision gain is sub-linear/saturating (supports log(n) or sqrt(n) weighting instead)\n')
    
    % Alternative: bin n_steps into groups and directly compare within-bin variance of R_H
    % (only meaningful if multiple observations share similar n_steps — check group sizes)
    edges = [0 2 5 10 20 50 100 150];
    data.n_steps_bin = discretize(data.n_steps, edges);
    binStats = grpstats(data(:, {'n_steps_bin', response_name}), ...
                        'n_steps_bin', {'var', 'mean', 'numel'});
    fprintf('\n--- Comparison of Within-Bin Variance of %s vs N_Steps ---\n', response_name)
    disp(binStats)

    % Bin-level variance of R_H against bin midpoint n_steps on log-log scale
    % to see empirically how variance actually declines with n_steps
    fprintf('\n--- Bin-Level Log-Log Correlation: log(Var(%s)) vs log(n_steps) ---\n', response_name)
    binMidpoints = (edges(1:end-1) + edges(2:end)) ./ 2;
    logVar = log(binStats.(['var_', response_name]));
    logN   = log(binMidpoints)';
    
    [p, S] = polyfit(logN, logVar, 1);
    fprintf('Estimated power-law exponent for Var(%s) vs n_steps: %.3f, R2 = %.3f\n', response_name, p(1), S.rsquared);
    fprintf('If exponent ~ -1: classical 1/n variance decay -> weight = n_steps is correct\n')
    fprintf('If exponent ~ -0.5: weight = sqrt(n_steps) more appropriate\n')
    fprintf(['If exponent ~ 0 or positive: NO meaningful precision gain from more steps at ' ...
             'the %s level -> weighting by n_steps may not be justified at all\n'], response_name)
    
    % Get DatasetID-adjusted residuals (removes between-dataset mean shifts)
    % Use a simple fixed-effects-only model, or just de-mean within DatasetID
    fprintf('\n--- Dataset Adjusted Variation: Var(%s) vs N_Steps ---\n', response_name)
    datasetMeans = grpstats(data.(response_name), data.DatasetID, 'mean');
    [G, ~] = findgroups(data.DatasetID);
    data.([response_name, '_centered']) = data.(response_name) - datasetMeans(G);
    
    % NOW bin by n_steps and examine variance of the CENTERED residual
    edges2 = edges;
    data.n_steps_bin = discretize(data.n_steps, edges2);
    binStats2 = grpstats(data(:,{'n_steps_bin', [response_name, '_centered']}), ...
                        'n_steps_bin', {'var', 'mean', 'numel'});
    disp(binStats2)
    
    % Refit power law on the dataset-adjusted variance
    binMidpoints = (edges2(1:end-1) + edges2(2:end)) ./ 2;
    validBins = binStats2.(['numel_', response_name, '_centered']) >= 15; % drop bins too sparse to trust
    logVar2 = log(binStats2.(['var_', response_name, '_centered'])(validBins));
    logN2   = log(binMidpoints(validBins))';
    
    [p_adjusted, S_adjusted] = polyfit(logN2, logVar2, 1);
    fprintf('Dataset-adjusted power-law exponent: %.3f, R2 = %.3f\n', p_adjusted(1), S_adjusted.rsquared);
        
    % Weighted linear regression: fit log-log slope giving more trust to larger bins
    fprintf('\n--- Weighted Correlation of Dataset-Adjusted Variation: log(Var(%s)) vs log(n_steps) ---\n', response_name)
    weights_for_fit = binStats2.(['numel_', response_name, '_centered'])(validBins);
    mdl_weighted = fitlm(logN2, logVar2, 'Weights', weights_for_fit);
    disp(mdl_weighted.Coefficients)

    % --------------------------------------------------------------------------
    % Non-weighted LMM
    % --------------------------------------------------------------------------
    formula = [response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
    lmm_no_weight = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'DummyVarCoding', 'effects');
    ICC_no_weight = PROST.lme.model_metrics(lmm_no_weight, Display="off");

    % --------------------------------------------------------------------------
    % N_steps weighted LMM
    % --------------------------------------------------------------------------
    weight_raw = data.n_steps;
    lmm_weighted = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_raw, ... 
                           'DummyVarCoding', 'effects');
    ICC_n_steps_weight = PROST.lme.model_metrics(lmm_weighted, Display="off");

    % --------------------------------------------------------------------------
    % Check: does capping extreme weights change the zero-variance result?
    % --------------------------------------------------------------------------
    % Original weight
    fprintf('Weight range: min=%.1f, max=%.1f, ratio=%.1f\n', ...
        min(weight_raw), max(weight_raw), max(weight_raw)/min(weight_raw));
    
    % No Random Effects formula
    % No Random Effects formula
    formula_noRE = [response_name ' ~ 1 + DatasetID'];

    % Try a few different capping thresholds to check sensitivity, not just one
    percentile_caps = [90, 95, 99];   
    results_table = table();
    for pc = percentile_caps
        cap_val = prctile(weight_raw, pc);
        weight_capped = min(weight_raw, cap_val);
        lmm_capped = fitlme(data, formula, ...
                            'FitMethod', 'REML', ...
                            'Weights', weight_capped, ...
                            'DummyVarCoding', 'effects');
        [ICC_capped, tau2, sigma2] = PROST.lme.model_metrics(lmm_capped, Display="off");

        % lme_initial for this capped-weight model too      
        lmm_capped_ML = fitlme(data, formula, ...
                               'FitMethod','ML', ...
                               'Weights', weight_capped, ...
                               'DummyVarCoding','effects');
        lmm_noRE_capped_ML = fitlme(data, formula_noRE, ...
                                    'FitMethod','ML', ...
                                    'Weights', weight_capped, ...
                                    'DummyVarCoding','effects');
        lrt_result = compare(lmm_noRE_capped_ML, lmm_capped_ML, 'CheckNesting', true);
        fprintf('\n--- Likelehood Ratio Test For %dth Percentile Capped Weights (Cap value %.2f) With/Without Random Effects --- \n', pc, cap_val)
        disp(lrt_result)
    
        results_table = [results_table; table(pc, cap_val, tau2, sigma2, ICC_capped(1), ICC_capped(2), ...
            'VariableNames', {'Percentile', 'CapValue', 'Tau2_Participant', 'Sigma2_Residual', 'ICC1', 'ICC2'})];
    end
    
    fprintf('\n--- Summary across capping thresholds ---\n');
    disp(results_table)

    % --------------------------------------------------------------------------
    % Check: Finer grid of caps between the 90th and 95th percentile
    % --------------------------------------------------------------------------
    % This is to find WHERE the discontinuity occurs and check if the transition 
    % is really a cliff or a gradual boundary-collapse across many cap values
    fine_percentiles = 85:1:100;
    fine_results = table();
    
    for pc = fine_percentiles
        cap_val = prctile(data.n_steps, pc);
        weight_capped = min(data.n_steps, cap_val);  
        lmm_fine = fitlme(data, formula, ...
                         'FitMethod', 'REML', ...
                         'Weights', weight_capped, ...
                         'DummyVarCoding', 'effects');
        [ICC_fine, tau2, sigma2] = PROST.lme.model_metrics(lmm_fine, Display="off");

        % At EACH point in this grid, verify with a second optimizer to rule out
        % optimizer-dependent boundary artifacts
        opts = optimoptions('fminunc');
        opts.Display = 'off';
        lmm_alt = fitlme(data, formula, ...
                        'FitMethod', 'REML', ...
                        'Weights', weight_capped, ...
                        'DummyVarCoding', 'effects', ...
                        'Optimizer', 'fminunc', ...
                        'OptimizerOptions', opts);

        ICC_altopt =  PROST.lme.model_metrics(lmm_alt, Display="off");

        fine_results = [fine_results; table(pc, cap_val, tau2, sigma2, ICC_fine(1), ICC_fine(2), ICC_altopt(1), ICC_altopt(2), ...
            'VariableNames', {'Percentile', 'CapValue', 'Tau2', 'Sigma2', 'ICC1', 'ICC2', 'ICC1_Alt', 'ICC2_Alt'})];
    end
    fprintf('\n--- Summary across fine capping thresholds ---\n');
    disp(fine_results)
    
    nexttile(tl)
    yyaxis left
    hold on
    plot(fine_results.Percentile, fine_results.ICC1, '-o', MarkerSize=10);
    plot(fine_results.Percentile, fine_results.ICC1_Alt, '-x', MarkerSize=10);
    ylabel('ICC1');
    yyaxis right
    hold on
    plot(fine_results.Percentile, fine_results.ICC2, '-o', MarkerSize=10);
    plot(fine_results.Percentile, fine_results.ICC2_Alt, '-x', MarkerSize=10);
    ylabel('ICC2');
    xlabel('Capping Percentile'); 
    legend('Quasinewton (Defalt)', 'FMinUnc')
    title('LMM - ICC vs Cap Threshold (fine grid)');
    
    % --------------------------------------------------------------------------
    % Check: uncapped weight but on a log scale (alternative to hard capping)
    % --------------------------------------------------------------------------
    % Log-transforming compresses the extreme ratio (140x -> ~5x) while
    % preserving rank order of precision, a common alternative to hard capping
    % +1 to avoid log(0) issues if any n_steps=0 and also log(1)=0 for n_steps=1
    weight_log = log(data.n_steps + 1);

    lme_log_weight = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_log, ...
                           'DummyVarCoding', 'effects');
    ICC_log_weight = PROST.lme.model_metrics(lme_log_weight, Display="off");

    % Also compare to an alternate optimizer
    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lme_log_weight_fminunc = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_log, ...
                           'DummyVarCoding', 'effects', ...
                           'Optimizer', 'fminunc', ...
                           'OptimizerOptions', opts);
    ICC_log_weight_fminunc = PROST.lme.model_metrics(lme_log_weight_fminunc, Display="off");
    
    % --------------------------------------------------------------------------
    % Check for only Dataset 4
    % --------------------------------------------------------------------------
    % Another test that eliminates inter-dataset variance due to heterogeneous
    % number of steps since dataset 4 is large (136 subjects). 
    % Test is for non-weighted and n_steps weighted (since there is still 
    % variability in number of steps per subject).
    formula_noFE = [response_name ' ~ 1 + (1|DatasetID:ParticipantID)'];
    data_dataset4 = data(data.DatasetID == "4", :);
    weight_dataset4 = weight_raw(data.DatasetID == "4");

    lmm_dataset4 = fitlme(data_dataset4, formula_noFE, ...
                          'FitMethod', 'REML', ...
                          'DummyVarCoding', 'effects');
    ICC_dataset4_no_weight =PROST.lme.model_metrics(lmm_dataset4, Display="off");

    lmm_dataset4_weighted = fitlme(data_dataset4, formula_noFE, ...
                                   'FitMethod', 'REML', ...
                                   'Weights', weight_dataset4, ...
                                   'DummyVarCoding', 'effects');
    ICC_dataset4_n_steps_weight = PROST.lme.model_metrics(lmm_dataset4_weighted, Display="off");

    % --------------------------------------------------------------------------
    % Check: uncapped weight but on sqrt(n_steps)
    % --------------------------------------------------------------------------
    % This is an alternative more conservative to the log scaling.
    % Optimizer is FMinUnc since it is stable than the default optimizer.
    weight_sqrt = sqrt(data.n_steps);

    lmm_sqrt = fitlme(data, formula, ...
                      'FitMethod', 'REML', ...
                      'Weights', weight_sqrt, ...
                      'DummyVarCoding', 'effects');
    ICC_sqrt_weight = PROST.lme.model_metrics(lmm_sqrt, Display="off");

    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lmm_sqrt_fminunc = fitlme(data, formula, ...
                      'FitMethod', 'REML', ...
                      'Weights', weight_sqrt, ...
                      'DummyVarCoding', 'effects', ...
                      'Optimizer', 'fminunc', ...
                      'OptimizerOptions', opts);
    ICC_sqrt_weight_fminunc = PROST.lme.model_metrics(lmm_sqrt_fminunc, Display="off");

    fprintf('\n--- Summary of all Weight Scheme ICCs ---\n')
    ICC_var = [ICC_no_weight NaN; ... 
               ICC_n_steps_weight; ...
               table2array(fine_results(fine_results.Percentile == 90, ["ICC1" "ICC2"])); ...
               table2array(fine_results(fine_results.Percentile == 90, ["ICC1_Alt" "ICC2_Alt"])); ...
               table2array(fine_results(fine_results.Percentile == 94, ["ICC1" "ICC2"])); ...
               table2array(fine_results(fine_results.Percentile == 94, ["ICC1_Alt" "ICC2_Alt"])); ...
               ICC_log_weight; ...
               ICC_log_weight_fminunc; ...
               ICC_dataset4_no_weight NaN; ...
               ICC_dataset4_n_steps_weight; ...
               ICC_sqrt_weight; ...
               ICC_sqrt_weight_fminunc];
    ICC_summary = table(ICC_var(:, 1), ICC_var(:, 2), ...
        'VariableNames',  {'ICC1' 'ICC2'}, ...
        'RowNames', {'No Weight', 'N_Steps', ...
        '90th Percentile Cap', '90th Percentile Cap (FMinUnc)', ...
        '94th Percentile Cap', '94th Percentile Cap (FMinUnc)', ...
        'Log', 'Log (FMinUnc)', ...
        'Dataset 4 No Weight', 'Dataset_4 N_Steps' ...
        'Sqrt', 'Sqrt (FMinUnc)'});
    disp(ICC_summary)
end

function test_cutoff_unstable_R(data, model)
% TEST_CUTOFF_UNSTABLE_R(DATA, MODEL)
% Tests what cutoff for unstable radius estimate of ROS. Some outlier radii are
% driving the model. Prints results to command window and plots the diagnostics
% in one figure.
%
% A nearly flat arc gives an ill-conditioned R, which is a property of the leg,
% so the cutoff is judged on the arc geometry. The model is used to find the
% outliers at the leg and participant levels and to test how sensitive the ICC
% is to the cutoff. The refits inherit the weights, formula and fit method of
% MODEL, so pass a model specified as the final models.
%
% Input :
%   data - the data table of measurements.
%   model - the mixed effects model to test.
%
% Example usage :
%   test_cutoff_unstable_R(data, lme_initial)

    response_name = model.ResponseName;
    weight = model.ObservationInfo.Weights;
    formula = model.Formula.char;
    excluded = model.ObservationInfo.Excluded;
    fit_method = model.FitMethod;
    is_degenerate = data.R_H > 1; % the applied cutoff

    figure(Name="Radius Instability Threshold")
    tl = tiledlayout('TileSpacing', 'compact', 'Padding', 'compact');

    % ------------------------------------------------------------------
    % Number of Steps: are the large radii from legs with few steps?
    % ------------------------------------------------------------------
    nexttile(tl)
    gscatter(data.n_steps, data.R_H, data.DatasetID);
    yline(1, '--k', 'R_H = 1', HandleVisibility='off');
    set(gca, 'YScale', 'log');
    xlabel('n\_steps'); ylabel('R\_H');
    title('R\_H vs Number of Steps (by Dataset)');
    grid on

    nexttile(tl)
    histogram(data.n_steps, 30);
    xlabel('n\_steps'); ylabel('Legs');
    title('Number of Steps Distribution');
    grid on

    [rho_steps, p_steps] = corr(data.n_steps, data.ArcSpanDeg, 'Type', 'Spearman');
    fprintf('Spearman correlation: n_steps vs arc span: rho=%.3f, p=%.4f\n', rho_steps, p_steps);

    % ------------------------------------------------------------------
    % Outlier/Influence Detection at the Leg and Participant Levels
    % ------------------------------------------------------------------
    % Both levels are needed: when both legs of a participant are degenerate, the
    % random intercept absorbs them, so their residuals look normal and only the
    % participant's random effect (BLUP) is extreme.
    std_resid = residuals(model, 'ResidualType', 'Standardized');
    nexttile(tl)
    qqplot(std_resid);
    hold on
    % Mark the legs of the applied cutoff at their Q-Q positions
    [resid_sorted, sort_idx] = sort(std_resid);
    normal_quantiles = norminv(((1:numel(resid_sorted))' - 0.5) / numel(resid_sorted));
    marked = is_degenerate(sort_idx);
    plot(normal_quantiles(marked), resid_sorted(marked), 'ro', MarkerSize=8, LineWidth=1.2)
    title('Standardized Residuals Q-Q (red: R\_H > 1)');
    [max_val, row_idx] = max(abs(std_resid));
    fprintf('Largest standardized residual: %.2f at row %d\n', max_val, row_idx);
    disp(data(row_idx, :))  % inspect the specific observation
    fprintf('Arc span: %.4f degrees (%.4f rad)\n', data.ArcSpanDeg(row_idx), data.ArcSpanRad(row_idx))

    [blup, ~, blup_stats] = randomEffects(model);
    blup_z = blup ./ std(blup);
    nexttile(tl)
    qqplot(blup_z);
    title('Participant Random Effects Q-Q (BLUP / SD)');

    fprintf('\n--- Participants with the Largest |BLUP| / SD --- \n')
    blup_group = string(blup_stats.Level); % "<DatasetID> <ParticipantID>"
    leg_group = string(data.DatasetID) + " " + string(data.ParticipantID);
    [~, order] = sort(abs(blup_z), 'descend');
    for k = order(1:5)'
        fprintf('Participant %s: BLUP = %.3f (%.1f SD)\n', blup_group(k), blup(k), blup_z(k));
        disp(data(leg_group == blup_group(k), {'DatasetID','ParticipantIDGlobal','Leg','R_H','ArcSpanDeg','n_steps'}))
    end

    % ------------------------------------------------------------------
    % Degenerate Arc Theory Check
    % ------------------------------------------------------------------
    % Flag any observation where R is implausibly large relative to anatomical scale
    threshold = median(data.(response_name)) + 5*iqr(data.(response_name)); % or another defensible cutoff
    suspect_rows = data(data.(response_name) > threshold, :);
    fprintf('\n--- Observations with Implausibly Large %s --- \n', response_name)
    disp(suspect_rows(:, {'DatasetID','ParticipantIDGlobal','Leg','R','R_H','RMS','n_steps', 'ArcSpanDeg', 'ArcSpanRad'}))
    fprintf('%d observations exceed threshold %s = %.3f (median + 5*iqr)\n', height(suspect_rows), response_name, threshold);
    
    % ------------------------------------------------------------------
    % Direct Empirical Check: does arc span predict R?
    % ------------------------------------------------------------------
    % Direct nonlinear fit of R vs arc span in radians, testing the geometric 
    % model: R_H ≈ L_H / (2*sin(theta/2)), solve for implied chord length L
    modelfun = @(b, theta) b(1) ./ (2*sin(theta/2));
    theta_rad = data.ArcSpanRad;
    b0 = 0.3; % initial guess for L_H (=L/H; unitless), rough anatomical chord length
    mdl_geom = fitnlm(theta_rad, data.R_H, modelfun, b0);
    disp(mdl_geom)
    % For small theta R_H ~ L_H / theta, so R is inversely proportional to the arc
    % span: R becomes ill-conditioned as theta -> 0, where a small change in the
    % curvature of a nearly flat arc gives a large change in R.
    
    % Calculate arc span for R_H = 1 - limit to physiological radius
    arc_span_physiological_rad = 2*asin(0.5*mdl_geom.Coefficients.Estimate(1)); % radians, for L_H = computed b1 and R_H = 1.
    arc_span_physiological_deg = rad2deg(arc_span_physiological_rad);
    fprintf('Physiological arc span corresponding to R_H = 1: %.3f degrees (%.3f rad)\n', arc_span_physiological_deg, arc_span_physiological_rad);

    % Agreement of the applied cutoff with the equivalent arc span rule
    is_narrow = data.ArcSpanDeg < arc_span_physiological_deg;
    fprintf('\n--- R_H > 1 vs Arc Span < %.3f Degrees --- \n', arc_span_physiological_deg)
    fprintf('Both: %d, only R_H > 1: %d, only arc span: %d, neither: %d\n', ...
        sum(is_degenerate & is_narrow), sum(is_degenerate & ~is_narrow), ...
        sum(~is_degenerate & is_narrow), sum(~is_degenerate & ~is_narrow));
    disp(data(xor(is_degenerate, is_narrow), {'DatasetID','ParticipantIDGlobal','Leg','R_H','ArcSpanDeg','n_steps'}))

    nexttile(tl)
    scatter(data.ArcSpanDeg, data.R_H, 15, 'filled');
    ylabel('R\_H');
    title('R\_H vs Arc Span — check for instability at low span');
    hold on;
    scatter(data.ArcSpanDeg(row_idx), data.R_H(row_idx), 100, 'r', 'filled');
    x_rad = linspace(min(data.ArcSpanRad), max(data.ArcSpanRad), 1000)';
    x_deg = rad2deg(x_rad);
    y_pred = predict(mdl_geom, x_rad);
    plot(x_deg, y_pred, 'k', LineWidth=1.5)
    xline(arc_span_physiological_deg, '--r', ...
        sprintf('%.2f%s / %.2f rad', arc_span_physiological_deg, char(176), arc_span_physiological_rad));
    yline(1, '--k', 'R_H = 1');
    label_arc_span_axis(gca)

    % Quantify: correlation between span and |R_H deviation from Dataset median|
    dataset_medians = grpstats(data.R_H, data.DatasetID, 'median');
    [G,~] = findgroups(data.DatasetID);
    data.abs_dev = abs(data.R_H - dataset_medians(G));
    [rho_span, p_span] = corr(data.ArcSpanRad, data.abs_dev, 'Type','Spearman');
    fprintf('Spearman correlation: arc span vs |R_H deviation from dataset median|: rho=%.3f, p=%.4f\n', rho_span, p_span);

    % ------------------------------------------------------------------
    % Sensitivity Sweep for Arc Span Threshold
    % ------------------------------------------------------------------
    % Candidate thresholds informed by the visual elbow (~10-15°) in plot. The first
    % rule is the uncut data and the last the applied R_H <= 1 cutoff, placed at its
    % equivalent arc span.
    candidate_thresholds =  [3, 5, 8, 10, 12, 15, 20];  % degrees
    rule_names = ["None", string(candidate_thresholds) + char(176), "R_H <= 1"];
    rule_deg = [0, candidate_thresholds, arc_span_physiological_deg];
    rule_idx = [true(height(data), 1), data.ArcSpanDeg >= candidate_thresholds, ~is_degenerate];
    sensitivity_results = table();

    for k = 1:numel(rule_names)
        th_deg = rule_deg(k);
        th_rad = deg2rad(th_deg);
        idx = rule_idx(:, k);
        data_filt = data(idx, :);
        weight_filt = weight(idx);
        excluded_filt = excluded(idx);

        n_filtered = height(data) - height(data_filt);


        lme_filt   = fitlme(data_filt, formula, ...
                            'FitMethod', fit_method, ...
                            'Weights', weight_filt, ...
                            'DummyVarCoding', 'effects', ...
                            'Exclude', excluded_filt);

        [ICC_filt, tau2_filt, sigma2_filt] = PROST.lme.model_metrics(lme_filt, Display="off");

        resid_filt = residuals(lme_filt, 'ResidualType', 'Pearson');
        [~, p_ad, adstat] = adtest(resid_filt);

        opts = optimoptions('fminunc');
        opts.Display = 'off';
        lme_alt = fitlme(data_filt, formula, ...
                         'FitMethod', fit_method, ...
                         'Weights', weight_filt, ...
                         'DummyVarCoding', 'effects', ...
                         'Exclude', excluded_filt, ...
                         'Optimizer', 'fminunc', ...
                         'OptimizerOptions', opts);

        ICC_alt = PROST.lme.model_metrics(lme_alt, Display="off");

        sensitivity_results = [sensitivity_results; ...
            table(rule_names(k), th_deg, th_rad, n_filtered, tau2_filt, sigma2_filt, ICC_filt(1), ICC_alt(1), adstat, p_ad, ...
            'VariableNames', {'Rule', 'ThresholdDeg', 'ThresholdRad', 'N_Filtered', 'Tau2', 'Sigma2', 'ICC1', 'ICC1_alt', 'AD_Statistic', 'Pvalue'})];
    end

    disp(sensitivity_results)

    is_span_rule = sensitivity_results.Rule ~= "R_H <= 1";
    nexttile(tl)
    hold on
    plot(sensitivity_results.ThresholdDeg(is_span_rule), sensitivity_results.ICC1(is_span_rule), '-o', ...
        DisplayName='Arc span threshold');
    plot(sensitivity_results.ThresholdDeg(~is_span_rule), sensitivity_results.ICC1(~is_span_rule), 'rp', ...
        MarkerSize=14, MarkerFaceColor='r', DisplayName='R_H \leq 1');
    ylabel('ICC(1)');
    title('LMM - ICC vs Arc Span Threshold');
    label_arc_span_axis(gca)
    xlabel(['Arc span threshold [' char(176) ' / rad]'])
    legend(Location='best')
    grid on

    % ------------------------------------------------------------------
    % Sanity check for better optimizer for 5 and 8 degrees and R_H <= 1
    % ------------------------------------------------------------------
    formula_noRE = model.Formula.FELinearFormula.char;
    check_names = ["5 degrees", "8 degrees", "R_H <= 1"];
    check_idx = [data.ArcSpanDeg >= 5, data.ArcSpanDeg >= 8, ~is_degenerate];
    for k = 1:numel(check_names)
        idx = check_idx(:, k);
        data_filt = data(idx, :);
        weight_filt = weight(idx);
        excluded_filt = excluded(idx);

        lmm_qn = fitlme(data_filt, formula, ...
                        'FitMethod', fit_method, ...
                        'Weights', weight_filt, ...
                        'Exclude', excluded_filt, ...
                        'DummyVarCoding','effects');
        [psi_qn, mse_qn] = covarianceParameters(lmm_qn);
        ICC_qn = psi_qn{1}(1, 1) / (psi_qn{1}(1, 1) + mse_qn);

        opts = optimoptions('fminunc');
        opts.Display = 'off';
        lmm_fu = fitlme(data_filt, formula, ...
                        'FitMethod', fit_method, ...
                        'Weights', weight_filt, ...
                        'DummyVarCoding','effects', ...
                        'Exclude', excluded_filt, ...
                        'Optimizer','fminunc', ...
                        'OptimizerOptions', opts);
        [psi_fu, mse_fu] = covarianceParameters(lmm_fu);
        ICC_fu = psi_fu{1}(1, 1) / (psi_fu{1}(1, 1) + mse_fu);

        % Manual profile: refit with tau^2 constrained near zero vs. away from zero,
        % by comparing a model that FORCES no random effect (tau^2=0) against the
        % freely-optimized model's log-likelihood
        lmm_noRE = fitlme(data_filt, formula_noRE, ...
                         'FitMethod', fit_method, ...
                         'Weights', weight_filt, ...,
                         'Exclude', excluded_filt, ...
                         'DummyVarCoding','effects');

        % Likelihood ratio test of tau^2 = 0 (the REML likelihoods are comparable,
        % as the fixed effects are the same). tau^2 = 0 lies on the boundary of the
        % parameter space, so the reference distribution is the 50:50 mixture of
        % chi2_0 and chi2_1 (Self & Liang 1987): p = 0.5 * P(chi2_1 > LRT).
        LRT = 2*(max(lmm_qn.LogLikelihood, lmm_fu.LogLikelihood) - lmm_noRE.LogLikelihood);
        p_boundary = 0.5 * chi2cdf(LRT, 1, 'upper');

        fprintf('\n--- Threshold %s ---\n', check_names(k));
        fprintf('Quasi-Newton: LogLik=%.6f, ICC=%.4f\n', lmm_qn.LogLikelihood, ICC_qn);
        fprintf('fminunc:      LogLik=%.6f, ICC=%.4f\n', lmm_fu.LogLikelihood, ICC_fu);
        fprintf('No random effect: LogLik=%.6f\n', lmm_noRE.LogLikelihood);
        fprintf('LRT of tau^2 = 0: %.3f, p = %.4g (boundary-corrected)\n', LRT, p_boundary);
    end

    % If lmm_qn (or lmm_fu)'s LogLik is only trivially higher than lmm_noRE's
    % that supports tau^2=0 genuinely being close to the true optimum at this 
    % threshold. If one of them is MEANINGFULLY higher, that one is the correct
    % answer and the other optimizer failed to find it.
end

function label_arc_span_axis(ax)
% LABEL_ARC_SPAN_AXIS(AX)
% Labels an x axis that is plotted in degrees with both units: each tick shows
% the value in degrees and, on a second line, in radians. The labels follow the
% axis limits, so they stay correct after zooming or panning.
%
% Input :
%   ax - axes whose x data are arc spans in degrees.
%
% Example usage :
%   scatter(data.ArcSpanDeg, data.R_H); label_arc_span_axis(gca)

    ax.XAxis.TickLabelInterpreter = 'tex';
    % Tick values stay automatic; only their labels are rewritten on each change
    ax.XAxis.LimitsChangedFcn = @(ruler, ~) relabel_arc_span_ticks(ruler);
    relabel_arc_span_ticks(ax.XAxis)
    xlabel(ax, "Arc span [" + char(176) + " / rad]")
end

function relabel_arc_span_ticks(ruler)
% RELABEL_ARC_SPAN_TICKS(RULER)
% Writes the degree/radian tick labels of LABEL_ARC_SPAN_AXIS for the current ticks.

    ticks = ruler.TickValues(:);
    ruler.TickLabels = compose("%g" + char(176) + "\\newline%.2f", ticks, deg2rad(ticks));
end

function left_right_difference_check(data, var_name)
    participants_global = unique(data.ParticipantIDGlobal);
    n_participants = numel(participants_global);
    delta_Variable = nan(n_participants, 1);
    delta_RMS = nan(n_participants, 1);
    mean_RMS = nan(n_participants, 1);
    n_1leg_participants = 0;

    for p=1:n_participants
        this_participant = data(data.ParticipantIDGlobal == participants_global(p), :);
        if height(this_participant) == 1
            n_1leg_participants = n_1leg_participants + 1;
            continue
        end
        delta_Variable(p) = this_participant.(var_name)(this_participant.Leg == "left") - this_participant.(var_name)(this_participant.Leg == "right");
        delta_RMS(p) = this_participant.RMS(this_participant.Leg == "left") - this_participant.RMS(this_participant.Leg == "right");
        mean_RMS(p) = (this_participant.RMS(this_participant.Leg == "left") + this_participant.RMS(this_participant.Leg == "right")) / 2;
    end

    delta_Variable = delta_Variable(~isnan(delta_Variable));
    delta_RMS = delta_RMS(~isnan(delta_RMS));
    mean_RMS = mean_RMS(~isnan(mean_RMS));

    fprintf('%d single-legged participant of %d participants (%.2f%%) not used.\n', n_1leg_participants, n_participants, 100 * n_1leg_participants / n_participants)

    fprintf('--- Left-Right %s Difference ---\n', var_name)
    fprintf('Delta %s:   Mean = %.2f, SD = %.2f\n', ...
        var_name, mean(delta_Variable), std(delta_Variable))
    fprintf('|Delta %s|: Median = %.2f, IQR = %.2f, MAD = %.2f\n', ...
        var_name, median(abs(delta_Variable)), iqr(abs(delta_Variable)), mad(abs(delta_Variable), 1))

    fprintf('--- Left-Right RMS Difference ---\n')
    fprintf('Delta RMS: Mean = %.2f, SD = %.2f\n', mean(delta_RMS), std(delta_RMS))
    fprintf('|Delta RMS|: Median = %.2f, IQR = %.2f, MAD = %.2f\n', ...
        median(abs(delta_RMS)), iqr(abs(delta_RMS)), mad(abs(delta_RMS), 1))

    fprintf('--- %s-RMS Difference Correlation ---\n', var_name)
    fprintf('Correlation Delta_%s to Delta_RMS: %.2f\n', corr(abs(delta_Variable), abs(delta_RMS)))
    fprintf('Correlation Delta_%s to mean_RMS: %.2f\n', corr(abs(delta_Variable), mean_RMS))

    PROST.lme.normality_check(delta_Variable, "Delta " + var_name + " [-]", 'anderson')
    PROST.lme.normality_check(delta_RMS, "Delta RMS [mm]", 'anderson')
end

function data = synthetic_lme_data(stream, n_per_dataset, dataset_means, tau2, sigma2)
% DATA = SYNTHETIC_LME_DATA(STREAM, N_PER_DATASET, DATASET_MEANS, TAU2, SIGMA2)
% Simulated table with the structure of the analysis data: participants nested in
% datasets, contributing one or two legs, y = dataset mean + u + e with
% u ~ N(0, tau2) per participant and e ~ N(0, sigma2) per leg.

    DatasetID = [];
    ParticipantID = [];
    y = [];
    for d = 1:numel(n_per_dataset)
        for p = 1:n_per_dataset(d)
            n_legs = 1 + (randi(stream, 4) > 1); % about 3/4 of participants are bilateral
            u = sqrt(tau2) * randn(stream);
            DatasetID = [DatasetID; repmat(d, n_legs, 1)]; %#ok<AGROW>
            ParticipantID = [ParticipantID; repmat(p, n_legs, 1)]; %#ok<AGROW>
            y = [y; dataset_means(d) + u + sqrt(sigma2) * randn(stream, n_legs, 1)]; %#ok<AGROW>
        end
    end
    data = table(categorical(DatasetID), categorical(ParticipantID), y, ...
                 'VariableNames', {'DatasetID', 'ParticipantID', 'y'});
    data.n_steps = randi(stream, [5 100], height(data), 1);
end

function self_test()
% SELF_TEST()
% Checks the ICC back-transform and the bootstrap helpers on synthetic data with
% known variance components. Needs no PROSTAnalyzer.mat. Errors at the first
% failed check.
%
% Example usage :
%   set self_test_flag = true at the top of the script and run it.

    stream = RandStream('Threefry', 'Seed', 1);
    fprintf('\n--- Radius_Mixed_Effects_Model self-test ---\n')

    % ------------------------------------------------------------------
    % ICC back-transform
    % ------------------------------------------------------------------
    ICC_original = PROST.lme.icc_original_scale([0; 0.07; 0.2], [0.09; 0.089; 0.05]);
    assert(isequal(size(ICC_original), [3 1]), "Back-transform is not element-wise.")
    assert(ICC_original(1) == 0, "Back-transform of tau2 = 0 is not 0.")
    fprintf('PASS: back-transform is element-wise and gives 0 for tau2 = 0\n')

    % For lognormal y = exp(mu + u + e), the correlation between two legs of the
    % same participant is the original-scale ICC by definition.
    n = 2e5;
    tau2 = 0.07;
    sigma2 = 0.089;
    u = sqrt(tau2) * randn(stream, n, 1);
    y_left  = exp(-1.38 + u + sqrt(sigma2) * randn(stream, n, 1));
    y_right = exp(-1.38 + u + sqrt(sigma2) * randn(stream, n, 1));
    ICC_empirical = corr(y_left, y_right);
    assert(abs(ICC_empirical - PROST.lme.icc_original_scale(tau2, sigma2)) < 0.01, ...
        "Back-transform %.4f does not match the simulated original-scale ICC %.4f.", ...
        PROST.lme.icc_original_scale(tau2, sigma2), ICC_empirical)
    fprintf('PASS: back-transform %.4f matches simulated original-scale ICC %.4f\n', ...
        PROST.lme.icc_original_scale(tau2, sigma2), ICC_empirical)

    % ------------------------------------------------------------------
    % model_metrics
    % ------------------------------------------------------------------
    data = synthetic_lme_data(stream, [12 8 15 25], [-1.7 -1.2 -1.1 -1.45], tau2, sigma2);
    formula = 'y ~ 1 + DatasetID + (1|DatasetID:ParticipantID)';
    lme = fitlme(data, formula, 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
    lme_weighted = fitlme(data, formula, 'FitMethod', 'REML', 'DummyVarCoding', 'effects', ...
                          'Weights', data.n_steps);

    [ICC, tau2_hat, sigma2_hat] = PROST.lme.model_metrics(lme, Display="off");
    [psi, mse] = covarianceParameters(lme);
    assert(isscalar(ICC), "Unweighted model gives more than one ICC.")
    assert(tau2_hat == psi{1}(1, 1) && sigma2_hat == mse, "Variance components differ from covarianceParameters.")
    assert(abs(ICC - tau2_hat / (tau2_hat + sigma2_hat)) < 1e-12, "ICC is not tau2 / (tau2 + sigma2).")
    assert(numel(PROST.lme.model_metrics(lme_weighted, Display="off")) == 2, "Weighted model does not give ICC1 and ICC2.")
    fprintf('PASS: model_metrics ICC1 = tau2 / (tau2 + sigma2); weighted model adds ICC2\n')

    % ------------------------------------------------------------------
    % Bootstrap resampler
    % ------------------------------------------------------------------
    n_fixed = height(lme.Coefficients) + 1;
    [boot_data, boot_rows] = PROST.utils.cluster_resample(data, PROST.utils.boot_stream(1, 1));
    stat = PROST.lme.lme_refit(boot_data, boot_rows, lme);
    assert(numel(stat) == n_fixed + 3, "Wrong number of bootstrap parameters.")
    assert(all(isfinite(stat)), "Bootstrap refit returned non-finite parameters.")
    beta = stat(1:n_fixed);
    assert(abs(beta(end) + sum(beta(2:end-1))) < 1e-12, "Last dataset effect is not minus the sum of the others.")
    fprintf('PASS: lme_refit refits an unweighted model\n')

    stat_weighted = PROST.lme.lme_refit(boot_data, boot_rows, lme_weighted);
    assert(all(isfinite(stat_weighted)), "Weighted bootstrap refit returned non-finite parameters.")
    assert(~isequal(stat_weighted, stat), "Weights were not applied to the refit.")
    fprintf('PASS: lme_refit refits a weighted model\n')

    for d = categories(data.DatasetID)'
        original = data(data.DatasetID == d{1}, :);
        resampled = boot_data(boot_data.DatasetID == d{1}, :);
        assert(numel(unique(resampled.ParticipantID)) == numel(unique(original.ParticipantID)), ...
            "Dataset %s: resample has a different number of participants.", d{1})
        for g = unique(resampled.ParticipantID)'
            legs = resampled(resampled.ParticipantID == g, :);
            assert(isscalar(unique(legs.ParticipantIDOriginal)), ...
                "Dataset %s: a resampled participant merges several originals.", d{1})
            assert(height(legs) == sum(original.ParticipantID == legs.ParticipantIDOriginal(1)), ...
                "Dataset %s: a resampled participant does not carry all its legs.", d{1})
        end
    end
    fprintf('PASS: resampling is stratified by dataset and keeps participants whole\n')

    refit = @(boot_data, boot_rows) PROST.lme.lme_refit(boot_data, boot_rows, lme);
    draws = PROST.utils.cluster_bootstrap(data, refit, 3, 1, NStat=n_fixed + 3);
    assert(isequal(draws(1, :), stat), "Replicate 1 differs from substream 1.")
    assert(isequal(PROST.utils.cluster_bootstrap(data, refit, 3, 1, NStat=n_fixed + 3, Parallel=true), draws), ...
        "Parallel replicates differ from serial ones.")
    assert(~isequal(draws(2, :), draws(1, :)), "Different substreams give the same results.")
    fprintf('PASS: replicates are reproducible per substream, serially and in parallel\n')

    [draws_bad, fail_bad] = PROST.utils.cluster_bootstrap(removevars(data, 'y'), refit, 2, 1, NStat=n_fixed + 3);
    assert(all(fail_bad ~= "") && all(isnan(draws_bad), 'all'), "A failed refit was not reported.")
    fprintf('PASS: a failed refit returns NaN and its error message\n')

    % ------------------------------------------------------------------
    % Per-dataset ICC
    % ------------------------------------------------------------------
    datasets = categories(data.DatasetID);
    stat_pd = PROST.lme.per_dataset_icc_refit(data, 'y', datasets, false);
    assert(numel(stat_pd) == 3*numel(datasets) && all(isfinite(stat_pd)), ...
        "Per-dataset refit did not return [tau2, sigma2, ICC] per dataset.")
    lme_4 = fitlme(data(data.DatasetID == datasets{4}, :), 'y ~ 1 + (1|ParticipantID)', 'FitMethod', 'REML');
    assert(abs(stat_pd(end) - PROST.lme.model_metrics(lme_4, Display="off")) < 1e-12, ...
        "Per-dataset ICC differs from a direct fit of that dataset.")
    data_bad = data;
    data_bad.y(data_bad.DatasetID == datasets{2}) = NaN; % fitlme errors with no usable rows
    stat_bad = PROST.lme.per_dataset_icc_refit(data_bad, 'y', datasets, true);
    assert(all(isnan(stat_bad(4:6))) && isequal(stat_bad([1:3 7:end]), stat_pd([1:3 7:end])), ...
        "A failed dataset fit did not give NaN for that dataset only.")
    fprintf('PASS: per-dataset ICC matches a direct fit; a failed dataset NaNs only itself\n')

    % One stratified bootstrap: the datasets of a replicate are resampled from
    % different random numbers. Same-size strata would draw identical index
    % vectors if the stream restarted per dataset.
    data_eq = synthetic_lme_data(stream, [20 20], [0 0], tau2, sigma2);
    [boot_eq, ~] = PROST.utils.cluster_resample(data_eq, PROST.utils.boot_stream(1, 1));
    drawn = cell(1, 2);
    for d = 1:2
        stratum = boot_eq(boot_eq.DatasetID == string(d), :);
        [~, first_leg] = unique(stratum.ParticipantID); % one row per draw, in draw order
        drawn{d} = double(string(stratum.ParticipantIDOriginal(first_leg)));
    end
    assert(~isequal(drawn{1}, drawn{2}), "Strata of one replicate reuse the same random numbers.")
    fprintf('PASS: strata of one bootstrap replicate are resampled independently\n')

    % ------------------------------------------------------------------
    % Covariate models
    % ------------------------------------------------------------------
    % A participant-level covariate x carries half of tau2: y gains beta*x with
    % beta^2 * var(x) = tau2/2, so the pseudo-R2 should be near 0.5.
    data_cov = synthetic_lme_data(stream, [60 60 80 120], [-1.7 -1.2 -1.1 -1.45], tau2/2, sigma2);
    [~, ~, participant] = unique(data_cov(:, {'DatasetID', 'ParticipantID'}));
    x_participant = randn(stream, max(participant), 1);
    beta_x = sqrt(tau2/2);
    data_cov.x = x_participant(participant);
    data_cov.y = data_cov.y + beta_x * data_cov.x;
    spec_base = struct('name', 'base', 'response', 'y', 'terms', {strings(1, 0)}, ...
                       'complete', "x", 'datasets', [], 'cut', true, 'baseline', '');
    spec_x = spec_base;
    spec_x.name = 'x_model';
    spec_x.terms = "x_c";
    spec_x.baseline = 'base';
    base = PROST.lme.fit_covariate_model(PROST.lme.covariate_model_data(data_cov, spec_base), spec_base, struct([]), height(data_cov));
    x_data = PROST.lme.covariate_model_data(data_cov, spec_x);
    assert(all(abs(groupsummary(x_data, "DatasetID", "mean", "x_c").mean_x_c) < 1e-12), ...
        "The _c column is not centred within dataset.")
    with_x = PROST.lme.fit_covariate_model(x_data, spec_x, base, height(data_cov));
    beta_hat = with_x.lme.Coefficients.Estimate(strcmp(with_x.lme.CoefficientNames, 'x_c'));
    assert(abs(beta_hat - beta_x) < 0.05, "Covariate slope %.3f is not near the simulated %.3f.", beta_hat, beta_x)
    assert(with_x.pseudo_R2 > 0.2 && with_x.pseudo_R2 < 0.8, "Pseudo-R2 %.3f is not near the simulated 0.5.", with_x.pseudo_R2)
    [boot_cov, ~] = PROST.utils.cluster_resample(x_data, PROST.utils.boot_stream(1, 1));
    stat_cov = PROST.lme.covariate_refit(boot_cov, with_x.lme, base.lme);
    assert(numel(stat_cov) == height(with_x.lme.Coefficients) + 4 && all(isfinite(stat_cov)), ...
        "covariate_refit did not return [beta, tau2, sigma2, ICC, pseudo_R2].")
    fprintf('PASS: covariate slope %.3f (simulated %.3f), pseudo-R2 %.3f (simulated 0.5)\n', ...
        beta_hat, beta_x, with_x.pseudo_R2)

    fprintf('All self-tests passed.\n')
end
