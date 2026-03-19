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

%% Plot data ROS
% who_to_plot = PROST.PROSTDatasetList();
% who_to_plot.add_to_list(Dataset_4_ID, 1:12);
% for dataset_id=dataset_ids
%     who_to_plot.add_to_list(dataset_id);
% end
% PROSTAnalyzer.plot_ros(who_to_plot, 6, 'nadir', 'on', 'pdf');

%% Analyze Residuals
PROSTAnalyzer.plot_stats("Residual", [], "Is_shod", ["kernel"], function_type="pdf", show="on", BinMethod='auto');

%% Analyze Radius and Center Horizontal
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["kernel"], function_type="pdf", show="on", BinMethod='auto');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["kernel"], function_type="pdf", show="on", BinMethod='auto');
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["kernel"], function_type="pdf", show="on", BinMethod='scott');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["kernel"], function_type="pdf", show="on", BinMethod='scott');
% PROSTAnalyzer.plot_stats("Radius", [], [], ["kernel"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["kernel"], function_type="pdf", show="on", BinMethod='fd');
% 
% [~, ~, stats_R] = PROSTAnalyzer.plot_stats("Radius", [], [], ["kernel" "normal" "lognormal" "gamma" "rayleigh" "half normal" "laplace" "tLocationScale" "exponential"], function_type="pdf", show="on", BinMethod='fd');
% [~, ~, stats_X] = PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["kernel" "normal" "laplace" "tlocationscale" "exponential"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Radius", "Height", "Is_shod", ["kernel" "normal" "lognormal" "gamma" "rayleigh" "half normal" "laplace"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", "Is_shod", ["kernel" "normal" "laplace"], function_type="pdf", show="on", BinMethod='fd');
% 
% PROSTAnalyzer.plot_stats("Radius", "Height", [], ["lognormal" "t Location Scale"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["tlocationscale"], function_type="pdf", show="on", BinMethod='fd');
% 
% PROSTAnalyzer.plot_stats("Radius", [], [], ["lognormal" "t Location Scale"], function_type="pdf", show="on", BinMethod='fd');
% PROSTAnalyzer.plot_stats("Center_horizontal", [], [], ["tlocationscale"], function_type="pdf", show="on", BinMethod='fd');


[~, ~, stats_R] = PROSTAnalyzer.plot_stats("Radius", "Height", [], ["tLocationScale"], function_type="pdf", show="on", BinMethod='fd');
[~, ~, stats_X] = PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], ["tlocationscale"], function_type="pdf", show="on", BinMethod='fd');

%% Plot Features vs Labels
PROSTAnalyzer.plot_features_vs_labels([], ["Radius" "Center_horizontal"], [], "Height", 'on', 'fig');

%% Plot COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(Dataset_2_ID, 12, 1, "Left");
who_to_plot.add_to_list(Dataset_4_ID, 1, [1 2 3], "Left");
PROSTAnalyzer.plot_cop(who_to_plot, 3, 'on', 'fig');

%% PLS Regression
% [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = obj.pls_analysis();

%% Save figures
% PROST.utils.save_all_open_figures(fullfile(toolbox_root, "figures/ROS Analysis"), [], "pdf")
% close all
