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

if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

response_name = 'log_R_H';
boot_flag = false;
summary_flag = false;

%% Create Table for Statistical Analysis
% Read from IPDTable
radius = table2array(PROSTAnalyzer.get_IPD_samples("Radius"));
horizontal = table2array(PROSTAnalyzer.get_IPD_samples("Center_horizontal"));
vertical = table2array(PROSTAnalyzer.get_IPD_samples("Center_vertical"));
residual = table2array(PROSTAnalyzer.get_IPD_samples("Residual_rms"));
predictors = PROSTAnalyzer.get_predictors();
height = PROST.utils.convert_units(predictors.Height, "m", "mm");
angle_start = table2array(PROSTAnalyzer.get_IPD_samples("Ang_start"));
angle_end = table2array(PROSTAnalyzer.get_IPD_samples("Ang_end"));
arc_span = table2array(PROSTAnalyzer.get_IPD_samples("Arc_length"));

% Create table for statistical analysis
data = table;

% Random and Fixed Effects Parameters
data.DatasetID = table2array(PROSTAnalyzer.get_IPD_samples("Dataset_id"));
data.ParticipantID = table2array(PROSTAnalyzer.get_IPD_samples("Participant_id"));
data.ParticipantIDGlobal = data.DatasetID.*1000 + data.ParticipantID;
data.Leg = categorical(table2array(PROSTAnalyzer.get_IPD_samples("Side")));
data.DatasetID = categorical(data.DatasetID);
data.ParticipantID = categorical(data.ParticipantID);
data.ParticipantIDGlobal = categorical(data.ParticipantIDGlobal);

% Predictors
data = [data predictors];

% Parameters to analyze
data.R = radius;
data.R_H = radius ./ height;
data.log_R_H = log(data.R_H);
data.Cx = horizontal;
data.Cy = vertical;
data.Cx_H = horizontal ./ height;
data.Cy_H = vertical ./ height;
data.AngleStartDeg = angle_start;
data.AngleStartRad = deg2rad(angle_start);
data.AngleEndDeg = angle_end;
data.AngleEndRad = deg2rad(angle_end);
data.ArcSpanDeg = arc_span;
data.ArcSpanRad = deg2rad(arc_span);

% Parameters for weights from RMS and Number of Steps
data.RMS = residual; % RMS radial residual

% Compute number of steps for each leg
for dataset_id=1:4
    dataset = PROSTAnalyzer.get_dataset(dataset_id);
    dataset_idx = find(dataset_id == double(string(data.DatasetID)));
    for idx = dataset_idx'
        participant_id = double(string(data.ParticipantID(idx)));
        side = data.Leg(idx);
        steps = dataset.Data(participant_id == [dataset.Data.Participant_id]).Uniform_data.(string(side)).step;
        if isempty(steps) || ~dataset.Data(participant_id == [dataset.Data.Participant_id]).Uniform_data.(string(side)).Is_included
            error("Side not included even though it is in table")
        end
        data.n_steps(idx) = sum([steps.Is_included]);
    end
end

clear radius horizontal residual height predictors

%% Robust descriptive summary, by participant (use participant-level means first
if summary_flag
    % to avoid double-weighting participants with bilateral measurements)
    participantMeans = groupsummary(data(data.R_H <= 1, :), 'ParticipantIDGlobal', 'mean', response_name);

    med_RH  = median(participantMeans.("mean_" + response_name));
    iqr_RH  = iqr(participantMeans.("mean_" + response_name));
    mean_RH = mean(participantMeans.("mean_" + response_name));
    sd_RH   = std(participantMeans.("mean_" + response_name));

    fprintf('Participant-level %s: total median = %.4f, total IQR = %.4f\n', response_name, med_RH, iqr_RH);
    fprintf('Participant-level %s: total mean = %.4f, total SD = %.4f (sensitive to skew, report for completeness)\n', response_name, mean_RH, sd_RH);

    figure
    tl=tiledlayout(2, 4);
    participant_id_global = string(participantMeans.ParticipantIDGlobal);
    for d=["1" "2" "3" "4"]
        mean_per_dataset = participantMeans.("mean_" + response_name)(startsWith(participant_id_global, d));
        fprintf('\n--- Participant-level %s: Dataset %s Stats ---\n', response_name, d)
        fprintf('n = %d\n', numel(mean_per_dataset))
        fprintf('Mean (SD) = %.3f (%.3f)\n', mean(mean_per_dataset), std(mean_per_dataset))
        fprintf('Median (IQR) = %.3f (%.3f)\n', median(mean_per_dataset), iqr(mean_per_dataset))
        fprintf('Coeffcient of Variation = %.3f %%\n', 100*std(mean_per_dataset) / mean(mean_per_dataset))
        fprintf('MAD Coeffcient of Variation = %.3f %%\n', 100*mad(mean_per_dataset, 1) / median(mean_per_dataset))
        fprintf('range = %.3f, min = %.3f, max = %.3f\n', range(mean_per_dataset), min(mean_per_dataset), max(mean_per_dataset))

        nexttile(tl)
        histogram(mean_per_dataset)
        title(sprintf("Participant-level %s: Dataset %s Histogram: Skew = %.3f, Kurtosis = %.3f", response_name, d, skewness(mean_per_dataset), kurtosis(mean_per_dataset)))

        nexttile(tl)
        qqplot(mean_per_dataset)
        title(sprintf("Participant-level %s: Dataset %s QQ-Plot", response_name, d))
    end
    figure
    boxplot(participantMeans.("mean_" + response_name), extract(participant_id_global, 1))
    title(sprintf("Participant-level %s: Boxplot", response_name))
    xlabel("Dataset ID")
    ylabel(response_name)

    [p, stats] = vartestn(participantMeans.("mean_" + response_name), extract(participant_id_global, 1), 'TestType', 'LeveneAbsolute', Display='off');
    fprintf('\n--- Variance Homoscedasticity Tests ---\n')
    fprintf('Levene Absolute: fstat = %.4f, df = [%d %d], p = %.4g\n', stats.fstat, stats.df(1), stats.df(2), p);
    flignerKilleen(participantMeans.("mean_" + response_name), extract(participant_id_global, 1));
