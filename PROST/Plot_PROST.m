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
who_to_plot.add_to_list(DB_1_ID, 1);
who_to_plot.add_to_list(DB_4_ID, 1);
PROSTObj.plot_ros(who_to_plot, 12, 'on', 'fig');
PROSTAnalyzer.plot_ros(who_to_plot, 12, 'azimuth', 'on', 'fig');

%% Analyze Residuals
disp("Plotting histogram of residuals")
figure(Name="Histogram:Residuals vs Normal Distribution Comparison");
residuals = table2array(PROSTAnalyzer.get_samples("Residual"));
is_shod = table2array(PROSTAnalyzer.get_samples("Is_shod"));
shod_residuals = residuals(is_shod == "Yes");
not_shod_residuals = residuals(is_shod == "No");

h_shod = histogram(shod_residuals);
h_shod.Normalization = 'pdf';
h_shod.BinWidth = 0.25;
h_shod.FaceAlpha = 0.5;
h_shod.FaceColor = [0 0.4470 0.7410];
h_shod.DisplayName = "Shod";

hold on
h_not_shod = histogram(not_shod_residuals);
h_not_shod.Normalization = 'pdf';
h_not_shod.FaceAlpha = 0.5;
h_not_shod.BinWidth = h_shod.BinWidth;
h_not_shod.FaceColor = [0.8500 0.3250 0.0980];
h_not_shod.DisplayName = "Not Shod";

y_shod = 0:0.1:5.5;
mu_shod = mean(shod_residuals);
sigma_shod = std(shod_residuals);
f_shod = normpdf(y_shod, mu_shod, sigma_shod);
plot(y_shod, f_shod, LineWidth=1.5, Color=h_shod.FaceColor, DisplayName="Shod")

y_not_shod = y_shod;
mu_not_shod = mean(not_shod_residuals);
sigma_not_shod = std(not_shod_residuals);
f_not_shod = normpdf(y_not_shod, mu_not_shod, sigma_not_shod);
plot(y_not_shod, f_not_shod, LineWidth=1.5, Color=h_not_shod.FaceColor, DisplayName="Not Shod")

title("Residuals Histogram vs Normal Distribution Comparison")
xlabel("Residual [mm]")
legend(FontSize=12)

%% Analyze Radius and Center x
PROSTAnalyzer.plot_histogram("Radius", "Height", "on", [], 'Normalization', 'pdf')
PROSTAnalyzer.plot_histogram("Center_x", "Height", "on", [], 'Normalization', 'pdf')

%% Plot Features vs Labels
PROSTAnalyzer.plot_features_vs_labels([], ["Radius" "Center_x"], [], [], 'on', 'fig')

%% Plot COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(DB_2_ID, [12], [1], "Left");
who_to_plot.add_to_list(DB_4_ID, [1], [1], "Left");
PROSTAnalyzer.plot_cop(who_to_plot, 12, 'on', 'fig');

%% PLS Regression
% [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = obj.pls_analysis();

%% Save figures
% PROST.utils.save_all_open_figures("./figures/ROS Analysis", [], "fig")
% close all
