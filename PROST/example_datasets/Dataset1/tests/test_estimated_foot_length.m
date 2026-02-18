% TEST_ESTIMATED_FOOT_LENGTH :
% Evaluates the accuracy of foot-length estimation from gait marker data. 
% For each participant, the script extracts measured foot length from metadata, 
% estimates left and right foot lengths from step trajectories, and computes 
% relative estimation error (%). It reports per-participant errors and 
% summarizes mean and standard deviation across participants. The script then 
% visualizes error distributions, measured foot-length distributions, left–right 
% estimated differences, and the relationship between measured and estimated 
% foot lengths.
% ------------------------------------------------------------------------------
clc; close all; clearvars -except -regexp ^Dataset\w*

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = "..\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

if ~exist('Dataset_1', 'var')
    load("../../Dataset_1.mat")
end

%% Test estimated length
participants = string(fieldnames(Dataset_1.Data));
n_participants = length(participants);

error_right = zeros(n_participants, 1);
error_left = zeros(n_participants, 1);
foot_length_right = zeros(n_participants, 1);
foot_length_left = zeros(n_participants, 1);
estimated_foot_length_right = zeros(n_participants, 1);
estimated_foot_length_left = zeros(n_participants, 1);
for p=1:n_participants
    participant_name = participants(p);
    participant_id = erase(PROST.utils.capitalize(participant_name), "_");
    metadata_array = split(string(fileread(fullfile(data_path, participant_id, "Metadata.txt"))));
    
    % Get provided foot length from metadata
    foot_length_right(p) = double(metadata_array(21));
    foot_length_left(p) = double(metadata_array(21));

    % Estimate foot length from markers
    right_steps = Dataset_1.Data.(participant_name).uniform_data.right.step;
    estimated_foot_length_right(p) = PROST.utils.estimate_foot_length(right_steps);
    left_steps = Dataset_1.Data.(participant_name).uniform_data.left.step;
    estimated_foot_length_left(p) = PROST.utils.estimate_foot_length(left_steps);

    % Calculate error between provided and estimated foot length
    error_right(p) = abs(foot_length_right(p) - estimated_foot_length_right(p)) / foot_length_right(p) * 100;
    error_left(p) = abs(foot_length_left(p) - estimated_foot_length_left(p)) / foot_length_left(p) * 100;

    fprintf("%s: left error: %.2f%%, right error: %.2f%%\n", participant_name, error_left(p), error_right(p));
end
disp("Mean: left error: " + mean(error_left) + "%, right error: " + mean(error_right) + "%");
disp("Std: left error: " + std(error_left) + "%, right error: " + std(error_right) + "%");

%% Histogram of Errors
nbins = 7;
figure
tiledlayout
nexttile
histogram(error_left, nbins)
title("Left Foot Length Estimation Errors Histogram")
xlabel("percent")
nexttile
histogram(error_right, nbins)
title("Right Foot Length Estimation Errors Histogram")
xlabel("percent")

%% Histogram of Feet Lengths
nbins = 10;
figure
tiledlayout
nexttile
histogram(foot_length_right, nbins)
title("Right Foot Length Histogram")
xlabel("percent")
nexttile
histogram(foot_length_left, nbins)
title("Left Foot Length Histogram")
xlabel("percent")

%% Histogram of Estimated Feet Length Differences
nbins = 10;
figure
histogram(abs(estimated_foot_length_right - estimated_foot_length_left), nbins)
title("Estimated Foot Length Difference Between Feet Histogram")
xlabel("percent")


%% Measured VS Estimated
figure
axis equal
plot(foot_length_right, estimated_foot_length_right, 'o', MarkerSize=8, MarkerFaceColor=[0 0.85 0])
hold on
plot(foot_length_left, estimated_foot_length_left, 'o', MarkerSize=8, MarkerFaceColor=[0.85 0 0])

title("Foot Length Measured v.s. Estimated Length")
xlabel("Measured Length [m]")
ylabel("Estimated Length [m]")
legend(["right" "left"])
grid on