end
%% Linear Mixed Effects Model
formula_initial = ['R_H ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
formula = [response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
weight_initial = sqrt(data.n_steps);

% Weighted LME Model
opts = optimoptions('fminunc');
opts.Display = 'off';
lme_initial = fitlme(data, formula_initial, ...
    'FitMethod', 'REML', ...
    'Weight', weight_initial,...
    'DummyVarCoding', 'effects', ...
    'Optimizer', 'fminunc', ...
    'OptimizerOptions', opts);

% Test Cutoff of Unstable R
% test_cutoff_unstable_R(data, lme_initial)
idx = data.R_H <= 1;
data_final = data(idx, :);

% Test Weight Scheme After Cutoff
% test_weight_scheme(data_final, response_name)

% Final Weighted and Cutoff LME Model
lme_final = fitlme(data_final, formula, ...
    'FitMethod', 'REML', ...
    'DummyVarCoding', 'effects');

disp(lme_final)
fprintf('Excluded %d of %d observations (%.1f%%) with R_H > 1\n', ...
    height(data) - height(data_final), height(data), ...
    100*(height(data) - height(data_final)) / height(data));

% Extract estimates and covariance for the three estimated DatasetID coefficients
coefNames = lme_final.Coefficients.Name;
idx = contains(coefNames, 'DatasetID');

b = lme_final.Coefficients.Estimate(idx);       % [b1; b2; b3]
V = lme_final.CoefficientCovariance(idx, idx);  % 3x3 covariance submatrix

% Contrast vector: beta4 = -(b1+b2+b3) = c' * b, where c = [-1;-1;-1]
c = [-1; -1; -1];

beta4 = c' * b;
se_beta4 = sqrt(c' * V * c);

df = lme_final.Coefficients.DF(find(idx,1));  % use same residual DF as other fixed effects
tstat = beta4 / se_beta4;
pval = 2 * (1 - tcdf(abs(tstat), df));
ci_lower = beta4 - tinv(0.975, df) * se_beta4;
ci_upper = beta4 + tinv(0.975, df) * se_beta4;

fprintf('\n--- Fixed Effects Values ---\n');
for idx=2:4
    fprintf('%s: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
        lme_final.Coefficients.Name{idx}, ...
        lme_final.Coefficients.Estimate(idx), ...
        lme_final.Coefficients.SE(idx), ...
        lme_final.Coefficients.tStat(idx), ...
        lme_final.Coefficients.pValue(idx), ...
        lme_final.Coefficients.Lower(idx), ...
        lme_final.Coefficients.Upper(idx));
end
fprintf('DatasetID_4: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
    beta4, se_beta4, tstat, pval, ci_lower, ci_upper);

% Display metrics formatted for publication
[ICC_log, tau2, sigma2] = model_metrics(lme_final, "Final LME Model");
ICC = (exp(tau2) - 1) / (exp(tau2 + sigma2) - 1);
fprintf('ICC scaled:                                          %8.4f\n', ICC);

% Test Linear Mixed-Effects Model Assumptions
% assumptions_check(lme_final, "Final LME - " + response_name + ":")
% PROST.utils.save_all_open_figures("C:\Users\chenr\Documents\PROST\figures\ROS Analysis\Mixed-Effects Plots", ".", "file_type", "pdf", "prepare","on", "append", "off")
%% Cluster (Participant-Level), Stratified-by-Dataset Bootstrap for CIs
if boot_flag
    tic
    n_boot = 5000;

    % Preallocate storage
    n_fixed      = height(lme_final.Coefficients) + 1;
    beta_boot    = nan(n_boot, n_fixed); % fixed effects intercept point estimates (grand mean + dataset IDs)
    tau2_boot    = nan(n_boot, 1); % participant-level random intercept variance
    sigma2_boot  = nan(n_boot, 1); % residual variance
    ICC_log_boot = nan(n_boot, 1); % ICC in log scale

    parfor b = 1:n_boot
        [beta_boot(b, :), tau2_boot(b), sigma2_boot(b), ICC_log_boot(b, :)] = boot_resampler(data_final, lme_final);
    end
    ICC_boot = (exp(tau2_boot) - 1) ./ (exp(tau2_boot + sigma2_boot) - 1);
    toc
    %%    
    valid = ~any(isnan([beta_boot, tau2_boot, sigma2_boot]), 2);
    fprintf('\n--- Bootstrapping Inferences Results ---\n')
    % fprintf('Convergence warnings (discarded): %d / %d (%.1f%%)\n', n_failed_warning, n_boot, 100*n_failed_warning/n_boot);
    fprintf('%.0f%% (of %d) bootstrap refits converged\n', 100*mean(valid), n_boot);

    beta_boot = beta_boot(valid,:);
    tau2_boot = tau2_boot(valid);
    sigma2_boot = sigma2_boot(valid);
    ICC_log_boot = ICC_log_boot(valid);
    ICC_boot = ICC_boot(valid);
    
    % Percentile method
    CI_beta = prctile(beta_boot, [2.5 97.5], 1);
    CI_tau2 = prctile(tau2_boot, [2.5 97.5]);
    CI_sigma2 = prctile(sigma2_boot, [2.5 97.5]);
    CI_ICC_log = prctile(ICC_log_boot, [2.5 97.5], 1);
    CI_ICC = prctile(ICC_boot, [2.5 97.5], 1);
    
    SE_beta = std(beta_boot, 0, 1);
    SE_tau2 = std(tau2_boot);
    SE_sigma2 = std(sigma2_boot);
    SE_ICC_log = std(ICC_log_boot, 0, 1);
    SE_ICC = std(ICC_boot, 0, 1);

    boot_inferences = table([lme_final.Coefficients.Estimate; beta4; tau2; sigma2; ICC_log; ICC], ...
                       [mean(beta_boot, 1)'; mean(tau2_boot); mean(sigma2_boot); mean(ICC_log_boot); mean(ICC_boot)], ...
                       [SE_beta'; SE_tau2; SE_sigma2; SE_ICC_log; SE_ICC], ...
                       [CI_beta(1, :)'; CI_tau2(1); CI_sigma2(1); CI_ICC_log(1); CI_ICC(1)], ...
                       [CI_beta(2, :)'; CI_tau2(2); CI_sigma2(2); CI_ICC_log(2); CI_ICC(2)], ...
                       'VariableNames', {'LmeEstimate', 'BootEstimate' 'SE', 'CI_lower', 'CI_upper'}, ...
                       'RowNames', [lme_final.CoefficientNames 'DatasetID_4' 'tau2' 'sigma2' 'ICC_log' 'ICC']);
    disp(boot_inferences)

    % figure; 
    % histogram(ICC_boot(:, 1), 40, DisplayName="ICC(1)");
    % hold on
    % histogram(ICC_boot(:, 2), 40, DisplayName="ICC(2)");
    % xlabel('Bootstrapped ICC'); 
    % ylabel('Frequency');
    % title('Bootstrap Distribution of ICC');
    % legend

    normality_check(ICC_log_boot, "Bootstrap ICC_{log}", 'anderson')
    normality_check(ICC_boot, "Bootstrap ICC", 'anderson')

    fprintf('\nICC log: Bootstrap mean: %.4f, median: %.4f, original point estimate: %.4f\n', ...
            mean(ICC_log_boot), median(ICC_log_boot), ICC_log);
    fprintf('ICC: Bootstrap mean: %.4f, median: %.4f, original point estimate: %.4f\n', ...
        mean(ICC_boot), median(ICC_boot), ICC);
    
    boot_results.beta = beta_boot;
    boot_results.tau2 = tau2_boot;
    boot_results.sigma2 = sigma2_boot;
    boot_results.ICC_log = ICC_log_boot;
    boot_results.ICC = ICC_boot;
    boot_results.boot_inferences = boot_inferences;

    save('Bootstrap_Results', "boot_results")
end

%% ----------------------------------------------------------------------------- 
% Helper Functions
% ------------------------------------------------------------------------------
function normality_check(varaiable, var_name, test_type)
% TEST_NORMALITY(VAR, NAME, TEST_TYPE)
% Normality test for variable. 
% Plots a histogram against the Gaussian PDF and a QQ-plot.
% Performs a normality test and prints the result to command window.
% Ignores nan and inf values of the variable.
%
% Input :
%   varaiable - the variable to test.
%   var_name - the name of the variable to test for printing.
%   test_type - the type of test to perform. One of the following:\n\n
%              'anderson'   - Anderson-Darling (default)
%              'chi2gof'    - Chi2 goodness-of-fit
%              'lilliefors' - Kolmogorov-Smirnov (standardized)
%              'kolmogorov' - Lilliefors
%
% Example usage:
%   test_normality(var, "variable", "chi2gof")
%   test_normality(var, "variable")


arguments
    varaiable {mustBeNumeric}
    var_name  (1, 1) string
    test_type (1, 1) string {mustBeMember(test_type, ["anderson" "chi2gof" "kolmogorov" "lilliefors"])} = "anderson"
end

    varaiable = varaiable(~isnan(varaiable) & ~isinf(varaiable));

    switch test_type
    case "chi2gof"
        % Chi-squared Goodness-of-Fit test
        [h, p, stat] = chi2gof(varaiable);
        fprintf('\n--- Chi-Squared Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (Chi^2): %.2g\n', stat.chi2stat);
        fprintf('p-value:                %.2g\n', p);
    case "lilliefors"
        % Lilliefors test
        [h, p, stat, cv] = lillietest(varaiable);
        fprintf('\n--- Lilliefors Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    case "anderson"
        % Anderson-Darling test
        [h, p, stat, cv] = adtest(varaiable);
        fprintf('\n--- Anderson-Darling Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (A^2):   %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    case "kolmogorov" 
        % standardized KS vs N(0,1)
        [h, p, stat, cv] = kstest((varaiable - mean(varaiable)) / std(varaiable));
        fprintf('\n--- Standardized Kolmogorov-Smirnov Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    end

    figure(Name="QQ-plot: " + var_name)
    qqplot(varaiable)
    title("QQ-plot: " + var_name)
    grid on

    figure(Name="Histogram: " + var_name)
    histogram(varaiable, Normalization='pdf', DisplayName="Histogram")
    hold on

    xx = linspace(min(varaiable), max(varaiable), 100);
    mu = mean(varaiable);
    sigma = std(varaiable);
    median_val = median(varaiable);
    quartiles = prctile(varaiable, [25 75]);
    Q1 = quartiles(1);
    Q3 = quartiles(2);

    plot(xx, normpdf(xx, mu, sigma), 'r-', LineWidth=1.5,  LineStyle='-', DisplayName="Normal Distribution")  
    xline(mu, 'b-', LineWidth=1.5, DisplayName="Mean")
    xregion(mu - sigma, mu + sigma, FaceColor=0.7*[0 0 1], FaceAlpha= 0.1, LineStyle='none', DisplayName="\pm SD")   
    xline(median_val, 'k-', LineWidth=1.5, DisplayName="Median")
    xregion(Q1, Q3, FaceColor=(1 - 0.7)*[1 1 1], FaceAlpha= 0.1, LineStyle='none', DisplayName="IQR")

    title(var_name + " vs Normal Distribution")
    xlabel(var_name)
    ylabel('Probability Density Function')
    legend
    grid on
end

function [ICC, tau2, sigma2] = model_metrics(model, name, opts)
% [ICC, TAU2, SIGMA2] = MODEL_METRICS(MODEL, NAME)
% Computes metrics of variance components from the Mixed-Effects Model and
% displays them in the command window.
%
% Input :
%   model - the mixed effects model
%   name - the name of the model for printing. "" by default.
%
% Name-Value pair options:
%   Display - whether to display or suppress results to the command line. 
%             Specified as 'on' or 'off', or as numeric or logical 1 (true) or 0 
%             (false). A value of 'on' is equivalent to true, and 'off' is 
%             equivalent to false.
%             - "on" - display (default).
%             - "off" - suppress.
%
%   ICC - Inter-class correlation. The ratio between the random effect component
%         variance and total variance. Returns either ICC1 or [ICC1, ICC2] 
%         according to Bliese 2000:
%           ICC1 = tau^2 / (tau^2 + sigma^2)
%         If model weights exist:
%           ICC2 = tau^2 / (tau^2 + sigma^2 * mean(1./w)), w = weights.
%   tau2 - variance of the random effects component
%   sigma2 - homoscedastic variance of the residual component 
%            (assuming weight = 1).
%
% Example usage :
%   model_metrics(lme, "LMM");
%   ICC = model_metrics(lme, "LMM");
%   ICC = model_metrics(lme, Display="off");
%   [ICC, tau2, sigma2] = model_metrics(lme, "LMM");


    arguments
        model
        name    (1, 1) string = ""
        opts.Display (1, 1) matlab.lang.OnOffSwitchState = "on"
    end

    [psi, sigma2] = covarianceParameters(model);
    tau2 = psi{1}(1, 1);
    total_variance = tau2 + sigma2;
    ICC1 = tau2 ./ (tau2 + sigma2);
    ICC = ICC1;
    
    weights =  model.ObservationInfo.Weights;
    if any(diff(weights) ~= 0)
        sigma2_avg = sigma2 * mean(1 ./ weights);
        total_variance = tau2 + sigma2_avg;
        ICC2 = tau2 ./ (tau2 + sigma2_avg);
        ICC = [ICC ICC2];
    end

    if opts.Display
        % Display metrics formatted for publication
        fprintf('\n--- %s - Hierarchical Variance Decomposition Metrics ---\n', name);
        fprintf('Participant-Level Variance:                          %8.3f\n', tau2);
        fprintf('Residual-Level Variance (reference with no weights): %8.3f\n', sigma2);
        fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
        fprintf('Total Variance:                                      %8.4f\n', total_variance);
        fprintf('ICC1:                                                %8.4f\n', ICC1);
        if any(diff(weights) ~= 0)
            fprintf('Residual-Level Variance (averaged weights):          %8.3f\n', sigma2_avg);
            fprintf('ICC2:                                                %8.4f\n', ICC2);
        end
    end
end

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
    ICC_no_weight = model_metrics(lmm_no_weight, Display="off");

    % --------------------------------------------------------------------------
    % N_steps weighted LMM
    % --------------------------------------------------------------------------
    weight_raw = data.n_steps;
    lmm_weighted = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_raw, ... 
                           'DummyVarCoding', 'effects');
    ICC_n_steps_weight = model_metrics(lmm_weighted, Display="off");

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
        [ICC_capped, tau2, sigma2] = model_metrics(lmm_capped, Display="off");

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
        [ICC_fine, tau2, sigma2] = model_metrics(lmm_fine, Display="off");

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

        ICC_altopt =  model_metrics(lmm_alt, Display="off");

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
    ICC_log_weight = model_metrics(lme_log_weight, Display="off");

    % Also compare to an alternate optimizer
    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lme_log_weight_fminunc = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_log, ...
                           'DummyVarCoding', 'effects', ...
                           'Optimizer', 'fminunc', ...
                           'OptimizerOptions', opts);
    ICC_log_weight_fminunc = model_metrics(lme_log_weight_fminunc, Display="off");
    
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
    ICC_dataset4_no_weight =model_metrics(lmm_dataset4, Display="off");

    lmm_dataset4_weighted = fitlme(data_dataset4, formula_noFE, ...
                                   'FitMethod', 'REML', ...
                                   'Weights', weight_dataset4, ...
                                   'DummyVarCoding', 'effects');
    ICC_dataset4_n_steps_weight = model_metrics(lmm_dataset4_weighted, Display="off");

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
    ICC_sqrt_weight = model_metrics(lmm_sqrt, Display="off");

    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lmm_sqrt_fminunc = fitlme(data, formula, ...
                      'FitMethod', 'REML', ...
                      'Weights', weight_sqrt, ...
                      'DummyVarCoding', 'effects', ...
                      'Optimizer', 'fminunc', ...
                      'OptimizerOptions', opts);
    ICC_sqrt_weight_fminunc = model_metrics(lmm_sqrt_fminunc, Display="off");

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

function assumptions_check(model, model_name)
% TEST_LMM_ASSUMPTIONS(DATA, MODEL, RESPONSE_NAME)
% Tests the various assumptions of the mixed-effects model: 
%   - Normality of the  random effects, 
%   - Normality of the residuals, 
%   - Homoscedasticity, 
%   - Comparison to a model without random effects, 
%   - Variance function power law.
% Prints results to the command window.
%
% Input :
%   data - the data table of measurements.
%   model - the mixed effects model to test.
%
% Example usage :
%   test_lmm_assumptions(data, lmm_final, "R_H")


    arguments 
        model
        model_name (1, 1) string = "Final Model"
    end

    % ME Model Parameters
    data = model.Variables;
    excluded = model.ObservationInfo.Excluded;
    valid = ~excluded;
    response_name = model.ResponseName;
    formula = model.Formula.char;
   
    % ------------------------------------------------------------------
    % Formal Statistical Tests on Raw Vectors (Stratified/Pooled)
    % ------------------------------------------------------------------
    var_raw = data.(response_name)(valid); % Load your empirical data vectors
    RMS_raw = data.RMS(valid); % RMS residuals
    normality_check(RMS_raw, "Pooled RMS [mm]", 'anderson') % Test on pooled RMS data
    normality_check(var_raw, "Pooled " + response_name + " [-]", 'anderson') % Test continuous pooled response data

    % ------------------------------------------------------------------
    % Conditional Normality Assessment (LME Model Residuals)
    % ------------------------------------------------------------------
    model_residuals = residuals(model, 'ResidualType', 'Pearson');
    model_residuals = model_residuals(valid);
    normality_check(model_residuals, model_name + " Residual [-]", 'anderson')
    
    % ------------------------------------------------------------------
    % Normality of Random Effects (BLUPs)
    % ------------------------------------------------------------------
    random_effects = randomEffects(model);
    normality_check(random_effects, model_name + " Random Effects [-]", 'anderson')

    % ------------------------------------------------------------------
    % Homoscedasticity
    % ------------------------------------------------------------------
    mu_hat = fitted(model);
    mu_hat = mu_hat(valid);

    figure(Name=model_name + " Residuals vs Fitted")
    scatter(mu_hat, model_residuals, 20, 'filled');
    yline(0, '--r');
    xlabel('Fitted values [-]'); 
    ylabel('Pearson residuals [-]');
    title([model_name ' Residuals vs Fitted']);

    % Brown-Forsythe's test: residual variance equal across Dataset groups
    group = data.DatasetID(valid);   % categorical grouping variable

    % Brown-Forsythe test (ANOVA on absolute deviations from group median)
    [p, stats] = vartestn(model_residuals, group, "Display", "off", "TestType", "BrownForsythe");
    
    fprintf('\n--- %s - Participant-level %s Brown-Forsythe Test of Variance Homoscedasticity ---\n', model_name, response_name);
    fprintf('Rejection Decision (h): %d (where 1 = Heteroscedastic Variance)\n', p < 0.05);
    fprintf('Test Statistic (W):     %.5f\n', stats.fstat);
    fprintf('p-value:                %.5f\n', p);

    % ------------------------------------------------------------------
    % Random-effects structure: LRT - Likelihood Ratio Test
    % ------------------------------------------------------------------
    % Compare model WITH participant random intercept vs WITHOUT
    lmm_full = fitlme(data, formula, ...
                        'FitMethod','REML', ...
                        'DummyVarCoding', 'effect', ...
                        'Exclude', excluded);  % must use ML, not REML, to compare 

    % No Random Effects formula
    formula_noRE = model.Formula.FELinearFormula.char;
    lmm_reduced = fitlme(data, formula_noRE, ...
                            'FitMethod', 'REML', ...
                            'DummyVarCoding', 'effect', ...
                            'Exclude', excluded);  % must use ML, not REML, to compare
    fprintf('\n--- %s - Likelehood Ratio Test With/Without Random Effects ---\n', model_name)
    results = compare(lmm_reduced, lmm_full, 'CheckNesting', true);
    disp(results);
    
    % ------------------------------------------------------------------
    % Variance Function (Var(Y) ~ mu^P)
    % ------------------------------------------------------------------
    % Plot group means vs group variances directly
    groupMeans = splitapply(@mean, data{valid, response_name}, findgroups(data.DatasetID(valid)));
    groupVars  = splitapply(@var,  data{valid, response_name}, findgroups(data.DatasetID(valid)));

    % Fit line to log-log to check power relationship (slope~2 => Gamma, slope~3 => IG)
    p = polyfit(log(abs(groupMeans)), log(abs(groupVars)), 1);
    fprintf('\n--- %s - Variance Function Check Across Datasets Directly ---\n', model_name);
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f\n', p(1));

    figure(Name=model_name + " Per-Dataset Mean vs Variance")
    scatter(log(abs(groupMeans)), log(abs(groupVars)), 60, 'filled');
    h_l = lsline();
    h_l.Color = "red";
    h_l.LineWidth = 1.5;
    xlabel(['log(|Group Mean of ' response_name '|)']); 
    ylabel(['log(|Group Variance) of ' response_name '|)']);
    title([model_name ' Mean-Variance Relationship Across Datasets Directly ' sprintf('(slope = %.2f)', p(1))]);
    grid on

    % Bin fitted values into groups, compute empirical variance per bin,
    % then regress log(|variance|) on log(|mean|)

    % Use Pearson residuals instead of raw residuals - these already incorporate
    % the model's weight structure, so remaining heteroscedasticity reflects
    % genuine mean-variance relationship, not the weighting scheme itself
    n_bins = floor(sqrt(numel(mu_hat)));
    edges = quantile(mu_hat, linspace(0, 1, n_bins+1));
    bin_idx = discretize(mu_hat, edges);
    
    log_mean_bin = nan(n_bins, 1);
    log_var_bin  = nan(n_bins, 1);
    for b = 1:n_bins
        sel = bin_idx == b;
        if sum(sel) > 3
            log_mean_bin(b) = log(abs(mean(mu_hat(sel))));
            log_var_bin(b)  = log(abs(var(model_residuals(sel))));
        end
    end
    valid2 = ~isnan(log_mean_bin) & ~isnan(log_var_bin);
    p = polyfit(log_mean_bin(valid2), log_var_bin(valid2), 1);
    fprintf('\n--- %s - Binned Variance Function Check ---\n', model_name);
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f\n', p(1));
    
    figure(Name=model_name + " Binned Mean vs Variance")
    scatter(log_mean_bin(valid2), log_var_bin(valid2), 60, 'filled')
    hold on
    xfit = linspace(min(log_mean_bin(valid2)), max(log_mean_bin(valid2)), 50);
    plot(xfit, polyval(p, xfit), 'r-', 'LineWidth', 1.5)
    xlabel('log(|Mean of \mu_{hat} per bin|)')
    ylabel('log(|Variance of residuals per bin|)')
    title([model_name ' Mean-Variance Relationship Accross Binned \mu_{hat} ' sprintf('slope = %.2f', p(1))])
    grid on

    % Diagnose what's actually driving bin membership
    % tabulate(discretize(mu_hat, edges))  % check bin sizes are reasonably balanced
    figure(Name=model_name + " Fitted vs Dataset")
    scatter(mu_hat, data.DatasetID(valid)); % see if bins ~ perfectly separate Datasets
    xlabel('\mu_{hat} [-]')
    ylabel('Dataset ID')
    title([model_name ' Fitted vs Dataset'])
    grid on
end

function test_cutoff_unstable_R(data, model)
% TEST_CUTOFF_UNSTABLE_R(DATA, LMM)
% Tests what cutoff for unstable radius estimate of ROS. Some outlier radii are
% driving the model. Prints results to command window.
%
% Input :
%   data - the data table of measurements.
%   model - the mixed effects model to test.
%
% Example usage :
%   test_cutoff_unstable_R(data, lmm)

    response_name = model.ResponseName;
    weight = model.ObservationInfo.Weights;
    formula = model.Formula.char;
    excluded = model.ObservationInfo.Excluded;
    fit_method = model.FitMethod;

    figure(Name="Radius Instability Threshold")
    tl = tiledlayout('TileSpacing', 'compact', 'Padding', 'compact');

    % ------------------------------------------------------------------
    % Outlier/Influence Detection with Standardized Residuals
    % ------------------------------------------------------------------
    std_resid = residuals(model, 'ResidualType', 'Standardized');
    nexttile(tl)
    qqplot(std_resid);
    hold on
    title('Standardized Residuals Q-Q (leverage-adjusted)');
    [max_val, row_idx] = max(abs(std_resid));
    fprintf('Largest standardized residual: %.2f at row %d\n', max_val, row_idx);
    disp(data(row_idx, :))  % inspect the specific observation

    % ------------------------------------------------------------------
    % Degenerate Arc Theory Check
    % ------------------------------------------------------------------
    % Check the arc span for the fitted arc
    fprintf('Arc span: %.4f degrees (%.4f rad)\n', data.ArcSpanDeg(row_idx), data.ArcSpanRad(row_idx))
    
    % Simple proxy check: compare RMS/R ratio across all data.
    fprintf('\n--- RMS vs R Ratio Check --- \n')
    fprintf(['A flat/degenerate arc typically shows a LOW RMS relative to a ' ...
             'large R (points can lie close to many different large-radius circles))\n'])

    data.RMS_to_R_ratio = data.RMS ./ data.R;
    [~, idx] = sort(data.RMS_to_R_ratio);
    disp(data(idx(1:10), {'DatasetID','ParticipantIDGlobal','Leg','R','RMS','n_steps'}))

    % If row row_idx appears among the LOWEST ratios, that supports the degenerate-arc theory
    fprintf('Row %d RMS/R ratio: %.5f (rank %d of %d)\n', ...
        row_idx, data.RMS_to_R_ratio(row_idx), find(idx==row_idx), height(data));
    
    % Flag any observation where R is implausibly large relative to anatomical scale
    threshold = median(data.(response_name)) + 5*iqr(data.(response_name)); % or another defensible cutoff
    suspect_rows = data(data.(response_name) > threshold, :);
    fprintf('\n--- Observations with Implausibly Large %s --- \n', response_name)
    disp(suspect_rows(:, {'DatasetID','ParticipantIDGlobal','Leg','R','R_H','RMS','n_steps', 'ArcSpanDeg', 'ArcSpanRad'}))
    fprintf('%d observations exceed threshold R_H = %.3f (median(R_H) + 5*iqr(data.R_H))\n', height(suspect_rows), threshold);
    
    % ------------------------------------------------------------------
    % Direct Empirical Check: does small arc span predict implausible/unstable
    % R?
    % ------------------------------------------------------------------
    % Direct nonlinear fit of R vs arc span in radians, testing the geometric 
    % model: R ≈ L / (2*sin(theta/2)), solve for implied chord length L
    modelfun = @(b, theta) b(1) ./ (2*sin(theta/2));
    theta_rad = data.ArcSpanRad;
    b0 = 300; % initial guess for L (mm), rough anatomical chord length
    mdl_geom = fitnlm(theta_rad, data.R_H, modelfun, b0);
    disp(mdl_geom)
    % If this fits well (residuals small, L in a plausible anatomical range,
    % e.g., ~200-500 mm for a foot/shank-scale chord), it directly CONFIRMS
    % the mechanism: for small theta R ~ L / theta so R is inversely proportional
    % to the arc span => small arc spans give way to larger circles as the
    % circular fitting is less accurate.
    nexttile(tl)
    scatter(data.ArcSpanDeg, data.R_H, 15, 'filled');
    xlabel('Arc Span (rad)'); ylabel('R\_H');
    title('R\_H vs Arc Span — check for instability at low span');
    hold on;
    scatter(data.ArcSpanDeg(row_idx), data.R_H(row_idx), 100, 'r', 'filled');
    x_rad = linspace(min(data.ArcSpanRad), max(data.ArcSpanRad), 1000)';
    x_deg = rad2deg(x_rad);
    y_pred = predict(mdl_geom, x_rad);
    plot(x_deg, y_pred, 'k', LineWidth=1.5)
   
    % Quantify: correlation between span and |R_H deviation from Dataset median|
    dataset_medians = grpstats(data.R_H, data.DatasetID, 'median');
    [G,~] = findgroups(data.DatasetID);
    data.abs_dev = abs(data.R_H - dataset_medians(G));
    [rho_span, p_span] = corr(data.ArcSpanRad, data.abs_dev, 'Type','Spearman');
    fprintf('Spearman correlation: arc span vs |R_H deviation from dataset median|: rho=%.3f, p=%.4f\n', rho_span, p_span);

    % ------------------------------------------------------------------
    % Sensitivity Sweep for Arc Span Threshold
    % ------------------------------------------------------------------
    % Candidate thresholds informed by the visual elbow (~10-15°) in plot
    candidate_thresholds =  [3, 5, 8, 10, 12, 15, 20];  % degrees
    sensitivity_results = table();
    
    for th_deg = candidate_thresholds
        th_rad = deg2rad(th_deg);
        idx = data.ArcSpanDeg >= th_deg;
        data_filt = data(idx, :);
        weight_filt = weight(idx);
        excluded_filt = excluded(idx);

        n_filtered = height(data) - height(data_filt);


        lme_filt   = fitlme(data_filt, formula, ...
                            'FitMethod', fit_method, ...
                            'Weights', weight_filt, ...
                            'DummyVarCoding', 'effects', ...
                            'Exclude', excluded_filt);

        ICC_filt = model_metrics(lme_filt, Display="off");

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

        ICC_alt = model_metrics(lme_alt, Display="off");

        sensitivity_results = [sensitivity_results; ...
            table(th_deg, th_rad, n_filtered, ICC_filt(1), ICC_alt(1), adstat, p_ad, ...
            'VariableNames', {'ThresholdDeg', 'ThresholdRad', 'N_Filtered', 'ICC1', 'ICC1_alt', 'AD_Statistic', 'Pvalue'})];
    end

    disp(sensitivity_results)

    nexttile(tl)
    hold on
    plot(sensitivity_results.ThresholdDeg, sensitivity_results.ICC1, '-o');
    ylabel('ICC(1)');
    title('LMM - ICC vs Arc Span Threshold');

    % ------------------------------------------------------------------
    % Sanity check for better optimizer for 5 and 8 degrees
    % ------------------------------------------------------------------
    formula_noRE = model.Formula.FELinearFormula.char;
    for th_deg = [5, 8]
        idx = data.ArcSpanDeg >= th_deg;
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

        fprintf('\n--- Threshold %d degrees ---\n', th_deg);
        fprintf('Quasi-Newton: LogLik=%.6f, ICC=%.4f\n', lmm_qn.LogLikelihood, ICC_qn);
        fprintf('fminunc:      LogLik=%.6f, ICC=%.4f\n', lmm_fu.LogLikelihood, ICC_fu);
        fprintf('No random effect: LogLik=%.6f\n', lmm_noRE.LogLikelihood);
    end

    % If lmm_qn (or lmm_fu)'s LogLik is only trivially higher than lmm_noRE's
    % that supports tau^2=0 genuinely being close to the true optimum at this 
    % threshold. If one of them is MEANINGFULLY higher, that one is the correct 
    % answer and the other optimizer failed to find it.
end

function [pval, stat, df] = flignerKilleen(data, group)
    % FLIGNERKILLEEN  Fligner-Killeen test for homogeneity of variances
    %   data  : vector of observations
    %   group : vector/categorical of group labels (same length as data)

    data = data(:);
    group = group(:);
    groups = unique(group);
    k = numel(groups);
    N = numel(data);

    % Step 1: center each group by its median
    centered = zeros(N,1);
    for i = 1:k
        idx = group == groups(i);
        centered(idx) = abs(data(idx) - median(data(idx)));
    end

    % Step 2: rank the absolute centered values (overall ranks)
    ranks = tiedrank(centered);

    % Step 3: Fligner-Killeen scores = normal quantile transform of ranks
    a = norminv(0.5 + ranks/(2*(N+1)));

    % Step 4: compute test statistic
    abar = mean(a);
    v = var(a); % variance of the scores, used as normalizing constant

    stat = 0;
    for i = 1:k
        idx = group == groups(i);
        ni = sum(idx);
        Ai = sum(a(idx));
        stat = stat + ni * (Ai/ni - abar)^2;
    end
    stat = stat / v;

    df = k - 1;
    pval = 1 - chi2cdf(stat, df);

    fprintf('Fligner-Killeen: chi-sq = %.4f, df = %d, p = %.4g\n', stat, df, pval);
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

    normality_check(delta_Variable, "Delta " + var_name + " [-]", 'anderson')
    normality_check(delta_RMS, "Delta RMS [mm]", 'anderson')
end

function [beta_boot, tau2_boot, sigma2_boot, ICC_boot, warn_flag] = boot_resampler(data, model)
    % Initialize boot parameters
    n_fixed = height(model.Coefficients) + 1;
    beta_boot = nan(1, n_fixed); % fixed effects intercept point estimates (grand mean + dataset IDs)
    tau2_boot = nan; % participant-level random intercept variance
    sigma2_boot = nan; % residual variance
    ICC_boot = nan(1, 2); % ICC
    warn_flag = false; % flag indicating if a convergence warning was issued

    % Per-dataset sampling with replacements of participants
    datasets = unique(data.DatasetID);
    boot_data = table();
    for d = 1:numel(datasets)
        idx = data.DatasetID == datasets(d);
        this_dataset = data(idx, :);
        this_dataset.ParticipantIDOriginal = data.ParticipantID(idx);
        participants = unique(data.ParticipantID(idx));
        n_participants = numel(participants);
        sample_idx = randi(n_participants, n_participants, 1);
        sampled_participant_ids = participants(sample_idx);

        % Relabel participant IDS to avoid merging duplicates when fitting LME
        [row, col] = find(data.ParticipantID(idx) == sampled_participant_ids');
        this_boot = this_dataset(row, :);
        this_boot.ParticipantID = categorical(col);
        boot_data = [boot_data; this_boot]; %#ok<AGROW>
    end
    % [last_warning, warnID] = lastwarn();
    %
    % if ~isempty(warnID) && ...
    %         ~contains(last_warning, 'Posterior mode estimation of random effects did not converge.') && ...
    %         ~contains(last_warning, 'Line search for posterior mode estimation of random effects did not converge.')
    %
    %     disp(warnID + ": " + last_warning)
    %     warning('on','all');
    % end
    %
    % if contains(warnID, 'lmeutils', IgnoreCase=true) || ...
    %         contains(warnID, 'StandardGeneralizedLinearMixedModel', IgnoreCase=true) || ...
    %         contains(last_warning, 'did not converge', IgnoreCase=true)
    %     warn_flag = true;
    %     warning('on','all');
    %     continue  % discard this resample - convergence not trustworthy
    % end

    try
        lme_boot = fitlme(boot_data, char(model.Formula), ...
            'FitMethod', model.FitMethod, ...
            'Weights', boot_data.Weight, ...
            'DummyVarCoding', 'effects');

        % fixed effects
        beta_boot(1:(end-1)) = lme_boot.Coefficients.Estimate;
        beta_boot(end) = -sum(beta_boot(2:(end-1)));
        [ICC_boot, tau2_boot, sigma2_boot] = model_metrics(lme_boot, Display="off");

    catch ME
        % do nothing and return nans of parameters.
    end
end