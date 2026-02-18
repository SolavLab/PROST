clearvars -except PROSTAnalyzer -regexp ^DB\w*
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
DB_1_ID = dataset_ids(matches(dataset_names, "Dataset 1"));
DB_2_ID = dataset_ids(matches(dataset_names, "Dataset 2"));
DB_3_ID = dataset_ids(matches(dataset_names, "Dataset 3"));
DB_4_ID = dataset_ids(matches(dataset_names, "Dataset 4"));

%% Plot data
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(DB_1_ID);
% who_to_plot.add_to_list(DB_2_ID);
% who_to_plot.add_to_list(DB_3_ID);
% who_to_plot.add_to_list(DB_4_ID);
PROSTAnalyzer.plot_ros(who_to_plot, 12, 'azimuth', 'on', 'fig');

%% Analyze Residuals
PROSTAnalyzer.plot_histogram("Residual", [], "Is_shod", "on", [], "Normalization", "pdf");

%% Analyze Radius and Center x
PROSTAnalyzer.plot_histogram("Radius", "Height", "Is_shod", "on", [], "Normalization", "pdf");
PROSTAnalyzer.plot_histogram("Center_x", "Height", "Is_shod", "on", [], "Normalization", "pdf");

%% Plot Features vs Labels
PROSTAnalyzer.plot_features_vs_labels([], ["Radius" "Center_x"], [], "Height", 'on', 'fig')

%% Plot COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(DB_2_ID, 12, 1, "Left");
who_to_plot.add_to_list(DB_4_ID, 1, 1, "Left");
PROSTAnalyzer.plot_cop(who_to_plot, 12, 'on', 'fig');

%% PLS Regression
% [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = obj.pls_analysis();

%% Save figures
% PROST.utils.save_all_open_figures("./figures/ROS Analysis", [], "png")
% close all
