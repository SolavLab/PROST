clearvars -except DB_1 DB_2 DB_3
close all
clc

%% Setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
toolbox_root = fileparts(script_full_path); % Get the folder of the script
addpath(toolbox_root); % Add PROST package to path
dataset_dir = fullfile(toolbox_root, 'example_datasets'); % Path to the example_datasets
cd(toolbox_root); % Change to folder of current script

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%% Build data
db_list = ["DB_1", fullfile(dataset_dir, "DB_1.mat"); "DB_2", fullfile(dataset_dir, "DB_2.mat"); "DB_3", fullfile(dataset_dir, "DB_3.mat")];

var_names = db_list(:, 1);
for index = 1:length(var_names)
    if ~exist(var_names(index), "var")
        load(db_list(index, 2))
    end
end
 
clearvars -except DB_1 DB_2 DB_3
close all 
clc

%% Load and ignore lists
%   load_list - a cell array where each row contains pairs of dataset name and 
%               path to the dataset. Example:
%               {"DB 1 Name", "path/to/DB1.mat"; "DB 2 Name", "path/to/DB2.mat"}
load_list = {DB_1, "Moreira et. al. (2021)"; DB_2, "Schreiber & Moissenet (2019)"; DB_3, "Lencioni et. al. (2019)"};
n_datasets = size(load_list, 1);

%% Create ROS analysis object
[PROSTObj, dataset_ids] = PROST.PROSTAnalyzer(load_list);
DB_1_ID = dataset_ids(1);
DB_2_ID = dataset_ids(2);
DB_3_ID = dataset_ids(3);

%% Clean data
% Some participants have bad data and should be ignored so we add them to an
% ignored list
ignore_list = PROST.PROSTIgnore();
ignore_list.add_ignored(DB_1_ID, [3 5 14 15 16], [], "Left");
ignore_list.add_ignored(DB_1_ID, [5 14 15 16], [], "Right");
ignore_list.add_ignored(DB_2_ID, [31], [], "Left");
ignore_list.add_ignored(DB_3_ID, [43, 47], [], "Left");

PROSTObj.clean_data(ignore_list);

%% Add to samples table data from datasets
for index=1:n_datasets
    dataset_name = PROSTObj.get_dataset_name(dataset_ids(index));
    PROSTObj.add_samples(dataset_ids(index));
end

%% Save PROST Object
save("PROSTObj.mat","PROSTObj")

%% Plot data
% close all
PROSTObj.plot_ros({DB_1_ID, 1}, 1, 'on', 'fig');

%% Analyze Residuals
disp("Plotting histogram of residuals")
figure(Name="Histogram:Residuals Histogram vs Normal Distribution Comparison");
residuals = table2array(PROSTObj.get_samples("Residual"));
is_shod = table2array(PROSTObj.get_samples("Is_shod"));
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
disp("Plotting histogram of normalized radius and center x (by hight)")
radius = table2array(PROSTObj.get_samples("Radius"));
center_x = table2array(PROSTObj.get_samples("Center_x"));
height = PROST.utils.convert_units(table2array(PROSTObj.get_samples("Height")), "m", "mm");
normalized_radius = radius./height;
normalized_center_x = center_x./height;

f = figure(Name="Histogram:Normalized Radius Histogram vs Normal Distribution Comparison");
h_radius = histogram(normalized_radius);
h_radius.Normalization = 'count';
h_radius.BinWidth = 0.1;
h_radius.DisplayName = "Radius";

h = findobj(gcf, 'Type', 'histogram');
edges = 0.1:0.01:1;  % Define your desired bin edges (range and bin width)
h.BinEdges = edges;

title(replace(f.Name, "_", " "))
xlabel("Normalized Radius [m/m]")

f = figure(Name="Histogram:Normalized Center x Histogram vs Normal Distribution Comparison");
h_center_x = histogram(normalized_center_x);
h_center_x.Normalization = 'count';
h_center_x.BinWidth = 0.1;
h_center_x.DisplayName = "Center x";


h = findobj(gcf, 'Type', 'histogram');
edges = -0.5:0.01:0.5;  % Define your desired bin edges (range and bin width)
h.BinEdges = edges;

title(replace(f.Name, "_", " "))
xlabel("Normalized Center x [m/m]")

%% Plot Features vs Labels
PROSTObj.plot_features_vs_labels([], ["Radius" "Center_x"])

%% PLS Regression
% [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = obj.pls_analysis();

%% Save figures
% PROST.utils.save_all_open_figures("./figures/ROS Analysis", [], "fig")
% close all
