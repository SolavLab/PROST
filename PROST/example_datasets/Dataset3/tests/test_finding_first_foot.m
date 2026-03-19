% TEST_FINDING_FIRST_FOOT :
% Validates step-foot labeling in walking trials by comparing the provided 
% stepping foot to heel marker kinematics. For each subject and walking trial, 
% the script identifies the frame of maximum right and left heel height and 
% checks whether their temporal order matches the labeled stepping foot. Trials 
% with mismatches are flagged as bad, plotted for inspection, and counted; 
% per-subject summaries of good and bad trials are printed.
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
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

%%
for p=1:50
    load(fullfile(data_path, "Subject" + string(p) + ".mat"));
    iYRxHeel = strmatch('YRxHeel  ', s.MarkerVarName);
    iYLxHeel = strmatch('YLxHeel  ', s.MarkerVarName);
    good_counter = 0; bad_counter = 0;
    walking_data = s.Data(matches({s.Data.Task}, 'Walking'));
    n_walking = length(walking_data);

    for j=1:n_walking
        yR = walking_data(j).Marker(iYRxHeel, :);
        yL = walking_data(j).Marker(iYLxHeel, :);
        foot = walking_data(j).Foot;
                
        [~, idxR] = max(yR);
        [~, idxL] = max(yL);

        if (idxR < idxL && strcmp(foot, 'RX')) || (idxL < idxR && strcmp(foot, 'LX'))
            bad_counter = bad_counter + 1;
            disp("Subject" + string(p) + " Trial " + string(j) + " is bad.");
            figure
            plot(yR, DisplayName="Right heel")
            hold on
            plot(yL, DisplayName="Left heel")
            title("Heel Heights of Bad Trial", "P" + p + " T" + j + " Foot: " + foot)
            legend
        else
            good_counter = good_counter + 1;
        end
    end
    fprintf("Subject %d: Good: %d, Bad: %d, Total: %d\n", p, good_counter,  bad_counter, n_walking);
end