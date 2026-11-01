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

% Mixed-effects analysis of the horizontal centre coordinate u_c [mm], the
% fore-aft position of the arc centre relative to the ankle. It mirrors the log R_H
% analysis of Radius_Mixed_Effects_Model.m and uses the same helpers (PROST.lme).
% u_c is modelled in mm: it is signed and additive, so it is not logged, and height
% enters the covariate models as a covariate rather than as a normalization.
boot_flag = false; % run the bootstrap SE/CI computation
summary_flag = false; % calculate summary statistics of the data (its coefficients of variation are meaningless for the signed u_c)
assumptions_flag = false; % test the LME assumptions of the response model
loo_flag = true; % leave-one-participant-out sensitivity of the ICC
per_dataset_icc_flag = true; % ICC of each dataset on its own (bootstrap CIs need boot_flag), with a forest plot
covariate_flag = true; % side, anthropometric and speed models of u_c (bootstrap CIs need boot_flag)
covariate_diagnostics_flag = false; % assumption checks of the covariate models and the per-dataset ICC models
save_flag = false; % save the complete results (needs boot_flag and loo_flag) to Center_Mixed_Effects_Results.mat
boot_seed = 20261006; % fixed so the bootstrap SE/CI are reproducible (see PROST.utils.boot_stream)
n_boot = 5000; % number of bootstrap replicates
unit = "[mm]"; % unit of u_c, for the diagnostic axis labels

% The saved file is the record of the reported results: a partial run must not
% overwrite a complete one.
if save_flag && ~(boot_flag && loo_flag)
    error("save_flag needs boot_flag and loo_flag: the saved file must hold the complete reported results.")
end

% u_c is on a linear scale, so the model-scale ICC is already on the original scale
responses = struct('name', {'u_c'}, 'scale', {"linear"});

