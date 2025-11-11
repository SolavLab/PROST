clearvars -except DB_1 DB_2 DB_3
close all
clc

% setup
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder); % Change to folder of current script
addpath(genpath(".\Helper Functions")); % Add path to helper functions
set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%% Build data
db_list = ["DB_1", "./DB1/DB_1.mat"; "DB_2", "./DB2/DB_2.mat"; "DB_3", "./DB3/DB_3.mat"];

var_names = db_list(:, 1);
dataset_paths = split(db_list(:, 2), "/");
if iscolumn(dataset_paths)
    dataset_paths = dataset_paths';
end
for index = 1:length(var_names)
    if ~exist(var_names(index), "var")
        load(db_list(index, 2))
    end
end
% build_names = replace("build_database_" + dataset_paths(:, end), "mat", "m");
% dataset_paths(:, end) = build_names(:);
% for index = 1:length(var_names)
%     if ~exist(var_names(index), "var")
%         disp("Building " + var_names(index) + "...")
%         dataset_file = join(dataset_paths(index, :), "/");
%         run(dataset_file)
%     end
% end
 
clearvars -except DB_1 DB_2 DB_3
close all 

%% Load and ignore lists
%   load_list - a cell array where each row contains pairs of dataset name and 
%               path to the dataset. Example:
%               {"DB 1 Name", "path/to/DB1.mat"; "DB 2 Name", "path/to/DB2.mat"}
load_list = {DB_1, "Moreira et. al. (2021)"; DB_2, "Schreiber & Moissenet (2019)"; DB_3, "Lencioni et. al. (2019)"};

%% Create ROS analysis object
[obj, dataset_ids] = ROSAnalyzer(load_list);
DB_1_ID = dataset_ids(1);
DB_2_ID = dataset_ids(2);
DB_3_ID = dataset_ids(3);

%% Clean data
% Some participants have bad data and should be ignored.
%   ignore_list - list of trials to ignore (left and right steps per 
%                 participant. A cell array of the form:
%                 {DB ID, [participants_to_ignore_left], [participants_to_ignore_right]}
ignore_list = {DB_1_ID, [3 5 14 15 16], [5 14 15 16]; DB_2_ID, [31], []; DB_3_ID, [43, 47], []};
obj.filter_data_by_id(ignore_list);

%% Plot data
% close all
obj.plot_ros({DB_2_ID, 24}, 12);

%% Analyze Residuals
disp("Plotting histogram of residuals")
figure(Name="Residuals Histogram vs Normal Distribution Comparison");
residuals = obj.get_sample_var("Residual");
is_shod = obj.get_sample_var("Is_shod");
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
radius = obj.get_sample_var("Radius");
center_x = obj.get_sample_var("Center_x");
height = convert_units(obj.get_sample_var("Height"), "m", "mm");
normalized_radius = radius./height;
normalized_center_x = center_x./height;

f = figure(Name="Normalized Radius Histogram vs Normal Distribution Comparison");
h_radius = histogram(normalized_radius);
h_radius.Normalization = 'count';
h_radius.BinWidth = 0.1;
h_radius.DisplayName = "Radius";

h = findobj(gcf, 'Type', 'histogram');
edges = 0.1:0.01:1;  % Define your desired bin edges (range and bin width)
h.BinEdges = edges;

title(replace(f.Name, "_", " "))
xlabel("Normalized Radius [m/m]")

f = figure(Name="Normalized Center x Histogram vs Normal Distribution Comparison");
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
obj.plot_features_vs_labels([], ["Radius" "Center_x"])

%% PLS Regression
% [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = obj.pls_analysis();

%% Save figures
% save_all_open_figures("./figures/ROS Analysis/FMinUnc", "fig")