function assumptions_check(model, model_name, unit)
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
        unit (1, 1) string = "[-]" % unit of the response, for the axis labels
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
    PROST.lme.normality_check(RMS_raw, "Pooled RMS [mm]", 'anderson') % Test on pooled RMS data
    PROST.lme.normality_check(var_raw, "Pooled " + response_name + " " + unit, 'anderson') % Test continuous pooled response data

    % ------------------------------------------------------------------
    % Conditional Normality Assessment (LME Model Residuals)
    % ------------------------------------------------------------------
    model_residuals = residuals(model, 'ResidualType', 'Pearson');
    model_residuals = model_residuals(valid);
    PROST.lme.normality_check(model_residuals, model_name + " Residual [-]", 'anderson')
    
    % ------------------------------------------------------------------
    % Normality of Random Effects (BLUPs)
    % ------------------------------------------------------------------
    random_effects = randomEffects(model);
    PROST.lme.normality_check(random_effects, model_name + " Random Effects " + unit, 'anderson')

    % ------------------------------------------------------------------
    % Homoscedasticity
    % ------------------------------------------------------------------
    mu_hat = fitted(model);
    mu_hat = mu_hat(valid);

    figure(Name=model_name + " Residuals vs Fitted")
    scatter(mu_hat, model_residuals, 20, 'filled');
    yline(0, '--r');
    xlabel("Fitted values " + unit);
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
                        'Exclude', excluded);  % REML is valid for this LRT: full and nested models have identical fixed effects (Pinheiro & Bates 2000, Sec. 2.4.1)

    % No Random Effects formula
    formula_noRE = model.Formula.FELinearFormula.char;
    lmm_reduced = fitlme(data, formula_noRE, ...
                            'FitMethod', 'REML', ...
                            'DummyVarCoding', 'effect', ...
                            'Exclude', excluded);  % REML is valid for this LRT: full and nested models have identical fixed effects (Pinheiro & Bates 2000, Sec. 2.4.1)
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
    xlabel("\mu_{hat} " + unit)
    ylabel('Dataset ID')
    title([model_name ' Fitted vs Dataset'])
    grid on
end