% Covariate models, specified as in Radius_Mixed_Effects_Model.m (see the field
% descriptions there). Height enters linearly, as Height_c [m]: with a signed
% response there is no log-scale invariance to keep. There is no scaling model:
% u_c proportional to H constrains the intercept, not the slope, and the intercept
% is the dataset mean under the centring. The Height_c slope is reported instead,
% next to the slope proportional scaling would imply.
anthro_rows = ["Leg" "Age" "Sex" "Height" "Mass" "Leg_length"];
anthro_terms = ["Leg" "Age_c" "Sex" "Height_c" "Mass_c"];
covariate_models = [ ...
    struct('name', 'base_cc',       'response', 'u_c', 'terms', {strings(1, 0)}, ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', '')
    struct('name', 'side',          'response', 'u_c', 'terms', "Leg", ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'base_cc')
    struct('name', 'anthro',        'response', 'u_c', 'terms', anthro_terms, ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'side')
    struct('name', 'anthro_leglen', 'response', 'u_c', 'terms', ["Leg" "Age_c" "Sex" "Leg_length_c" "Mass_c"], ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'side')
    % Slope heterogeneity: one slope per dataset, tested against the common slope
    struct('name', 'anthro_het',    'response', 'u_c', 'terms', [anthro_terms ...
                                                                  "Age_c:DatasetID" "Sex:DatasetID" "Height_c:DatasetID" "Mass_c:DatasetID"], ...
           'complete', anthro_rows, 'datasets', [], 'cut', true, 'baseline', 'anthro')
    % Dataset 4 alone
    struct('name', 'base_D4',       'response', 'u_c', 'terms', {strings(1, 0)}, ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', '')
    struct('name', 'side_D4',       'response', 'u_c', 'terms', "Leg", ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'base_D4')
    struct('name', 'anthro_D4',     'response', 'u_c', 'terms', anthro_terms, ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'side_D4')
    struct('name', 'speed_D4',      'response', 'u_c', 'terms', "v_star_c", ...
           'complete', [anthro_rows "v_star"], 'datasets', 4, 'cut', true, 'baseline', 'base_D4')
    % Speed only in Datasets 3-4: in Datasets 1-2 a leg pools cued speed conditions
    struct('name', 'base_D34',      'response', 'u_c', 'terms', {strings(1, 0)}, ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', '')
    struct('name', 'speed_D34',     'response', 'u_c', 'terms', "v_star_c", ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', 'base_D34')
    struct('name', 'speed_D34_het', 'response', 'u_c', 'terms', ["v_star_c" "v_star_c:DatasetID"], ...
           'complete', "v_star", 'datasets', [3 4], 'cut', true, 'baseline', 'speed_D34')
    ]';

if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

%% Create Table for Statistical Analysis
data = PROST.lme.build_analysis_table(PROSTAnalyzer);

%% Cutoff of Unstable Arcs
% The R_H <= 1 cutoff of the radius analysis: for a flat arc the centre is far
% away and u_c is ill-defined, so the same legs are excluded.
idx = data.R_H <= 1;
data_final = data(idx, :);

fprintf('Excluded %d of %d observations (%.1f%%) with R_H > 1\n', ...
    height(data) - height(data_final), height(data), ...
    100*(height(data) - height(data_final)) / height(data));

%% Linear Mixed Effects Model of u_c
results = struct();
for spec = responses
    if summary_flag
        PROST.lme.describe_response(data_final, spec)
    end

    results.(spec.name) = PROST.lme.fit_response_model(data_final, spec);

    % Sensitivity of the ICC to Single Participants
    if loo_flag
        results.(spec.name).loo = PROST.lme.icc_leave_one_out(results.(spec.name).lme, "Final LME - " + spec.name);
    end

    % Test Linear Mixed-Effects Model Assumptions. The binned mean-variance check
    % works on log|fitted|, which has little meaning for u_c near zero.
    if assumptions_flag
        PROST.lme.assumptions_check(results.(spec.name).lme, "Final LME - " + spec.name + ":", unit)
    end

    if boot_flag
        results.(spec.name).boot = PROST.lme.bootstrap_response_model(data_final, spec, results.(spec.name), n_boot, boot_seed);
    end

    if per_dataset_icc_flag
        results.(spec.name).per_dataset = PROST.lme.per_dataset_icc(data_final, spec, n_boot, boot_seed, boot_flag);
        PROST.lme.plot_icc_forest(results.(spec.name), spec)
    end
end

% Assumption checks of the per-dataset ICC models
if covariate_diagnostics_flag
    PROST.lme.per_dataset_diagnostics(data_final, 'u_c', unit)
end

%% Covariate Models: Side, Anthropometrics and Speed
% How much of the between-participant variance tau2 the covariates explain
if covariate_flag
    results.covariate_models = struct();
    for model_spec = covariate_models
        model_data = PROST.lme.covariate_model_data(data_final, model_spec);
        baseline = struct([]);
        if ~isempty(model_spec.baseline)
            baseline = results.covariate_models.(model_spec.baseline);
        end
        results.covariate_models.(model_spec.name) = PROST.lme.fit_covariate_model(model_data, model_spec, baseline, height(data));
        if covariate_diagnostics_flag && ismember(model_spec.name, ["anthro" "anthro_D4" "speed_D34" "speed_D4"])
            PROST.lme.covariate_diagnostics(model_data, results.covariate_models.(model_spec.name), baseline, model_spec, unit)
        end
        if boot_flag
            results.covariate_models.(model_spec.name).boot = PROST.lme.bootstrap_covariate_model(model_data, ...
                results.covariate_models.(model_spec.name), baseline, n_boot, boot_seed);
        end
    end

    % Height slope next to the slope that u_c proportional to H would imply,
    % mean(u_c)/mean(H): a reference for its size, not a test
    anthro = results.covariate_models.anthro;
    anthro_data = anthro.lme.Variables(~anthro.lme.ObservationInfo.Excluded, :);
    is_height = strcmp(anthro.lme.CoefficientNames, 'Height_c');
    slope = anthro.lme.Coefficients(is_height, :);
    fprintf('\nHeight_c slope (anthro): %.1f mm per m, model CI [%.1f, %.1f]', slope.Estimate, slope.Lower, slope.Upper)
    if boot_flag
        fprintf(', bootstrap CI [%.1f, %.1f]', anthro.boot.boot_inferences{'Height_c', 'CI_lower'}, ...
            anthro.boot.boot_inferences{'Height_c', 'CI_upper'})
    end
    proportional_slope = mean(anthro_data.u_c) / mean(anthro_data.Height);
    fprintf('\nSlope implied by u_c proportional to H: %.1f mm per m (reference only)\n', proportional_slope)
    results.covariate_models.anthro.proportional_slope = proportional_slope;
end

% Distinct variable names, so loading the file next to other results cannot clash
if save_flag
    saved.center_lme_results = results;
    saved.center_lme_provenance = PROST.utils.provenance();
    save("Center_Mixed_Effects_Results", "-struct", "saved")
end

% PROST.utils.save_all_open_figures("C:\Users\chenr\Documents\PROST\figures\ROS Analysis\Mixed-Effects Plots\Center Horizontal", ".", "file_type", "pdf", "prepare","on", "append", "off")
