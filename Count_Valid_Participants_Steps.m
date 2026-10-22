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

%% Walking speed of valid steps
% Measured speed of the steps entering the fit (included participant, side
% and step). Speed is a trial property copied into each of its steps, so
% step-level statistics weight participants by their step counts; the
% participant-level mean +- SD is printed alongside for that reason.
dataset_col = [];
participant_col = [];
category_col = strings(0, 1);
speed_col = [];
for dd = 1:numel(PROSTAnalyzer.DataRecords)
    data = PROSTAnalyzer.DataRecords(dd).Data;
    for pp = 1:numel(data)
        if ~data(pp).Is_included
            continue
        end
        for side = ["right", "left"]
            if ~data(pp).Uniform_data.(side).Is_included
                continue
            end
            steps = data(pp).Uniform_data.(side).step;
            steps = steps([steps.Is_included]);
            speeds = [steps.speed];
            n_steps = numel(steps);
            dataset_col = [dataset_col; repmat(PROSTAnalyzer.DataRecords(dd).Dataset_id, n_steps, 1)]; %#ok<AGROW>
            participant_col = [participant_col; repmat(pp, n_steps, 1)]; %#ok<AGROW>
            category_col = [category_col; string({speeds.speed_category})']; %#ok<AGROW>
            speed_col = [speed_col; [speeds.value]']; %#ok<AGROW>
        end
    end
end
speed_table = table(dataset_col, participant_col, category_col, speed_col, ...
    VariableNames=["Dataset_id", "Participant", "Speed_category", "Speed"]);

fprintf("\n--- Walking speed of valid steps [km/h] ---\n")
fprintf("NaN speeds: %d of %d steps\n", sum(isnan(speed_table.Speed)), height(speed_table))
for dd = [unique(speed_table.Dataset_id)' 0]
    if dd == 0
        rows = true(height(speed_table), 1);
        label = "Total";
    else
        rows = speed_table.Dataset_id == dd;
        label = "Dataset " + dd;
    end
    v = speed_table.Speed(rows);
    participant_means = groupsummary(speed_table(rows, :), ["Dataset_id", "Participant"], "mean", "Speed").mean_Speed;
    fprintf("%s: n = %d steps, %.2f +- %.2f (%.2f-%.2f); participant level: %.2f +- %.2f (n = %d)\n", ...
        label, numel(v), mean(v, "omitnan"), std(v, "omitnan"), min(v), max(v), ...
        mean(participant_means, "omitnan"), std(participant_means, "omitnan"), numel(participant_means))
end

fprintf("\nPer speed category:\n")
category_summary = groupsummary(speed_table, ["Dataset_id", "Speed_category"], ["mean", "std", "min", "max"], "Speed");
disp(category_summary)