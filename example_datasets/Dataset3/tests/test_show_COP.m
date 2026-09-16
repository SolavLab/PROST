% TEST_SHOW_COP :
% Visualizes center-of-pressure (CoP) trajectories for selected participants. 
% For each participant, the script plots CoP x vs y trajectories for all 
% right and left step trials separately, enabling per-trial inspection of CoP 
% patterns and consistency across steps.
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = mfilename('fullpath'); % Full path of this script (MATLAB editor, VS Code, and batch)
if isempty(script_full_path)
    script_full_path = matlab.desktop.editor.getActiveFilename; % Fallback: evaluating a selection in the MATLAB editor
end
assert(~isempty(script_full_path), "Cannot determine script location. Run the whole file rather than a selection.")
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = "..\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
i_end = find(matches(toolbox_root, "PROST"), 1, "last");
toolbox_root = fullfile(toolbox_root{1:i_end});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

if ~exist("Dataset_3", "var")
    load("../../Dataset_3.mat");
end

%%
% Choose which participants to plot
participants = 1:10;
n_participants = length(fieldnames(Dataset_3.Data));
for p=participants
    if p > n_participants
        break
    end

    fig  = figure(Name="CoP Measurements - Participant " + p, Visible='on');
    tOuter = tiledlayout(fig, 'TileSpacing', 'tight', 'Padding', 'tight');
    sgtitle(fig, replace(fig.Name, "_", " "))

    right_data = Dataset_3.Data.("participant_" + num2str(p)).uniform_data.right.step;
    left_data = Dataset_3.Data.("participant_" + num2str(p)).uniform_data.left.step;
    n_right_data = length(right_data);
    n_left_data = length(left_data);
    
    n_trials = max(n_right_data, n_left_data);
    for t=1:n_trials
        % Inner tile for pair
        tInner = tiledlayout(tOuter, 1, 2, 'Padding', 'tight', 'TileSpacing','tight');
        tInner.Layout.Tile = t;

        ax_right = nexttile(tInner, 1);
        if t <= n_right_data
            plot(ax_right, right_data(t).COP.x, right_data(t).COP.y, '.', MarkerSize=2, Color=[0 0.85 0]);
            title(ax_right, "Right CoP", "Step " + t);
            axis(ax_right, "equal");
            pbaspect(ax_right, [1 1 1]);
            xlabel(ax_right, "x [mm]");
            ylabel(ax_right, "y [mm]");
        else
            ax_right.Visible = "off";
        end

        ax_left = nexttile(tInner, 2);
        if t <= n_left_data
            plot(ax_left, left_data(t).COP.x, left_data(t).COP.y, '.', MarkerSize=2, Color=[0.85 0 0]);
            title(ax_left, "Left CoP", "Step " + t);
            axis(ax_left, "equal");
            pbaspect(ax_left, [1 1 1]);
            xlabel(ax_left, "x [mm]");
            ylabel(ax_left, "y [mm]");
        else
            ax_left.Visible = "off";
        end
    end
end
