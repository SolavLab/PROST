% ------------------------------------------------------------------------------
% Correlation Analysis Script
% Created: 16.05.2026 by Chen Reichsbouscher
% MATLAB analysis script that loads a PROSTAnalyzer object, computes Pearson and 
% Spearman correlations and R^2 between radius and several anthropometric 
% predictors, detects/removes outliers, and compares raw, scaled, and 
% rank-transformed relationships. The script also generates plots (scaled data, 
% relationships, rank plots), performs PCA on predictors with diagnostic plots, 
% fits a linear model on PCA scores, and includes helper functions 
% compute_correlations, plot_relationships, and plot_scaled_data.
% ------------------------------------------------------------------------------

clearvars -except PROSTAnalyzer
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename;
toolbox_root = fileparts(script_full_path);

addpath(toolbox_root)
cd(toolbox_root)

set(0, 'DefaultFigureWindowStyle', 'docked')
warning('off', 'backtrace')

%% Load PROST Object
if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

%% Parameters
param_names = ["Height", "Leg_length", "Thigh_length", "Shank_length"];
display_names = replace(param_names, "_", " ");
colors = lines(numel(param_names));

%% Load Data
radius = table2array(PROSTAnalyzer.get_IPD_samples("Radius"));

predictors = struct();
for i = 1:numel(param_names)
    predictors.(param_names(i)) = ...
        table2array(PROSTAnalyzer.get_IPD_samples(param_names(i)));
end

%% Normalize Data
scale01 = @(x) rescale(x, 0, 1);

radius_norm = scale01(radius);

predictors_norm = structfun(scale01, predictors, UniformOutput=false);

%% Rank Data
radius_rank = tiedrank(radius);

predictors_rank = structfun(@tiedrank, predictors, UniformOutput=false);

%% Calculate Correlations
CorrR = compute_correlations(predictors, radius);

%% Display Results
disp("--------------- Correlation Results ---------------------------------------------------")

disp(CorrR)

%% Plot Scaled Data
plot_scaled_data(predictors_norm, ...
    radius_norm, ...
    display_names, ...
    colors, ...
    "Scaled Radius vs Scaled Anthropometrics")

plot_relationships(predictors_norm, ...
    radius_norm, ...
    display_names, ...
    colors, ...
    "Scaled Radius vs Scaled Anthropometrics")

%% Plot Rank Correlations
plot_relationships(predictors_rank, ...
    radius_rank, ...
    display_names, ...
    colors, ...
    "Ranks of Radius vs Ranks of Anthropometrics")

%% Remove Outliers
idx = ~isoutlier(radius, "median");

radius_screened = radius(idx);
radius_screened_norm = scale01(radius_screened);
radius_screened_rank = tiedrank(radius_screened);

predictors_screened = structfun(@(x) x(idx), predictors, ...
    UniformOutput=false);
predictors_screened_norm = structfun(scale01, predictors_screened, ...
    UniformOutput=false);
predictors_screened_rank = structfun(@tiedrank, predictors_screened, ...
    UniformOutput=false);

%% Calculate Screened Correlations
CorrR_screened = compute_correlations(predictors_screened, radius_screened);

%% Display Screened Results
disp("--------------- Screened Correlation Results ------------------------------------------")
disp(CorrR_screened)

%% Plot Screened Scaled Data
plot_scaled_data(predictors_screened_norm, ...
    radius_screened_norm, ...
    display_names, ...
    colors, ...
    "Scaled Screened Radius vs Scaled Anthropometrics")

plot_relationships(predictors_screened_norm, ...
    radius_screened_norm, ...
    display_names, ...
    colors, ...
    "Scaled Screened Radius vs Scaled Anthropometrics")

%% Plot Screened Rank Correlations
plot_relationships( ...
    predictors_screened_rank, ...
    radius_screened_rank, ...
    display_names, ...
    colors, ...
    "Ranks of Screened Radius vs Ranks of Anthropometrics")

%% PCA
X = zeros(numel(radius), numel(param_names));
for i = 1:numel(param_names)
    X(:, i) = predictors.(param_names(i));
end

figure

boxplot(X, 'Orientation', 'horizontal', 'Labels', display_names)

title("Predictors Distributions", FontName="Times New Roman", FontSize=20)
set(gca, 'FontName', "Times New Roman", 'FontSize', 14)


w = 1 ./ var(X);
[wcoeff, score, latent, tsquared, explained] = pca(X, 'VariableWeights',w);
coefforth = diag(std(X)) \ wcoeff;
cscores = zscore(X)*coefforth;

figure
plot(score(:,1), score(:,2), '+')

title("Predictors PCA", FontName="Times New Roman", FontSize=20)

xlabel('1st Principal Component')
ylabel('2nd Principal Component')

set(gca, 'FontName', "Times New Roman", 'FontSize', 14)

figure
pareto(explained)
xlabel('Principal Component')
ylabel('Variance Explained (%)')
set(gca, 'FontName', "Times New Roman", 'FontSize', 14)

mdl = fitlm(score(:, 1:2), radius);
disp("--------------- PCA Model -------------------------------------------------------------")
disp(mdl)

%% =========================================================================
% Helper Functions
% =========================================================================

function CorrT = compute_correlations(predictors, response)

names = string(fieldnames(predictors));

X = zeros(numel(response), numel(names));

R2 = [];
for i = 1:numel(names)
    X(:, i) = predictors.(names(i));
    mdl = fitlm(X(:, i), response);
    R2 = [R2; mdl.Rsquared.Ordinary];
end

[srho, sp] = corr(X, response, ...
    Type="Spearman", ...
    Rows="complete");

[prho, pp] = corr(X, response, ...
    Type="Pearson", ...
    Rows="complete");

CorrT = table( ...
    srho, ...
    sp, ...
    prho, ...
    pp, ...
    R2, ...
    VariableNames=[ ...
        "Spearman_rho", ...
        "Spearman_p", ...
        "Pearson_rho", ...
        "Pearson_p", ...
        "Rsquared"], ...
    RowNames=names);

end

function plot_relationships( ...
        predictors, ...
        response, ...
        display_names, ...
        colors, ...
        figure_title)

names = string(fieldnames(predictors));

figure
tl = tiledlayout();
title(tl, figure_title, "FontSize", 20, "FontName", "Times New Roman")

for i = 1:numel(names)

    ax = nexttile;
    hold on
    grid on

    x = predictors.(names(i));
    scatter(x, response, 100, colors(i,:), "filled", MarkerFaceAlpha=0.5, DisplayName="Data")

    p = polyfit(x, response, 1);
    xfit = linspace(min(x), max(x), 100);
    yfit = polyval(p, xfit);

    plot(xfit, yfit, 'k', LineWidth=1.5, DisplayName="Linear model")

    title(display_names(i) )

    xlabel(display_names(i) + " [-]")
    ylabel("Radius [-]")

    legend()

    set(ax, "FontSize", 14, "FontName", "Times New Roman")

end

end

function plot_scaled_data( ...
        predictors, ...
        response, ...
        display_names, ...
        colors, ...
        figure_title)

names = string(fieldnames(predictors));

figure
hold on
grid on
title(figure_title)

for i = 1:numel(names)
    scatter(predictors.(names(i)), ...
        response, ...
        100, ...
        colors(i, :), ...
        "filled", ...
        MarkerFaceAlpha=0.5, ...
        DisplayName=display_names(i))
end

set(gca, "FontSize", 14, "FontName", "Times New Roman")

xlabel("Lengths Scaled [-]")
ylabel("Radius Scaled [-]")

legend()
end