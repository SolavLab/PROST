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
PROSTAnalyzer.plot_ros(who_to_plot, number_of_axes_in_fig=1, plot_type="circle", show="on", file_type="pdf");

%% Analyze Residuals
PROSTAnalyzer.plot_stats("Residual", [], [], "normal", function_type="pdf", qq_plot=true);

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


[~, ~, stats_r] = PROSTAnalyzer.plot_stats("Radius", "Leg_length", [], "tLocationScale", function_type="pdf", BinMethod="fd");
[~, ~, stats_horizontal] = PROSTAnalyzer.plot_stats("Center_horizontal", "Leg_length", [], "tlocationscale", function_type="pdf", BinMethod="fd");

disp("Radius:")
fprintf(PROST.utils.pretty_print(stats_r))
disp("Center Horizontal:")
fprintf(PROST.utils.pretty_print(stats_horizontal))

%% Plot Features vs Labels
PROSTAnalyzer.plot_features_vs_labels([], ["Radius" "Center_horizontal"], norm_var_name="Height");

%% Plot Example COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(Dataset_2_ID, 12, 1, "Left");
PROSTAnalyzer.plot_cop(who_to_plot, number_of_axes_in_fig=1, show="on", file_type="jpg");

%% Save figures
% PROST.utils.save_all_open_figures(fullfile(toolbox_root, "figures/ROS Analysis"), [], "jpg")
% close all