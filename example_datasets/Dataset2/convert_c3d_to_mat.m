% ------------------------------------------------------------------
%  Convert C3D files to MAT Files
%  Created by Chen Reichsbouscher, 20.04.2026
% -------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = ".\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

% Add ezc3d package
addpath(fullfile(toolbox_root, "lib-ext", "ezc3d_matlab"));

%%
raw_data(50) = struct;

subject_folders = dir(data_path);
subject_folders = subject_folders([subject_folders.isdir]);
subject_folders = string({subject_folders.name})';
subject_folders(subject_folders == "." | subject_folders == "..") = [];
for p=1:numel(subject_folders)
    subject_folder = subject_folders(p);
    raw_data(p).folder = subject_folder;
    subject_files = [dir(fullfile(data_path, subject_folder, "*.c3d"))];
    subject_files = {subject_files.name};
    idx = contains(subject_files, "ST");
    [c3d, fp] = ezc3dRead(convertStringsToChars(fullfile(data_path, subject_folder, subject_files{idx})));
    raw_data(p).standing_trial.filename = convertCharsToStrings(subject_files{idx});
    raw_data(p).standing_trial.c3d = c3d;
    raw_data(p).standing_trial.fp = fp;
    subject_files(idx) = [];
    n_trials = length(subject_files);
    raw_data(p).trial(n_trials) = struct;
    for t=1:n_trials
        [c3d, fp] = ezc3dRead(convertStringsToChars(fullfile(data_path, subject_folder, subject_files{t})));
        raw_data(p).trial(t).filename = convertCharsToStrings(subject_files{t});
        trial_num = sscanf(subject_files{t}, subject_folder + "_C%d_0%d.c3d");
        raw_data(p).trial(t).condition_num = trial_num(1);
        raw_data(p).trial(t).trial_num = trial_num(2);
        raw_data(p).trial(t).c3d = c3d;
        raw_data(p).trial(t).fp = fp;
    end
end

%%
save(fullfile(data_path, "raw_data.mat"), "raw_data", "-v7.3");