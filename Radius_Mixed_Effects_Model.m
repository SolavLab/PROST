clearvars -except PROSTAnalyzer
close all
clc

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 
warning('off', 'backtrace')

% Set the default font name (e.g., Arial, Times New Roman, Courier)
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

model = "lmm";
boot_flag = false;

%% Create Table for Statistical Analysis
% Read from IPDTable
radius = table2array(PROSTAnalyzer.get_IPD_samples("Radius"));
horizontal = table2array(PROSTAnalyzer.get_IPD_samples("Center_horizontal"));
residual = table2array(PROSTAnalyzer.get_IPD_samples("Residual_rms"));

predictors = PROSTAnalyzer.get_predictors();
height = PROST.utils.convert_units(predictors.Height, "m", "mm");

% Create table for statistical analysis
data = predictors;

% Parameters to analyze
data.R = radius;
data.R_H = radius ./ height;
data.Cx = horizontal;
data.Cx_H = horizontal ./ height;

% Random and fixed Effects on Parameters
data.DatasetID = table2array(PROSTAnalyzer.get_IPD_samples("Dataset_id"));
data.ParticipantID = table2array(PROSTAnalyzer.get_IPD_samples("Participant_id"));
data.ParticipantIDGlobal = data.DatasetID.*1000 + data.ParticipantID;
data.Leg = categorical(table2array(PROSTAnalyzer.get_IPD_samples("Side")));
data.DatasetID = categorical(data.DatasetID);
data.ParticipantID = categorical(data.ParticipantID);
data.ParticipantIDGlobal = categorical(data.ParticipantIDGlobal);


% Weights from RMS
data.RMS = residual;
% Check RMS vs number of steps used per observation
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

figure;
scatter(data.n_steps, data.RMS, 20, 'filled');
xlabel('Number of steps in fit');
ylabel('RMS');
title('RMS vs Sample Size (check for negative relationship)');

[rho, p_corr] = corr(data.n_steps, data.RMS, 'Type', 'Spearman');
fprintf('Spearman correlation RMS vs n_steps: rho=%.3f, p=%.4f\n', rho, p_corr);

% Also check at the Dataset level, since this is where the confound is most severe
groupStats = grpstats(data(:,{'DatasetID','RMS','n_steps'}), 'DatasetID', {'mean','std'});
disp(groupStats);

% Weights should consider number of steps since more steps increases the RMS due
% to captured variability not model error
weight = data.n_steps;% ./ (data.RMS.^2);

% Standardize predictor units
data.Age_z          = (data.Age - mean(data.Age)) / std(data.Age);
data.Mass_z         = (data.Mass - mean(data.Mass)) / std(data.Mass);
data.Height_z       = (data.Height - mean(data.Height)) / std(data.Height);
data.Leg_length_z   = (data.Leg_length - mean(data.Leg_length)) / std(data.Leg_length);
data.Thigh_z        = (data.Thigh_length - mean(data.Thigh_length)) / std(data.Thigh_length);
data.Shank_z        = (data.Shank_length - mean(data.Shank_length)) / std(data.Shank_length);

