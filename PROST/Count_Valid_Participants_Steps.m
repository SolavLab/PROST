% Count the number of participants and steps and the valid ones
% Created by Chen Reichsbouscher 23.04.2026
% ------------------------------------------------------------------------------
clearvars -except PROSTAnalyzer
close all
clc
%%
disp("Total number of participants: " + sum([PROSTAnalyzer.SummaryTable.N_participants]))
disp("Total number of included participants: " + sum([PROSTAnalyzer.SummaryTable.N_participants_included]))
disp("Total number of steps: " + sum([PROSTAnalyzer.SummaryTable.N_steps]))
disp("Total number of included steps: " + sum([PROSTAnalyzer.SummaryTable.N_steps_included]))
disp("Steps per participant (mean +- std):")
disp("------------------------------------")
for d=1:numel(PROSTAnalyzer.DataRecords)
    dataset = PROSTAnalyzer.DataRecords(d);
    dataset_id = dataset.Dataset_id;
    fprintf("Dataset %d: %.2f +- %2.f\n", dataset_id, PROSTAnalyzer.SummaryTable.Steps_pp_mean(d), PROSTAnalyzer.SummaryTable.Steps_pp_std(d))
end