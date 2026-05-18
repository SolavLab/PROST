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
warning('off', 'backtrace')

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
who_to_plot.add_to_list(Dataset_2_ID, 7);
PROSTAnalyzer.plot_ros(who_to_plot, number_of_axes_in_fig=1, plot_type="circle", show="off", file_type="pdf");

%% Analyze Residual RMS
[~, ~, stats_res] = PROSTAnalyzer.plot_stats("Residual_rms", [], [], ["normal"], function_type="pdf", show="off", file_type="pdf");

% Residual RMS analysis results
% disp("-------- Residual RMS Statistical Analysis --------")
% for i=1:numel(stats_res)
%     stats_i = stats_res(i);
%     summary = stats_i.summary;
%     chi2 = stats_i.fits.normal.chi2;
% 
%     disp("Category: " + stats_i.category)    
%     disp("mu: " + summary.mean + " std: " + summary.std)
%     disp("skewness: " + summary.skewness + " kurtosis: " + summary.kurtosis)
%     if isnan(chi2.stat)
%         disp("Not enough samples!")
%     else
%         s = "Chi2 test: pvalue = " + chi2.pvalue;
%         if chi2.pvalue < 0.05
%             s = s + " Not normal!";
%         else
%             s = s + " Normal!";
%         end
%         disp(s)
%     end
% end
% 
% % Sanity Check
% residual_rms = table2array(PROSTAnalyzer.get_samples("Residual_rms"));
% z = (residual_rms - mean(residual_rms)) / std(residual_rms);
% [h, p] = kstest(z);
% s = "Kolmogorov–Smirnov (KS) test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% 
% [h, p] = lillietest(residual_rms);
% s = "Lilliefors test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% 
% [h, p, ~] = adtest(residual_rms);
% s = "Anderson–Darling test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)

%% Analyze Residual RMS per Dataset
% [~, ~, stats_res] = PROSTAnalyzer.plot_stats("Residual_rms", [], "Dataset_id", ["normal" "kernel" "tlocationscale"], function_type="pdf", qq_plot=true);
% disp("-------- Residual RMS Statistical Analysis --------")
% for i=1:numel(stats_res)
%     stats_i = stats_res(i);
%     summary = stats_i.summary;
%     chi2 = stats_i.fits.normal.chi2;
% 
%     disp(stats_i.category)    
%     disp("mu: " + summary.mean + " std: " + summary.std)
%     disp("skewness: " + summary.skewness + " kurtosis: " + summary.kurtosis)
%     s = "Chi2 test:";
%     if isnan(chi2.stat)
%         s = s + " Not enough samples!";
%     else
%         s = s + " pvalue = " + chi2.pvalue;
%         if chi2.pvalue < 0.05
%             s = s + " Not normal!";
%         else
%             s = s + " Normal!";
%         end
%     end
%     s = s + "\n";
%     disp(s)
% end

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

% PROSTAnalyzer.plot_stats("Radius", "Height", [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
% PROSTAnalyzer.plot_stats("Radius", [], [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
% PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");
% PROSTAnalyzer.plot_stats("Center_horizontal", [], [], [], function_type="pdf", show="on", file_type="pdf", BinMethod="fd");

%%
[f_r, ~, stats_r] = PROSTAnalyzer.plot_stats("Radius", "Height", [], "tLocationScale", function_type="pdf", show="off", file_type="pdf", BinMethod="fd");
[f_x, ~, stats_horizontal] = PROSTAnalyzer.plot_stats("Center_horizontal", "Height", [], "tLocationScale", function_type="pdf", show="off", file_type="pdf", BinMethod="fd");

% Sanity Check
% radius = table2array(PROSTAnalyzer.get_samples("Radius"));
% center_h = table2array(PROSTAnalyzer.get_samples("Center_horizontal"));

% disp("-------- Parameters Statistical Analysis --------")
% disp("Radius:")
% [h, p] = lillietest(radius);
% s = "Lilliefors test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% 
% [h, p, ~] = adtest(radius);
% s = "Anderson–Darling test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% 
% disp("Center_horizontal:")
% [h, p] = lillietest(center_h);
% s = "Lilliefors test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% 
% [h, p, ~] = adtest(center_h);
% s = "Anderson–Darling test: pvalue = " + p;
% if h
%     s = s + " Not normal!";
% else
%     s = s + " Normal!";
% end
% disp(s)
% disp("Radius:")
% fprintf(PROST.utils.pretty_print(stats_r))
% disp("Center Horizontal:")
% fprintf(PROST.utils.pretty_print(stats_horizontal))

%% Plot Predictors vs Responses
winsor_options.p = [5 95];
outlier_options.method = "percentiles";
outlier_options.threshold = [5 95];
[f, correlations] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], show="on", file_type="pdf");
[f, correlations] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], show="on", file_type="pdf", filter="outlier", filter_options=outlier_options);
[f, correlations] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], show="on", file_type="pdf", filter="winsor", filter_options=winsor_options);

[f_n, correlations_norm] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], norm_var_name="Height", show="on", file_type="pdf");
[f_n, correlations_norm] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], norm_var_name="Height", show="on", file_type="pdf", filter="outlier", filter_options=outlier_options);
[f_n, correlations_norm] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius"], norm_var_name="Height", show="on", file_type="pdf", filter="winsor", filter_options=winsor_options);

% [f, correlations] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius" "Center_horizontal"], show="off", file_type="pdf");
% [f_n, correlations_norm] = PROSTAnalyzer.plot_predictors_vs_responses([], ["Radius" "Center_horizontal"], norm_var_name="Height", show="off", file_type="pdf");

%% Plot Example COP
who_to_plot = PROST.PROSTDatasetList();
who_to_plot.add_to_list(Dataset_2_ID, 7, 14, "Left");
PROSTAnalyzer.plot_cop(who_to_plot, number_of_axes_in_fig= 1, show="off", file_type="pdf");

%% Save figures
% PROST.utils.save_all_open_figures(fullfile(toolbox_root, "figures/ROS Analysis"), [], "jpg")
% close all