clear radius horizontal residual height predictors
%% Linear Mixed Effects Model
switch model
    case "lmm"
    lme_response_name = 'R_H';
    lme_formula = [lme_response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
    
    % Fit the model using REML
    lme = fitlme(data, lme_formula, ...
                'FitMethod', 'REML', ...
                'Weights', weight, ...
                'DummyVarCoding', 'effects');
    
    % Extract variance components
    cov_estimates = covarianceParameters(lme);
    
    % By MATLAB convention, cov_estimates is a cell array containing covariance matrices.
    % For scalar random effects, these matrices contain a single element (the variance).
    var_participant = cov_estimates{1}(1,1);
    sigma2_residual    = lme.MSE; % Mean Squared Error represents the Level 1 Residual Variance
    
    % Display metrics formatted for publication
    ICC = display_model_metrics(var_participant, sigma2_residual, "LMM");
    
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

    fprintf('DatasetID_4: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
        beta4, se_beta4, tstat, pval, ci_lower, ci_upper);

    %% Test LMM Assumptions
    % ------------------------------------------------------------------
    % STEP 1: Formal Statistical Tests on Raw Vectors (Stratified/Pooled)
    % ------------------------------------------------------------------
    var_raw = data{:, lme_response_name}; % Load your empirical data vectors
    RMS_raw = data.RMS; % RMS residuals
    test_normality(RMS_raw, "Pooled RMS Radial Residual", 'anderson') % Test on pooled RMS data
    test_normality(var_raw, "Pooled " + lme_response_name, 'anderson') % Test continuous pooled response data
    
    % ------------------------------------------------------------------
    % STEP 2: Conditional Normality Assessment (LME Model Residuals)
    % ------------------------------------------------------------------
    model_residuals = residuals(lme);
    test_normality(model_residuals, "LMM Model Residual", 'anderson')
    
    % ------------------------------------------------------------------
    %  CHECK 3: Normality of Random Effects (BLUPs)
    %  ------------------------------------------------------------------
    [~, ~, reStats] = randomEffects(lme); % reStats: table with Level, Name, Estimate, Group
    isPart  = strcmp(reStats.Group, 'DatasetID:ParticipantID');
    random_effects  = reStats.Estimate(isPart);
    test_normality(random_effects, "LMM Random Effects", 'anderson')

    % ------------------------------------------------------------------
    %  CHECK 4: Homoscedasticity
    %  ------------------------------------------------------------------
    fitted_vals = fitted(lme);

    figure
    scatter(fitted_vals, model_residuals, 15, 'filled');
    yline(0, '--r');
    xlabel('Fitted values'); 
    ylabel('Pearson residuals');
    title('Residuals vs Fitted (check for funnel shape)');

    % Levene's test: residual variance equal across Footwear groups
    group = data.DatasetID;   % categorical grouping variable

    % Manual Levene's test (ANOVA on absolute deviations from group median)
    groups = unique(group);
    absDevFromMedian = zeros(size(model_residuals));
    for i = 1:numel(groups)
        idx = group == groups(i);
        absDevFromMedian(idx) = abs(model_residuals(idx) - median(model_residuals(idx)));
    end
    [p_levene, tbl_anova] = anova1(absDevFromMedian, group, 'off');
    fprintf('--- LMM Homoscedasticity Check ---\n');
    fprintf('Levene''s test (DatasetID) p = %.4f\n\n', p_levene);
    
    % ------------------------------------------------------------------
    %  CHECK 5: Random-effects structure: Likelihood Ratio Test
    %  ------------------------------------------------------------------
    % Compare model WITH participant random intercept vs WITHOUT
    lme_full   = fitlme(data, lme_formula, ...
                         'FitMethod','ML');  % must use ML, not REML, to compare
    lme_formula_reduced = [lme_response_name ' ~ 1 + DatasetID'];
    lme_reduced = fitlme(data, lme_formula_reduced, 'FitMethod', 'ML');
    
    results = compare(lme_reduced, lme_full, 'CheckNesting', true);
    disp(results);
    
    % ------------------------------------------------------------------
    %  CHECK 6: Variance Function (Var(Y) ~ mu^P)
    %  ------------------------------------------------------------------
    % Plot group means vs group variances directly
    groupMeans = splitapply(@mean, data{:, lme_response_name}, findgroups(data.DatasetID));
    groupVars  = splitapply(@var,  data{:, lme_response_name}, findgroups(data.DatasetID));
    figure 
    scatter(log(groupMeans), log(groupVars), 60, 'filled');
    h_l = lsline();
    h_l.Color = "red";
    h_l.LineWidth = 1.5;
    xlabel(['log(Group Mean) of ' replace(lme_response_name, "_", " / ")]); 
    ylabel(['log(Group Variance) of ' replace(lme_response_name, "_", " / ")]);
    title('Mean-Variance Relationship Across Datasets');
    grid on

    % Fit line to log-log to check power relationship (slope~2 => Gamma, slope~3 => IG)
    p = polyfit(log(groupMeans), log(groupVars), 1);
    fprintf('Estimated variance-mean power: %.2f (Gamma≈2, InvGaussian≈3, constant-variance≈0)\n', p(1));

    mu_hat    = predict(lme); % conditional mean predictions
    raw_resid = data{:, lme_response_name} - mu_hat; % raw residuals on response scale

    % Bin fitted values into groups, compute empirical variance per bin,
    % then regress log(variance) on log(mean) -> slope should be ~3 for Inverse
    % Gaussian
    n_bins = floor(sqrt(numel(mu_hat)));
    edges = quantile(mu_hat, linspace(0, 1, n_bins+1));
    bin_idx = discretize(mu_hat, edges);
    
    log_mean_bin = nan(n_bins, 1);
    log_var_bin  = nan(n_bins, 1);
    for b = 1:n_bins
        sel = bin_idx == b;
        if sum(sel) > 3
            log_mean_bin(b) = log(mean(mu_hat(sel)));
            log_var_bin(b)  = log(var(raw_resid(sel)));
        end
    end
    valid = ~isnan(log_mean_bin) & ~isnan(log_var_bin);
    p = polyfit(log_mean_bin(valid), log_var_bin(valid), 1);
    fprintf('--- LMM Variance Function Check ---\n');
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f\n\n', p(1));
    
    figure
    scatter(log_mean_bin(valid), log_var_bin(valid), 60, 'filled')
    hold on
    xfit = linspace(min(log_mean_bin(valid)), max(log_mean_bin(valid)), 50);
    plot(xfit, polyval(p, xfit), 'r-', 'LineWidth', 1.5)
    xlabel('log(Mean of \mu_{hat} per bin)')
    ylabel('log(Variance of residuals per bin)')
    txt = sprintf('LMM Variance Function Check (slope = %.2f)', p(1));
    title(txt)
    grid on

    %% General Linear Mixed Effects Model
    case "glmm"
    % We use an Inverse Gaussian distribution with a Log link function.
    % Observations are weighted by 1/RMS^2 to account for circular fit precision.
    expected_slope = dictionary(["Gamma", "InverseGaussian", "Poisson", "Normal"], [2 3 1 0]);
    glme_response_name = 'R_H';
    glme_distribution = 'InverseGaussian';
    glme_link = 'log';
    glme_fit_method = 'Laplace';
    glme_formula = [glme_response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
    
    % Fit the Generalized Linear Mixed-Effects Model (GLMM)
    glme = fitglme(data, glme_formula, ...
                    'Distribution', glme_distribution, ...
                    'Link', glme_link, ...
                    'FitMethod', glme_fit_method, ...
                    'Weights', weight);
    
    % Extract variance components
    [cov_estimates, ~, stats] = covarianceParameters(glme);
    
    % By MATLAB convention, cov_estimates is a cell array containing covariance matrices.
    % For scalar random effects, these matrices contain a single element (the variance).
    var_participant = cov_estimates{1}(1, 1);
    phi = glme.Dispersion;                 % from fitglme output
    var_resid = psi(1, 1/phi);       % trigamma-based latent-scale residual variance
    
    % Display metrics formatted for publication
    ICC = display_model_metrics(var_participant, var_resid, "GLMM");

    %% GLMM Assumption Diagnostics
    %% ------------------------------------------------------------------
    %  CHECK 1: Variance Function (Var(Y) ~ mu^P)
    %  ------------------------------------------------------------------
    mu_hat    = predict(glme); % conditional mean predictions
    raw_resid = data{:, glme_response_name} - mu_hat; % raw residuals on response scale

    % Bin fitted values into groups, compute empirical variance per bin,
    % then regress log(variance) on log(mean) -> slope should be ~3 for Inverse
    % Gaussian
    n_bins = 20;
    edges = quantile(mu_hat, linspace(0, 1, n_bins+1));
    bin_idx = discretize(mu_hat, edges);
    
    log_mean_bin = nan(n_bins, 1);
    log_var_bin  = nan(n_bins, 1);
    for b = 1:n_bins
        sel = bin_idx == b;
        if sum(sel) > 3
            log_mean_bin(b) = log(mean(mu_hat(sel)));
            log_var_bin(b)  = log(var(raw_resid(sel)));
        end
    end
    valid = ~isnan(log_mean_bin) & ~isnan(log_var_bin);
    p = polyfit(log_mean_bin(valid), log_var_bin(valid), 1);
    fprintf('--- GLMM Variance Function Check ---\n');
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f (%s expects ~ %d)\n\n', ...
        p(1), glme_distribution, expected_slope(glme_distribution));
    
    figure
    scatter(log_mean_bin(valid), log_var_bin(valid), 60, 'filled')
    hold on
    xfit = linspace(min(log_mean_bin(valid)), max(log_mean_bin(valid)), 50);
    plot(xfit, polyval(p, xfit), 'r-', 'LineWidth', 1.5)
    xlabel('log(Mean of \mu_{hat} per bin)')
    ylabel('log(Variance of residuals per bin)')
    txt = sprintf('GLMM Variance Function Check (slope = %.2f, %s expects ~ %d)', ...
                   p(1), glme_distribution, expected_slope(glme_distribution));
    title(txt)
    grid on
    
    %% ------------------------------------------------------------------
    %  CHECK 2: Normality of Random Effects
    %  ------------------------------------------------------------------
    [~, ~, reStats] = randomEffects(glme); % reStats: table with Level, Name, Estimate, Group
    isPart  = strcmp(reStats.Group, 'DatasetID:ParticipantID');
    random_effects  = reStats.Estimate(isPart);
    
    test_normality(random_effects, "GLMM Participant Random Effects", 'anderson')
    
    figure; 
    qqplot(random_effects);
    [skew_re, kurt_re] = deal(skewness(random_effects), kurtosis(random_effects));
    fprintf('Skewness: %.3f, Kurtosis: %.3f\n\n', skew_re, kurt_re);
    
    %% ------------------------------------------------------------------
    %  CHECK 3: Dispersion Adequacy (Pearson chi^2 / df)
    %  ------------------------------------------------------------------
    phi = glme.Dispersion;
    mu_hat = predict(glme);
    y = data{:, glme_response_name};
    V_mu = mu_hat.^expected_slope(glme_distribution);

    pearson_resid = (y - mu_hat) ./ sqrt(V_mu);
    pearson_chi2  = sum(pearson_resid.^2);

    df_resid      = glme.DFE; % residual degrees of freedom
    dispersion_ratio = pearson_chi2 / df_resid;
    
    fprintf('--- GLMM Dispersion Adequacy Check ---\n');
    fprintf('Pearson chi^2:           %.3f\n', pearson_chi2);
    fprintf('df_resid:                %d\n', df_resid);
    fprintf('Pearson chi^2 / df:      %.3f  (should be approx. 1.0)\n', dispersion_ratio);
    fprintf('Model fitted dispersion: %.3f  (should agree with ratio if family is correct)\n', phi);
    fprintf('Ratio / phi:             %.3f  (should be approx. 1.0 if phi is well-estimated)\n\n', dispersion_ratio/phi);

    %% ------------------------------------------------------------------
    %  CHECK 4: Randomized Quantile Residuals (Dunn & Smyth, 1996)
    %  Valid replacement for response-scale normality testing
    %  ------------------------------------------------------------------
    phi   = glme.Dispersion;
    shape = 1/phi;
    scale = phi .* mu_hat;
    
    u = gamcdf(data{:, glme_response_name}, shape, scale);   % probability integral transform
    u = min(max(u, eps), 1-eps);                          % guard against 0/1 boundary issues
    quantile_resid = norminv(u);                          % should be ~ N(0,1) if model correctly specified
    
    test_normality(quantile_resid, "GLMM Quantile Resdial", 'anderson')
end
%% ----------------------------------------------------------------------------- 
% Helper Functions
% ------------------------------------------------------------------------------
function test_normality(data, data_name, test_type)
    switch test_type
    case "chi2gof"
        % Chi-squared Goodness-of-Fit test
        [h, p, stat] = chi2gof(data);
        fprintf('--- Chi-Squared Normality Test on %s ---\n', data_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (Chi^2): %.5f\n', stat.chi2stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "lilliefors"
        % Lilliefors test
        [h, p, stat] = lillietest(data);
        fprintf('--- Lilliefors Normality Test on %s ---\n', data_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "anderson"
        % Anderson-Darling test
        [h, p, stat] = adtest(data);
        fprintf('--- Anderson-Darling Normality Test on %s ---\n', data_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (A^2):   %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "kolmogorov" 
        % standardized KS vs N(0,1)
        [h, p, stat] = kstest((data - mean(data)) / std(data));
        fprintf('--- Standardized Kolmogorov-Smirnov Normality Test on %s ---\n', data_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    end

    figure
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact')
    nexttile;
    qqplot(data)
    title("QQ-plot: " + data_name)
    grid on

    nexttile;
    histogram(data, 'Normalization','pdf')
    hold on
    xx = linspace(min(data), max(data), 100);
    mu = mean(data);
    sigma = std(data);
    plot(xx, normpdf(xx, mu, sigma), 'r-', 'LineWidth', 1.5)
    xline(mu, 'b-', LineWidth=1.5)
    xline(mu + sigma, 'b--', LineWidth=1.5)
    xline(mu - sigma, 'b--', LineWidth=1.5)
    title(data_name + " vs Normal Distribution")
    xlabel(data_name);
    grid on
end

function ICC = display_model_metrics(participant_variance, residual_variance, model_name)
    total_variance = participant_variance + residual_variance;
    ICC = participant_variance / total_variance;

    % Display metrics formatted for publication
    fprintf('\n--- %s - Hierarchical Variance Decomposition Metrics ---\n', model_name);
    fprintf('Participant-Level Variance:     %8.3f (%5.2f%%)\n', participant_variance, (participant_variance/total_variance)*100);
    fprintf('Residual-Level Variance:        %8.3f (%5.2f%%)\n', residual_variance, (residual_variance/total_variance)*100);
    fprintf('---------------------------------------------------\n');
    fprintf('Total Unexplained Variance:                    %8.3f\n', total_variance);
    fprintf('Participant Intraclass Correlation (ICC):      %8.4f\n\n', ICC);
end

%% Cluster (Participant-Level), Stratified-by-Dataset Bootstrap for ICC CI
if boot_flag
    n_boot = 2000;
    ICC_boot   = nan(n_boot, 1);
    sigma2_part_boot = nan(n_boot, 1);
    sigma2_resid_boot = nan(n_boot, 1);
    n_failed_error = 0;
    n_failed_warning = 0;
    
    datasets = unique(data.DatasetID);
    glme_response_name = 'R_H';
    boot_formula = [glme_response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];  % unconditional model
    
    for b = 1:n_boot
        boot_rows = [];
        for d = 1:numel(datasets)
            this_dataset = data(data.DatasetID == datasets(d), :);
            partisipant_IDs = unique(this_dataset.ParticipantID);
            n_participants = numel(partisipant_IDs);
            sampled_IDs = partisipant_IDs(randi(n_participants, n_participants, 1));  % resample participants WITH replacement
            [r, ~] = find(this_dataset.ParticipantID == sampled_IDs');
            boot_rows = [boot_rows; this_dataset(r, :)];
        end
        
        lastwarn('');  % clear warning state before each fit
        warning('off', 'all');  % suppress console spam; we'll check programmatically instead
        
        try
            % Weights from RMS
            boot_weight = 1 ./ (boot_rows.RMS.^2);
            boot_weight(~isfinite(weight)) = max(boot_weight(isfinite(boot_weight)));
            glme_boot = fitglme(boot_rows, boot_formula, ...
                                'Distribution', 'InverseGaussian', ...
                                'Link', 'log', ...
                                'FitMethod', 'Laplace', ...
                                'Weights', boot_weight);
            
            [last_warning, warnID] = lastwarn();
            if ~isempty(warnID) && ...
               ~contains(last_warning, 'Posterior mode estimation of random effects did not converge.') && ...
               ~contains(last_warning, 'Line search for posterior mode estimation of random effects did not converge.')
    
                disp(warnID + ": " + last_warning)
                warning('on','all');
            end
            if contains(warnID, 'lmeutils', IgnoreCase=true) || ...
               contains(warnID, 'StandardGeneralizedLinearMixedModel', IgnoreCase=true) || ...
               contains(last_warning, 'did not converge', IgnoreCase=true)
                n_failed_warning = n_failed_warning + 1;
                warning('on','all');
                continue  % discard this resample - convergence not trustworthy
            end
            
            [cov_estimates, ~, stats] = covarianceParameters(glme_boot);  % adjust extraction to match your existing helper
            sigma2_part  = cov_estimates{1}(1, 1); % participant variance component 
            phi = glme_boot.Dispersion;  % trigamma-corrected latent residual variance
            var_resid = psi(1, 1/phi);       % trigamma-based latent-scale residual variance
    
            sigma2_part_boot(b)  = sigma2_part;
            sigma2_resid_boot(b) = var_resid;
            ICC_boot(b) = sigma2_part / (sigma2_part + var_resid);
        catch
            n_failed_error = n_failed_error + 1;
            % leave as NaN, continue
        end
    end
    %%
    ICC_boot = ICC_boot(~isnan(ICC_boot));
    fprintf('Hard errors: %d / %d (%.1f%%)\n', n_failed_error, n_boot, 100*n_failed_error/n_boot);
    fprintf('Convergence warnings (discarded): %d / %d (%.1f%%)\n', n_failed_warning, n_boot, 100*n_failed_warning/n_boot);
    fprintf('Usable resamples: %d / %d (%.1f%%)\n', numel(ICC_boot), n_boot, 100*numel(ICC_boot)/n_boot);
    
    
    %% Percentile method
    ICC_CI_percentile = quantile(ICC_boot, [0.025, 0.975]);
    fprintf('ICC point estimate: %.4f\n', ICC); % from your original full-sample fit
    fprintf('Bootstrap 95%% CI (percentile): [%.4f, %.4f]\n', ICC_CI_percentile(1), ICC_CI_percentile(2));
    
    figure; 
    histogram(ICC_boot, 40); 
    xlabel('Bootstrapped ICC'); 
    ylabel('Frequency');
    title('Bootstrap Distribution of ICC'); 
    test_normality(ICC_boot, "Bootstrap ICC", 'anderson')
    
    mean_boot = mean(ICC_boot);
    median_boot = median(ICC_boot);
    fprintf('Bootstrap mean: %.4f, median: %.4f, original point estimate: %.4f\n', ...
            mean_boot, median_boot, 0.4350);
    
    %% BCa Correction to Bootstrapped ICC CI
    % Proportion of bootstrap ICCs less than the original point estimate
    ICC_hat = ICC;  % your original full-sample point estimate
    p0 = mean(ICC_boot < ICC_hat);
    z0 = norminv(p0);  % bias-correction factor
    fprintf('z0 = %.4f (proportion below point estimate: %.4f)\n', z0, p0);
    
    participantIDs_all = unique(data.ParticipantID);
    nP = numel(participantIDs_all);
    ICC_jack = nan(nP, 1);
    
    for i = 1:nP
        jackData = data(data.ParticipantID ~= participantIDs_all(i), :);
        try
            glme_j = fitglme(jackData, formula, 'Distribution','InverseGaussian', ...
                              'Link','log', 'FitMethod','Laplace', ...
                              'Weights', 1./(jackData.RMS.^2));
            [psi, ~, ~] = covarianceParameters(glme_j);
            s2_part_j  = psi{1}(1);
            s2_resid_j = glme_j.Dispersion;
            ICC_jack(i) = s2_part_j / (s2_part_j + s2_resid_j);
        catch
            ICC_jack(i) = NaN;
        end
    end
    
    ICC_jack = ICC_jack(~isnan(ICC_jack));
    ICC_jack_mean = mean(ICC_jack);
    
    num = sum((ICC_jack_mean - ICC_jack).^3);
    den = 6 * (sum((ICC_jack_mean - ICC_jack).^2))^1.5;
    a_hat = num / den;
    fprintf('Acceleration (a_hat) = %.5f\n', a_hat);
end

%% Robust descriptive summary, by participant (use participant-level means first 
% to avoid double-weighting participants with bilateral measurements)
participantMeans = groupsummary(data, 'ParticipantIDGlobal', 'mean', 'R_H');

med_RH  = median(participantMeans.mean_R_H);
iqr_RH  = iqr(participantMeans.mean_R_H);
mean_RH = mean(participantMeans.mean_R_H);
sd_RH   = std(participantMeans.mean_R_H);

fprintf('Participant-level R_H: median = %.4f, IQR = %.4f\n', med_RH, iqr_RH);
fprintf('Participant-level R_H: mean = %.4f, SD = %.4f (sensitive to skew, report for completeness)\n', mean_RH, sd_RH);