clearvars -except DB_1
close all
clc
% Test Foot Length
if ~exist('DB_1', 'var')
    load("DB_1.mat")
end

%% Test estimated length
participants = string(fieldnames(DB_1.Data));
n_participants = length(participants);

error_right = [];
error_left = [];
foot_length_right = [];
estimated_foot_length_right = [];
foot_length_left = [];
estimated_foot_length_left = [];
for participant_name=participants'
    foot_length_right(end + 1) = DB_1.Data.(participant_name).metadata.Foot_length.right.value;
    estimated_foot_length_right(end + 1) = DB_1.Data.(participant_name).metadata.Estimated_foot_length.right.value;
    foot_length_left(end + 1) = DB_1.Data.(participant_name).metadata.Foot_length.left.value;
    estimated_foot_length_left(end + 1) = DB_1.Data.(participant_name).metadata.Estimated_foot_length.left.value;
    error_right(end + 1) = abs(foot_length_right - estimated_foot_length_right) / foot_length_right * 100;
    error_left(end+1) = abs(foot_length_left - estimated_foot_length_left) / foot_length_left * 100;
    disp(participant_name + ": left error: " + error_left(end) + "%, right error: " + error_right(end) + "%")
end
disp("Mean: left error: " + mean(error_left) + "%, right error: " + mean(error_right) + "%");
disp("Std: left error: " + std(error_left) + "%, right error: " + std(error_right) + "%");

%% Histogram of Errors
nbins = 10;
figure
tiledlayout
nexttile
histogram(error_right, nbins)
title("Right Foot Length Estimation Errors Histogram")
xlabel("percent")
nexttile
histogram(error_left, nbins)
title("Left Foot Length Estimation Errors Histogram")
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
plot(foot_length_right, estimated_foot_length_right, 'o', MarkerSize=5)
hold on
plot(foot_length_left, estimated_foot_length_left, 'o', MarkerSize=5)

title("Foot Length Measured v.s. Estimated Length")
xlabel("Measured Length [m]")
ylabel("Estimated Length [m]")
legend(["right" "left"])
grid on

