% ------------------------------------------------------------------
%  Convert C3D files to MAT Files
%  Created by Chen Reichsbouscher, 12.01.2026
% -------------------------------------------------------------------
clearvars -except good_trials DB_1 DB_3 DB_4;
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = ".\Data Files";
subjects_path = fullfile(data_path, "\138_HealthyPiG_10.05");

% Add ezc3d package
addpath(".\ezc3d_matlab");

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

%%
raw_data(138) = struct;
for p=1:138
    subject_folder = sprintf("SUBJ%02d", p);
    raw_data(p).folder = subject_folder;
    subject_files = [dir(fullfile(subjects_path, subject_folder, "*.c3d"))];
    subject_file_names = {subject_files.name};
    idx = contains(subject_file_names, "(0)");
    [c3d, fp] = ezc3dRead(convertStringsToChars(fullfile(subjects_path, subject_folder, subject_file_names{idx})));
    raw_data(p).standing_trial.filename = convertCharsToStrings(subject_file_names{idx});
    raw_data(p).standing_trial.c3d = c3d;
    raw_data(p).standing_trial.fp = fp;
    subject_file_names(idx) = [];
    n_trials = length(subject_file_names);
    raw_data(p).trial(n_trials) = struct;
    for t=1:n_trials
        [c3d, fp] = ezc3dRead(convertStringsToChars(fullfile(subjects_path, subject_folder, subject_file_names{t})));
        raw_data(p).trial(t).filename = convertCharsToStrings(subject_file_names{t});
        raw_data(p).trial(t).trial_num = sscanf(subject_file_names{t}, "SUBJ" + p + " (%d).c3d");
        raw_data(p).trial(t).c3d = c3d;
        raw_data(p).trial(t).fp = fp;
    end
end

%%
save(fullfile(data_path, "raw_data.mat"), "raw_data", "-v7.3");