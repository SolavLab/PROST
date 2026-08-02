% Count the number of participants, limbs and steps and the valid ones
% Created by Chen Reichsbouscher 23.04.2026
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$ PROSTAnalyzer
close all
clc

if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end
for d=1:4
    if ~exist("Dataset_" + d, "var")
        load("./example_datasets/Dataset_"+ d + ".mat")
    end
end

%% Number of Participants and Steps
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

%% Number of limbs
fprintf("\n--- Preprocessed Data ---\n")
for d=1:4
    DB = eval("Dataset_" + d);
    n_participants = numel(fieldnames(DB.Data));
    right_side = false(1, n_participants);
    left_side = false(1, n_participants);

    for p=1:n_participants
        trials = [DB.Data.("participant_" + p).processed_original_data.trial];
        trial_fields = fieldnames(trials);
        step_idx = contains(trial_fields, "step");
        step_fields = trial_fields(step_idx);
        for s=1:numel(step_fields)
            steps = [trials.(step_fields{s})];
            feet = [steps.foot];
            if ~right_side(p)
                right_side(p) = ismember("right", feet);
            end
            if ~left_side(p)
                left_side(p) = ismember("left", feet);
            end
            if left_side(p) & right_side(p)
                break
            end
        end
    end

    fprintf("Dataset %d: num Left: %d, num right: %d, total: %d\n",d, sum(left_side), sum(right_side), sum(left_side) + sum(right_side))
end

fprintf("\n--- Uniform Data ---\n")
for dd = 1:4
    n_participants = numel(PROSTAnalyzer.DataRecords(dd).Data);
    right_side = false(1, n_participants);
    left_side = false(1, n_participants);
    for pp=1:n_participants
        if PROSTAnalyzer.DataRecords(dd).Data(pp).Is_included
            left_side(pp) = PROSTAnalyzer.DataRecords(dd).Data(pp).Uniform_data.left.Is_included;
            right_side(pp) = PROSTAnalyzer.DataRecords(dd).Data(pp).Uniform_data.right.Is_included;
        end
    end
    fprintf("Dataset %d: num Left: %d, num right: %d, total: %d\n",dd, sum(left_side), sum(right_side), sum(left_side) + sum(right_side))

end