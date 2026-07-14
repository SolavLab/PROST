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

model = "lmm";
boot_flag = false;

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
% Exclude unstable data
% data(data.ArcSpanDeg < 5, :) = [];

clear radius horizontal residual height predictors

%% Linear Mixed Effects Model
switch model
    case "lmm"
    lmm_response_name = 'R_H';
    %% Test Weight Scheme
    test_weight_scheme(data, lmm_response_name)
    
    %% Weighted LMM Model
    formula = [lmm_response_name ' ~ 1 + DatasetID + (1|DatasetID:ParticipantID)'];
    weight_scheme = sqrt(data.n_steps);

    % Fit the model using REML
    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lmm_weighted = fitlme(data, formula, ...
                'FitMethod', 'REML', ...
                'Weights', weight_scheme, ...
                'DummyVarCoding', 'effects', ...
                'Optimizer', 'fminunc', ...
                'OptimizerOptions', opts);
    
    %% Test Cutoff of Unstable R
    test_cutoff_unstable_R(data, lmm_weighted)

    %% Final Weighted and Cutoff LMM
    data_final = data(data.R_H <= 1, :);
    weight_final = weight_scheme(data.R_H <= 1);

    fprintf('Excluded %d of %d observations (%.1f%%) with R_H > 1\n', ...
            height(data)-height(data_final), height(data), ...
            100*(height(data) - height(data_final)) / height(data));


    % Fit the model using:
    % Formula: R_H ~ 1 + DatasetID + (1|DatasetID:ParticipantID)
    % Weight: sqrt(n_steps)
    % Fit Method: REML
    % Dummy Var Coding: Effects
    % Optimizer: QuasiNewton (default)
    % Dataset cutoff at R_H > 1
    lmm_final = fitlme(data_final, formula, ...
                       'FitMethod', 'REML', ...
                       'Weights', weight_final, ...
                       'DummyVarCoding', 'effects');
    lmm_final_alt = fitlme(data_final, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_final, ...
                           'DummyVarCoding', 'effects', ...
                           'Optimizer', 'fminunc');

    if lmm_final.LogLikelihood < lmm_final_alt.LogLikelihood
        lmm_final = lmm_final_alt;
        fprintf('Switched to FMinUnc!')
    end

    disp(lmm_final)

    % Extract estimates and covariance for the three estimated DatasetID coefficients
    % coefNames = lmm_final.Coefficients.Name;
    % idx = contains(coefNames, 'DatasetID');
    % 
    % b = lmm_final.Coefficients.Estimate(idx);       % [b1; b2; b3]
    % V = lmm_final.CoefficientCovariance(idx, idx);  % 3x3 covariance submatrix
    % 
    % % Contrast vector: beta4 = -(b1+b2+b3) = c' * b, where c = [-1;-1;-1]
    % c = [-1; -1; -1];
    % 
    % beta4 = c' * b;
    % se_beta4 = sqrt(c' * V * c);
    % 
    % df = lmm_final.Coefficients.DF(find(idx,1));  % use same residual DF as other fixed effects
    % tstat = beta4 / se_beta4;
    % pval = 2 * (1 - tcdf(abs(tstat), df));
    % ci_lower = beta4 - tinv(0.975, df) * se_beta4;
    % ci_upper = beta4 + tinv(0.975, df) * se_beta4;
    % 
    % fprintf('\n--- Fixed Effects Values ---\n');
    % for idx=1:3
    %     fprintf('DatasetID_%d: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
    %     idx, ...
    %     lmm_final.Coefficients.Estimate(idx), ...
    %     lmm_final.Coefficients.SE(idx), ...
    %     lmm_final.Coefficients.tStat(idx), ...
    %     lmm_final.Coefficients.pValue(idx), ...
    %     lmm_final.Coefficients.Lower(idx), ...
    %     lmm_final.Coefficients.Upper(idx));
    % end
    % fprintf('DatasetID_4: Estimate=%.5f, SE=%.5f, t=%.3f, p=%.4g, CI=[%.5f, %.5f]\n', ...
    %     beta4, se_beta4, tstat, pval, ci_lower, ci_upper);

    % Display metrics formatted for publication
    ICC = model_metrics(lmm_final, "Final LMM");

    %% Test Linear Mixed-Effects Model Assumptions
    test_lmm_assumptions(data_final, lmm_final, lmm_response_name)

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
    tau2_participant = cov_estimates{1}(1, 1);
    phi = glme.Dispersion;                 % from fitglme output
    var_resid = psi(1, 1/phi);       % trigamma-based latent-scale residual variance
    
    % Display metrics formatted for publication
    ICC = model_metrics(tau2_participant, var_resid, "GLMM");

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

%% ----------------------------------------------------------------------------- 
% Helper Functions
% ------------------------------------------------------------------------------
function test_normality(var, name, test_type)
% TEST_NORMALITY(VAR, NAME, TEST_TYPE)
% Normality test for variable. Prints the result to command window.
%
% Input :
%   var - the variable to test
%   name - the name of the variable to test for printing
%   test_type - the type of test to perform. One of the following:
%               - Anderson-Darling (default)
%               - Chi2 goodness-of-fit
%               - Kolmogorov-Smirnov (standardized)
%               - Lilliefors
%
% Example usage:
%   test_normality(var, "variable", "chi2gof")
%   test_normality(var, "variable")


arguments
    var {mustBeNumeric}
    name (1, 1) string
    test_type (1, 1) string {mustBeMember(test_type, ["anderson" "chi2gof" "kolmogorov" "lilliefors"])} = "anderson"
end
    switch test_type
    case "chi2gof"
        % Chi-squared Goodness-of-Fit test
        [h, p, stat] = chi2gof(var);
        fprintf('--- Chi-Squared Normality Test on %s ---\n', name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (Chi^2): %.5f\n', stat.chi2stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "lilliefors"
        % Lilliefors test
        [h, p, stat] = lillietest(var);
        fprintf('--- Lilliefors Normality Test on %s ---\n', name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "anderson"
        % Anderson-Darling test
        [h, p, stat] = adtest(var);
        fprintf('--- Anderson-Darling Normality Test on %s ---\n', name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (A^2):   %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    case "kolmogorov" 
        % standardized KS vs N(0,1)
        [h, p, stat] = kstest((var - mean(var)) / std(var));
        fprintf('--- Standardized Kolmogorov-Smirnov Normality Test on %s ---\n', name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.5f\n', stat);
        fprintf('p-value:                %.5f\n\n', p);
    end

    figure
    tl = tiledlayout('TileSpacing', 'compact', 'Padding', 'compact');
    nexttile(tl)
    qqplot(var)
    title("QQ-plot: " + name)
    grid on

    nexttile(tl)
    histogram(var, 'Normalization','pdf')
    hold on
    xx = linspace(min(var), max(var), 100);
    mu = mean(var);
    sigma = std(var);
    plot(xx, normpdf(xx, mu, sigma), 'r-', 'LineWidth', 1.5)
    xline(mu, 'b-', LineWidth=1.5)
    xline(mu + sigma, 'b--', LineWidth=1.5)
    xline(mu - sigma, 'b--', LineWidth=1.5)
    title(name + " vs Normal Distribution")
    xlabel(name);
    grid on
end

function [ICC, random_effects_var, residual_var] = model_metrics(model, name)
% [ICC, RANDOM_EFFECTS_VAR, RESIDUAL_VAR] = MODEL_METRICS(MODEL, NAME)
% Computes metrics of variance components from the Mixed-Effects Model and
% displays them in the command window.
%
% Input :
%   model - the mixed effects model
%   name - the name of the model for printing
%
% Output :
%   ICC - Interclass correlation. The ratio between the random effect component
%         variance and total variance.
%   random_effects_var - variance of the random effects component
%   residual_var - variance of the residual component
%
% Example usage :
%   model_metrics(lme, "LMM Final");
%   ICC = model_metrics(lme, "LMM Final");
%   [ICC, random_effects_var, residual_var] = model_metrics(lme, "LMM Final")

    [psi, mse] = covarianceParameters(model);
    random_effects_var = psi{1}(1, 1);
    residual_var = mse;
    total_variance = random_effects_var + residual_var;
    ICC = random_effects_var / total_variance;

    % Display metrics formatted for publication
    fprintf('\n--- %s - Hierarchical Variance Decomposition Metrics ---\n', name);
    fprintf('Participant-Level Variance:     %8.3f (%5.2f%%)\n', random_effects_var, (random_effects_var/total_variance)*100);
    fprintf('Residual-Level Variance:        %8.3f (%5.2f%%)\n', residual_var, (residual_var/total_variance)*100);
    fprintf('---------------------------------------------------\n');
    fprintf('Total Unexplained Variance:                    %8.3f\n', total_variance);
    fprintf('Participant Intraclass Correlation (ICC):      %8.4f\n\n', ICC);
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


    figure(Name="Weight Schemes")
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
    fprintf('--- Correlation: RMS vs n_steps ---\n')
    fprintf('Spearman correlation RMS vs n_steps: rho=%.3f, p=%.4f\n', rho, p_corr);
    fprintf(['Correlation > 0 means RMS grows with n_steps since more steps means ' ...
             'capturing more data variability durring circular arc fit.\n\n'])
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

    fprintf('--- Log-Log Correlation: log(RMS) vs log(n_steps) ---\n')
    p = polyfit(log(data.n_steps), log(data.RMS), 1);
    fprintf('Estimated power-law exponent: %.3f\n\n', p(1));
    % fprintf('If RMS ~ n^(0.5), exponent should be near 0.5 (supports 1/n variance, i.e. w=n)\n')
    % fprintf('If RMS ~ n^(0.25) or similar shallow slope, precision gain is sub-linear/saturating (supports log(n) or sqrt(n) weighting instead)\n\n')
    
    % Alternative: bin n_steps into groups and directly compare within-bin variance of R_H
    % (only meaningful if multiple observations share similar n_steps — check group sizes)
    edges = [0 2 5 10 20 50 150];
    data.n_steps_bin = discretize(data.n_steps, edges);
    binStats = grpstats(data(:, {'n_steps_bin', response_name}), ...
                        'n_steps_bin', {'var', 'mean', 'numel'});
    fprintf('--- Comparison of Within-Bin Variance of %s vs N_Steps ---\n', response_name)
    disp(binStats)

    % Plot bin-level variance of R_H against bin midpoint n_steps on log-log scale
    % to see empirically how variance actually declines with n_steps
    fprintf('--- Bin-Level Log-Log Correlation: log(Var(%s)) vs log(n_steps) ---\n', response_name)
    binMidpoints = (edges(1:end-1) + edges(2:end)) ./ 2;
    logVar = log(binStats.(['var_', response_name]));
    logN   = log(binMidpoints)';
    
    p = polyfit(logN, logVar, 1);
    fprintf('Estimated power-law exponent for Var(%s) vs n_steps: %.3f\n', response_name, p(1));
    fprintf('If exponent ≈ -1: classical 1/n variance decay -> weight = n_steps is correct\n')
    fprintf('If exponent ≈ -0.5: weight = sqrt(n_steps) more appropriate\n')
    fprintf(['If exponent ≈ 0 or positive: NO meaningful precision gain from more steps at ' ...
             'the %s level -> weighting by n_steps may not be justified at all\n\n'], response_name)
    
    % Get DatasetID-adjusted residuals (removes between-dataset mean shifts)
    % Use a simple fixed-effects-only model, or just de-mean within DatasetID
    fprintf('\n--- Dataset Adjusted Variation: log(Var(%s)) vs log(n_steps) ---\n', response_name)
    datasetMeans = grpstats(data.(response_name), data.DatasetID, 'mean');
    [G, ~] = findgroups(data.DatasetID);
    data.([response_name, '_centered']) = data.(response_name) - datasetMeans(G);
    
    % NOW bin by n_steps and examine variance of the CENTERED residual
    edges2 = [0 2 5 10 20 50 150];
    data.n_steps_bin = discretize(data.n_steps, edges2);
    binStats2 = grpstats(data(:,{'n_steps_bin', [response_name, '_centered']}), ...
                        'n_steps_bin', {'var', 'mean', 'numel'});
    disp(binStats2)
    
    % Refit power law on the dataset-adjusted variance
    binMidpoints = (edges2(1:end-1) + edges2(2:end)) ./ 2;
    validBins = binStats2.(['numel_', response_name, '_centered']) >= 15; % drop bins too sparse to trust
    logVar2 = log(binStats2.(['var_', response_name, '_centered'])(validBins));
    logN2   = log(binMidpoints(validBins))';
    
    p_adjusted = polyfit(logN2, logVar2, 1);
    fprintf('Dataset-adjusted power-law exponent: %.3f\n', p_adjusted(1));
        
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
    model_metrics(lmm_no_weight, "LMM - No Weight");

    % --------------------------------------------------------------------------
    % N_steps weighted LMM
    % --------------------------------------------------------------------------
    weight_raw = data.n_steps;
    lmm_weighted = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_raw, ... 
                           'DummyVarCoding', 'effects');
    model_metrics(lmm_weighted, "LMM - N_steps Weight");

    % --------------------------------------------------------------------------
    % Check: does capping extreme weights change the zero-variance result?
    % --------------------------------------------------------------------------
    % Original weight
    fprintf('Weight range: min=%.1f, max=%.1f, ratio=%.1f\n\n', ...
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
        [psi, mse] = covarianceParameters(lmm_capped);
        tau2 = psi{1}(1,1);
        ICC_capped = tau2 / (tau2 + mse);

        % LRT for this capped-weight model too      
        lmm_capped_ML = fitlme(data, formula, ...
                               'FitMethod','ML', ...
                               'Weights', weight_capped, ...
                               'DummyVarCoding','effects');
        lmm_noRE_capped_ML = fitlme(data, formula_noRE, ...
                                    'FitMethod','ML', ...
                                    'Weights', weight_capped, ...
                                    'DummyVarCoding','effects');
        lrt_result = compare(lmm_noRE_capped_ML, lmm_capped_ML, 'CheckNesting', true);
        fprintf('--- Likelehood Ratio Test For %dth Percentile Capped Weights (Cap value %.2f) With/Without Random Effects --- \n', pc, cap_val)
        disp(lrt_result)
    
        results_table = [results_table; table(pc, cap_val, tau2, mse, ICC_capped, ...
            'VariableNames', {'Percentile', 'CapValue', 'Tau2_Participant', 'Sigma2_Residual', 'ICC'})];
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
        [psi, mse] = covarianceParameters(lmm_fine);
        tau2 = psi{1}(1,1);
        ICC_fine = tau2 / (tau2 + mse);

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
        [psi_alt, mse_alt] = covarianceParameters(lmm_alt);
        tau2_alt = psi_alt{1}(1,1);
        ICC_altopt = tau2_alt / (tau2_alt + mse_alt);

        fine_results = [fine_results; table(pc, cap_val, tau2, mse, ICC_fine, tau2_alt, mse_alt, ICC_altopt, ...
            'VariableNames', {'Percentile', 'CapValue', 'Tau2', 'Sigma2', 'ICC', 'Tau2Alt', 'Sigma2Alt', 'ICCAlt'})];
    end
    fprintf('\n--- Summary across fine capping thresholds ---\n');
    disp(fine_results)
    
    nexttile(tl)
    plot(fine_results.Percentile, fine_results.ICC, '-o');
    hold on
    plot(fine_results.Percentile, fine_results.ICCAlt, '-o');
    xlabel('Capping Percentile'); 
    ylabel('ICC');
    legend('Quasinewton (Defalt)', 'FMinUnc')
    title('LMM - ICC vs Cap Threshold (fine grid)');
    
    % --------------------------------------------------------------------------
    % Check: uncapped weight but on a log scale (alternative to hard capping)
    % --------------------------------------------------------------------------
    % Log-transforming compresses the extreme ratio (140x -> ~5x) while
    % preserving rank order of precision, a common alternative to hard capping
    % +1 to avoid log(0) issues if any n_steps=0 and also log(1)=0 for n_steps=1
    weight_log = log(data.n_steps + 1);

    lme_logweight = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_log, ...
                           'DummyVarCoding', 'effects');
    model_metrics(lme_logweight, "LMM - Log-Scaled Weight");

    % Also compare to an alternate optimizer
    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lme_logweight_fminunc = fitlme(data, formula, ...
                           'FitMethod', 'REML', ...
                           'Weights', weight_log, ...
                           'DummyVarCoding', 'effects', ...
                           'Optimizer', 'fminunc', ...
                           'OptimizerOptions', opts);
    model_metrics(lme_logweight_fminunc, "LMM - Log-Scaled Weight with FMinUnc Optimizer");
    
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
    model_metrics(lmm_dataset4, "LMM - Just Dataset 4 with No Weights");

    lmm_dataset4_weighted = fitlme(data_dataset4, formula_noFE, ...
                                   'FitMethod', 'REML', ...
                                   'Weights', weight_dataset4, ...
                                   'DummyVarCoding', 'effects');
    model_metrics(lmm_dataset4_weighted, "LMM - Just Dataset 4 with N_steps Weight");

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
    model_metrics(lmm_sqrt, "LMM - Sqrt-scaled Weight");

    opts = optimoptions('fminunc');
    opts.Display = 'off';
    lmm_sqrt_fminunc = fitlme(data, formula, ...
                      'FitMethod', 'REML', ...
                      'Weights', weight_sqrt, ...
                      'DummyVarCoding', 'effects', ...
                      'Optimizer', 'fminunc', ...
                      'OptimizerOptions', opts);
    model_metrics(lmm_sqrt_fminunc, "LMM - Sqrt-scaled Weight with FMinUnc Optimizer");
end

function test_lmm_assumptions(data, model, response_name)
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

    figure(Name="LMM Assumptions")
    tl = tiledlayout('TileSpacing', 'compact', 'Padding', 'compact');
    
    % ------------------------------------------------------------------
    % Formal Statistical Tests on Raw Vectors (Stratified/Pooled)
    % ------------------------------------------------------------------
    var_raw = data{:, response_name}; % Load your empirical data vectors
    RMS_raw = data.RMS; % RMS residuals
    test_normality(RMS_raw, "Pooled RMS Radial Residual", 'anderson') % Test on pooled RMS data
    test_normality(log(var_raw), "Pooled log(" + replace(response_name, '_', ' \_ ') + ")", 'anderson') % Test continuous pooled response data
    
    % ------------------------------------------------------------------
    % Conditional Normality Assessment (LME Model Residuals)
    % ------------------------------------------------------------------
    model_residuals = residuals(model, 'ResidualType', 'Pearson');
    test_normality(model_residuals, "Final LMM Model Residual", 'anderson')
    
    % ------------------------------------------------------------------
    % Normality of Random Effects (BLUPs)
    % ------------------------------------------------------------------
    random_effects = randomEffects(model);
    test_normality(random_effects, "Final LMM Random Effects", 'anderson')

    % ------------------------------------------------------------------
    % Homoscedasticity
    % ------------------------------------------------------------------
    fitted_values = fitted(model);

    nexttile(tl)
    scatter(fitted_values, model_residuals, 20, 'filled');
    yline(0, '--r');
    xlabel('Fitted values'); 
    ylabel('Pearson residuals');
    title('Final LMM Residuals vs Fitted (check for funnel shape)');

    % Levene's test: residual variance equal across Dataset groups
    group = data.DatasetID;   % categorical grouping variable

    % Manual Levene's test (ANOVA on absolute deviations from group median)
    groups = unique(group);
    absDevFromMedian = zeros(size(model_residuals));
    for i = 1:numel(groups)
        idx = group == groups(i);
        absDevFromMedian(idx) = abs(model_residuals(idx) - median(model_residuals(idx)));
    end
    [p_levene, ~, stat_levene] = anova1(absDevFromMedian, group, 'on');
    fprintf('--- Final LMM Homoscedasticity Check ---\n');
    fprintf('Levene''s test (DatasetID) p = %.4f\n\n', p_levene);

    nexttile(tl)
    multcompare(stat_levene);

    
    % ------------------------------------------------------------------
    % Random-effects structure: Likelihood Ratio Test
    % ------------------------------------------------------------------
    % Compare model WITH participant random intercept vs WITHOUT
    lmm_full_ML = fitlme(data, char(model.Formula), ...
                        'FitMethod','ML');  % must use ML, not REML, to compare   
    % No Random Effects formula
    formula_noRE = [response_name ' ~ 1 + DatasetID'];
    lmm_reduced_ML = fitlme(data, formula_noRE, 'FitMethod', 'ML');
    fprintf('Likelehood Ratio Test For Final LMM With/Without Random Effects:\n')
    results = compare(lmm_reduced_ML, lmm_full_ML, 'CheckNesting', true);
    disp(results);
    
    % ------------------------------------------------------------------
    % Variance Function (Var(Y) ~ mu^P)
    % ------------------------------------------------------------------
    % Plot group means vs group variances directly
    groupMeans = splitapply(@mean, data{:, response_name}, findgroups(data.DatasetID));
    groupVars  = splitapply(@var,  data{:, response_name}, findgroups(data.DatasetID));
    
    nexttile(tl)
    scatter(log(groupMeans), log(groupVars), 60, 'filled');
    h_l = lsline();
    h_l.Color = "red";
    h_l.LineWidth = 1.5;
    xlabel(['log(Group Mean) of ' replace(response_name, "_", " / ")]); 
    ylabel(['log(Group Variance) of ' replace(response_name, "_", " / ")]);
    title('Final LMM Mean-Variance Relationship Across Datasets Directly');
    grid on

    % Fit line to log-log to check power relationship (slope~2 => Gamma, slope~3 => IG)
    p = polyfit(log(groupMeans), log(groupVars), 1);
    fprintf('--- Final LMM Variance Function Check Across Datasets Directly ---\n');
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f\n\n', p(1));

    % Bin fitted values into groups, compute empirical variance per bin,
    % then regress log(variance) on log(mean) -> slope should be ~3 for Inverse
    % Gaussian
    mu_hat    = predict(model); % conditional mean predictions
    model_residuals = residuals(model, 'ResidualType', 'Pearson');

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
            log_mean_bin(b) = log(mean(mu_hat(sel)));
            log_var_bin(b)  = log(var(model_residuals(sel)));
        end
    end
    valid = ~isnan(log_mean_bin) & ~isnan(log_var_bin);
    p = polyfit(log_mean_bin(valid), log_var_bin(valid), 1);
    fprintf('--- Final LMM Binned Variance Function Check ---\n');
    fprintf('Estimated slope of log(Var) vs log(Mean): %.3f\n\n', p(1));
    
    nexttile(tl)
    scatter(log_mean_bin(valid), log_var_bin(valid), 60, 'filled')
    hold on
    xfit = linspace(min(log_mean_bin(valid)), max(log_mean_bin(valid)), 50);
    plot(xfit, polyval(p, xfit), 'r-', 'LineWidth', 1.5)
    xlabel('log(Mean of \mu_{hat} per bin)')
    ylabel('log(Variance of residuals per bin)')
    title(sprintf('Final LMM Binned Variance Function Check (slope = %.2f)', p(1)))
    grid on

    % Diagnose what's actually driving bin membership
    tabulate(discretize(mu_hat, edges))  % check bin sizes are reasonably balanced
    nexttile(tl)
    scatter(mu_hat, data.DatasetID); % see if bins ~ perfectly separate Datasets
    xlabel('\mu_{hat}')
    ylabel('Dataset ID')
    title('Final LMM Fitted vs Dataset')
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
    formula = char(model.Formula);

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
    fprintf('--- RMS vs R Ratio Check --- \n')
    fprintf(['A flat/degenerate arc typically shows a LOW RMS relative to a ' ...
             'large R (points can lie close to many different large-radius circles))\n'])

    data.RMS_to_R_ratio = data.RMS ./ data.R;
    [~, idx] = sort(data.RMS_to_R_ratio);
    disp(data(idx(1:10), {'DatasetID','ParticipantIDGlobal','Leg','R','RMS','n_steps'}))

    % If row row_idx appears among the LOWEST ratios, that supports the degenerate-arc theory
    fprintf('Row %d RMS/R ratio: %.5f (rank %d of %d)\n\n', ...
        row_idx, data.RMS_to_R_ratio(row_idx), find(idx==row_idx), height(data));
    
    % Flag any observation where R is implausibly large relative to anatomical scale
    threshold = median(data.(response_name)) + 5*iqr(data.(response_name)); % or another defensible cutoff
    suspect_rows = data(data.(response_name) > threshold, :);
    fprintf('--- Observations with Implausibly Large %s --- \n', response_name)
    disp(suspect_rows(:, {'DatasetID','ParticipantIDGlobal','Leg','R','R_H','RMS','n_steps', 'ArcSpanDeg', 'ArcSpanRad'}))
    fprintf('%d observations exceed threshold R_H = %.3f (median(R_H) + 5*iqr(data.R_H))\n', height(suspect_rows), threshold);
    
    % ------------------------------------------------------------------
    % Direct Empirical Check: does small arc span predict implausible/unstable
    % R?
    % ------------------------------------------------------------------
    nexttile(tl)
    scatter(data.ArcSpanDeg, data.R_H, 15, 'filled');
    xlabel('Arc Span (rad)'); ylabel('R\_H');
    title('R\_H vs Arc Span — check for instability at low span');
    hold on;
    scatter(data.ArcSpanDeg(row_idx), data.R_H(row_idx), 100, 'r', 'filled');

    % Direct nonlinear fit of R vs arc span in radians, testing the geometric 
    % model: R ≈ L / (2*sin(theta/2)), solve for implied chord length L
    modelfun = @(b, theta) b(1) ./ (2*sin(theta/2));
    theta_rad = data.ArcSpanRad;
    b0 = 300; % initial guess for L (mm), rough anatomical chord length
    mdl_geom = fitnlm(theta_rad, data.R, modelfun, b0);
    disp(mdl_geom)
    % If this fits well (residuals small, L in a plausible anatomical range,
    % e.g., ~200-500 mm for a foot/shank-scale chord), it directly CONFIRMS
    % the mechanism: for small theta R ~ L / theta so R is inversely proportional
    % to the arc span => small arc spans give way to larger circles as the
    % circular fitting is less accurate.
   
    % Quantify: correlation between span and |R_H deviation from Dataset median|
    dataset_medians = grpstats(data.R_H, data.DatasetID, 'median');
    [G,~] = findgroups(data.DatasetID);
    data.abs_dev = abs(data.R_H - dataset_medians(G));
    [rho_span, p_span] = corr(data.ArcSpanRad, data.abs_dev, 'Type','Spearman');
    fprintf('Spearman correlation: arc span vs |R_H deviation|: rho=%.3f, p=%.4f\n', rho_span, p_span);

    % ------------------------------------------------------------------
    % Sensitivity Sweep for Arc Span Threshold
    % ------------------------------------------------------------------
    % Candidate thresholds informed by the visual elbow (~10-15°) in plot
    candidate_thresholds =  [3, 5, 8, 10, 12, 15, 20];  % degrees
    sensitivity_results = table();
    
    for th_deg = candidate_thresholds
        th_rad = deg2rad(th_deg);
        data_filt = data(data.ArcSpanDeg >= th_deg, :);
        weight_filt = weight(data.ArcSpanDeg >= th_deg);
        n_excluded = height(data) - height(data_filt);


        lme_filt   = fitlme(data_filt, formula, ...
                            'FitMethod', 'REML', ...
                            'Weights', weight_filt, ...
                            'DummyVarCoding', 'effects');
        [psi, mse] = covarianceParameters(lme_filt);
        ICC_filt = psi{1}(1,1) / (psi{1}(1,1) + mse);

        resid_filt = residuals(lme_filt, 'ResidualType', 'Pearson');
        [~, p_ad, adstat] = adtest(resid_filt);

        opts = optimoptions('fminunc');
        opts.Display = 'off';
        lme_alt = fitlme(data_filt, formula, ...
                         'FitMethod', 'REML', ...
                         'Weights', weight_filt, ...
                         'DummyVarCoding', 'effects', ...
                         'Optimizer', 'fminunc', ...
                         'OptimizerOptions', opts);

        [psi_alt, mse_alt] = covarianceParameters(lme_alt);
        ICC_alt = psi_alt{1}(1,1) / (psi_alt{1}(1,1) + mse_alt);

        sensitivity_results = [sensitivity_results; ...
            table(th_deg, th_rad, n_excluded, ICC_filt, ICC_alt, adstat, p_ad, ...
            'VariableNames', {'ThresholdDeg', 'ThresholdRad', 'N_Excluded','ICC', 'ICC_alt', 'AD_Statistic', 'Pvalue'})];
    end

    disp(sensitivity_results)

    nexttile(tl)
    plot(sensitivity_results.ThresholdDeg, sensitivity_results.ICC, '-o');
    xlabel('Arc Span Threshold (Degrees)'); 
    ylabel('ICC');
    title('LMM - ICC vs Arc Span Threshold');

    % ------------------------------------------------------------------
    % Sanity check for better optimizer for 5 and 8 degrees
    % ------------------------------------------------------------------
    for th_deg = [5, 8]
        data_filt = data(data.ArcSpanDeg >= th_deg, :);
        weight_filt = weight(data.ArcSpanDeg >= th_deg);

        lmm_qn = fitlme(data_filt, formula, ...
                        'FitMethod','REML', ...
                        'Weights', weight_filt, ...
                        'DummyVarCoding','effects');
        [psi_qn, mse_qn] = covarianceParameters(lmm_qn);
        ICC_qn = psi_qn{1}(1, 1) / (psi_qn{1}(1, 1) + mse_qn);

        opts = optimoptions('fminunc');
        opts.Display = 'off';
        lmm_fu = fitlme(data_filt, formula, ...
                        'FitMethod','REML', ...
                        'Weights', weight_filt, ...
                        'DummyVarCoding','effects', ...
                        'Optimizer','fminunc', ...
                        'OptimizerOptions', opts);
        [psi_fu, mse_fu] = covarianceParameters(lmm_fu);
        ICC_fu = psi_fu{1}(1, 1) / (psi_fu{1}(1, 1) + mse_fu);

        fprintf('--- Threshold %d degrees ---\n', th_deg);
        fprintf('Quasi-Newton: LogLik=%.6f, ICC=%.4f\n', lmm_qn.LogLikelihood, ICC_qn);
        fprintf('fminunc:      LogLik=%.6f, ICC=%.4f\n', lmm_fu.LogLikelihood, ICC_fu);

        % Manual profile: refit with tau^2 constrained near zero vs. away from zero,
        % by comparing a model that FORCES no random effect (tau^2=0) against the
        % freely-optimized model's log-likelihood
        formula_noRE = [response_name, '~ 1 + DatasetID'];
        lmm_noRE = fitlme(data_filt, formula_noRE, ...
                         'FitMethod','REML', ...
                         'Weights', weight_filt, ...
                         'DummyVarCoding','effects');
        fprintf('No random effect: LogLik=%.6f\n', lmm_noRE.LogLikelihood);
        
        % If lmm_qn (or lmm_fu)'s LogLik is only trivially higher than lmm_noRE's,
        % that supports tau^2=0 genuinely being close to the true optimum at this threshold.
        % If one of them is MEANINGFULLY higher, that one is the correct answer
        % and the other optimizer failed to find it.
    end
end