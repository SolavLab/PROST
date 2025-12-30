% clear all
% close all
% clc

subs = [1];
lw = 1.5;
%% Look at MAT file
load('data files\MAT_normalizedData_AbleBodiedAdults_v06-03-23.mat')

figure
sgtitle("Processed Data")
tiledlayout
for sub=subs
    nexttile
    for segment=["L" "R"]
        n_trials = width(Sub(sub).(segment + "sideSegm_LsideData").ANK.z);
        for i=1:n_trials           
            plot(Sub(sub).(segment + "sideSegm_" + segment + "sideData").GroundReactionForce.z(:, i), LineWidth=lw, Color='blue')
            hold on
            grid on
            title("Vertical GRF: Step " + segment)
        end
    end
    ylabel("Subno:" + sub)
end

%% Look at C3D files


addpath("C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\ezc3d_matlab")
file_path = "C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\data files\138_HealthyPiG_10.05";
figure
tiledlayout%(12,12, 'Padding', 'none', 'TileSpacing', 'compact'); 



for sub=subs
    n_steps = 0;
    if sub < 10
        sub_folder_name = "SUBJ0" + sub;
    else
        sub_folder_name = "SUBJ" + sub;
    end
    folder_name = fullfile(file_path, sub_folder_name);
    files = dir(folder_name);
    file_names = {files.name};
    file_names = {file_names{contains(file_names, '.c3d')}};
    file_names = {file_names{~contains(file_names, '(0)')}};
    n_trials = length(file_names);
    nexttile
    for i=1:n_trials
        c3d_filename = fullfile(file_path, sub_folder_name, file_names{i});
        [c3d fp] = ezc3dRead(convertStringsToChars(c3d_filename));
        
        for j=1:height(fp)
            n_steps = n_steps + 1;
            data = fp(j).force(3, :);

            plot(data, LineWidth=lw, DisplayName="FP" + j)
            hold on
        end
    end
    disp("Subno: " + sub + " - " + n_steps + " steps")
    ylabel(['Subno:',num2str(sub)])
end