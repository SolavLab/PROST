% Here we just want to see the COP for select participants
clearvars
close all
clc
addpath("..\..\Helper Functions\DisplayTools\")
load("..\DB_3.mat");
n_participants = length(fieldnames(DB_3.Data));
for p=1:10
    right_data = DB_3.Data.("participant_" + num2str(p)).processed_data.right.step;
    left_data = DB_3.Data.("participant_" + num2str(p)).processed_data.left.step;
    n_right_data = length(right_data);
    n_left_data = length(left_data);
    figure
    tiledlayout
    sgtitle("Participant " + num2str(p) + " Right Leg - COP")
    for t=1:n_right_data
        nexttile
        plot(right_data(t).COP.x, right_data(t).COP.y, '.', MarkerSize=2);
        title("Trial " + num2str(t));
    end
    figure
    tiledlayout
    sgtitle("Participant " + num2str(p) + " Left Leg - COP")
    for t=1:n_left_data
        nexttile
        plot(left_data(t).COP.x, left_data(t).COP.y, '.', MarkerSize=2);
        title("Trial " + num2str(t));
    end
end
TileFigures()