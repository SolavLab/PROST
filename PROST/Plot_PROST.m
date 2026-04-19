clearvars -except PROSTAnalyzer
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
toolbox_root = fileparts(script_full_path); % Get the folder of the script
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%% Load PROST Object
if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

dataset_ids = [PROSTAnalyzer.DataRecords.Dataset_id];
dataset_names = [PROSTAnalyzer.DataRecords.Dataset_name];
Dataset_1_ID = dataset_ids(matches(dataset_names, "Dataset 1"));
Dataset_2_ID = dataset_ids(matches(dataset_names, "Dataset 2"));
Dataset_3_ID = dataset_ids(matches(dataset_names, "Dataset 3"));
Dataset_4_ID = dataset_ids(matches(dataset_names, "Dataset 4"));

%% Plot All ROSs
% who_to_plot = PROST.PROSTDatasetList();
% for dataset_id=dataset_ids
%     who_to_plot.add_to_list(dataset_id);
% end
% PROSTAnalyzer.plot_ros(who_to_plot, number_of_axes_in_fig=6, plot_type="nadir", show="off", file_type="pdf", append=true);

%% Plot Example ROS
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(Dataset_2_ID, 12);
PROSTAnalyzer.plot_ros(who_to_plot, number_of_axes_in_fig=1, plot_type="circle", show="off", file_type="pdf");

%% Analyze Residuals
[~, ~, stats_res] = PROSTAnalyzer.plot_stats("Residual", [], [], ["normal"], function_type="pdf", qq_plot=true, show="off", file_type="pdf");
% Residual analysis results
disp("-------- Residuals Statistical Analysis --------")
for i=1:numel(stats_res)
    stats_i = stats_res(i);
    summary = stats_i.summary;
    chi2 = stats_i.fits.normal.chi2;

    disp("Category: " + stats_i.category)    
    disp("mu: " + summary.mean + " std: " + summary.std)
    disp("skewness: " + summary.skewness + " kurtosis: " + summary.kurtosis)
    if isnan(chi2.stat)
        disp("Not enough samples!")
    else
        s = "Chi2 test: pvalue = " + chi2.pvalue;
        if chi2.pvalue < 0.05
            s = s + " Residuals aren't normal!";
        else
            s = s + " Residuals are normal!";
        end
        disp(s)
    end
end

% Sanity Check
residuals = table2array(PROSTAnalyzer.get_samples("Residual"));
z = (residuals - mean(residuals)) / std(residuals);
[h, p] = kstest(z);
s = "Kolmogorov–Smirnov (KS) test: pvalue = " + p;
if h
    s = s + " Residuals aren't normal!";
else
    s = s + " Residuals are normal!";
end
disp(s)

[h, p] = lillietest(residuals);
s = "Lilliefors test: pvalue = " + p;
if h
    s = s + " Residuals aren't normal!";
else
    s = s + " Residuals are normal!";
end
disp(s)

[h, p, ~] = adtest(residuals);
s = "Anderson–Darling test: pvalue = " + p;
if h
    s = s + " Residuals aren't normal!";
else
    s = s + " Residuals are normal!";
end
disp(s)

%% Analyze Residuals per Dataset
[~, ~, stats_res] = PROSTAnalyzer.plot_stats("Residual", [], "Dataset_id", ["normal" "kernel" "tlocationscale"], function_type="pdf", qq_plot=true);
disp("-------- Residuals Statistical Analysis --------")
for i=1:numel(stats_res)
    stats_i = stats_res(i);
    summary = stats_i.summary;
    chi2 = stats_i.fits.normal.chi2;

    disp("Dataset ID: " + stats_i.category)    
    disp("mu: " + summary.mean + " std: " + summary.std)
    disp("skewness: " + summary.skewness + " kurtosis: " + summary.kurtosis)
    if isnan(chi2.stat)
        disp("Not enough samples!")
    else
        s = "Chi2 test: pvalue = " + chi2.pvalue;
        if chi2.pvalue < 0.05
            s = s + " Residuals aren't normal!";
        else
            s = s + " Residuals are normal!";
        end
        disp(s)
    end
end

%% Analyze Radius and Center Horizontal
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["kernel"], function_type="pdf", BinMethod='auto');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["kernel"], function_type="pdf", BinMethod='auto');
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["kernel"], function_type="pdf", BinMethod='scott');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["kernel"], function_type="pdf", BinMethod='scott');
% PROSTAnalyzer.plot_stats("Radius", [], [], ["kernel"], function_type="pdf", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["kernel"], function_type="pdf", BinMethod='fd');
% 
% [~, ~, stats_R] = PROSTAnalyzer.plot_stats("Radius", [], [], ["kernel" "normal" "lognormal" "gamma" "rayleigh" "half normal" "laplace" "tLocationScale" "exponential"], function_type="pdf", BinMethod='fd');
% [~, ~, stats_X] = PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["kernel" "normal" "laplace" "tlocationscale" "exponential"], function_type="pdf", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Radius", "Height", "Is_shod", ["kernel" "normal" "lognormal" "gamma" "rayleigh" "half normal" "laplace"], function_type="pdf", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", "Is_shod", ["kernel" "normal" "laplace"], function_type="pdf", BinMethod='fd');
% 
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["lognormal" "t Location Scale"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["tlocationscale"], function_type="pdf", BinMethod='fd');
% 
% PROSTAnalyzer.plot_stats("Radius", [], [], ["lognormal" "t Location Scale"], function_type="pdf", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["tlocationscale"], function_type="pdf", show="on", BinMethod='fd');


PROSTAnalyzer.plot_stats("Radius", "Height", [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
PROSTAnalyzer.plot_stats("Radius", [], [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
PROSTAnalyzer.plot_stats("Center_horizontal", [], [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");


[f_r, ~, stats_r] = PROSTAnalyzer.plot_stats("Radius", "Height", [], "tLocationScale", function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
[f_x, ~, stats_horizontal] = PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], "tLocationScale", function_type="pdf", show="on", file_type="pdf", BinMethod="fd");

disp("Radius:")
fprintf(PROST.utils.pretty_print(stats_r))
disp("Center Horizontal:")
fprintf(PROST.utils.pretty_print(stats_horizontal))

%%
PROSTAnalyzer.plot_stats("Radius", "Height", "Side", "tLocationScale", function_type="pdf", show="on", file_type="pdf", BinMethod="fd");

%% Plot Features vs Labels
[~, correlations] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius" "Center_horizontal"], show="on", file_type="pdf");
[~, correlations_norm] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius" "Center_horizontal"], norm_var_name="Height", show="on", file_type="pdf");

%% Plot Example COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(Dataset_2_ID, 12, 1, "Left");
PROSTAnalyzer.plot_cop(who_to_plot, number_of_axes_in_fig=1, show="off", file_type="pdf");

%% Save figures
PROST.utils.save_all_open_figures(fullfile(toolbox_root, "figures/ROS Analysis"), [], "jpg")
close all