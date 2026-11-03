% Per-dataset distributions of the radius (R, log R, R_H, log R_H) and the
% horizontal centre coordinate (u_c, u_c_H = u_c/H), with participant-clustered
% bootstrap CIs for the per-dataset median u_c and u_c_H.
% The pooled distributions mix four datasets with different centres, so their
% spread, skewness and kurtosis are reported here within each dataset as well.
% Created by Chen Reichsbouscher 22.10.2026
% ------------------------------------------------------------------------------
clearvars -except -regexp ^Dataset_\d+$ PROSTAnalyzer
close all
clc

save_flag = false; % save the results to Distribution_By_Dataset_Results.mat
boot_seed = 20261006; % same seed as Radius_Mixed_Effects_Model.m (see boot_stream)
n_boot = 5000; % number of bootstrap replicates
R_H_cutoff = 1; % unstable-radius cutoff of Radius_Mixed_Effects_Model.m

if ~exist("PROSTAnalyzer", "var")
    load("PROSTAnalyzer.mat")
end

%% Create Table (one row per leg)
data = table;
data.DatasetID = table2array(PROSTAnalyzer.get_IPD_samples("Dataset_id"));
data.ParticipantID = table2array(PROSTAnalyzer.get_IPD_samples("Participant_id"));
data.u_c = table2array(PROSTAnalyzer.get_IPD_samples("Center_horizontal"));
data.R = table2array(PROSTAnalyzer.get_IPD_samples("Radius"));
predictors = PROSTAnalyzer.get_predictors();
body_height = PROST.utils.convert_units(predictors.Height, "m", "mm");
data.R_H = data.R ./ body_height;
data.log_R_H = log(data.R_H);
data.log_R = log(data.R);
data.u_c_H = data.u_c ./ body_height;

is_stable = data.R_H <= R_H_cutoff;
fprintf("R_H <= %g: %d of %d legs kept (%d excluded)\n", ...
    R_H_cutoff, sum(is_stable), height(data), sum(~is_stable))

%% Summary Statistics per Dataset and Pooled
% RCV is only meaningful for a positive ratio-scale variable: it is reported for
% R and R_H, not for the logs or u_c, whose medians are near zero and can change sign.
specs = struct( ...
    'variable', {'R_H', 'R_H', 'log_R_H', 'u_c', 'u_c', 'R', 'R', 'log_R', 'u_c_H', 'u_c_H'}, ...
    'subset',   {"all", "stable", "stable", "all", "stable", "all", "stable", "stable", "all", "stable"});

dataset_ids = unique(data.DatasetID);
groups = [string(dataset_ids); "Pooled"];
summary = table;
for s = 1:numel(specs)
    spec = specs(s);
    in_subset = true(height(data), 1);
    if spec.subset == "stable"
        in_subset = is_stable;
    end
    for g = 1:numel(groups)
        in_group = in_subset;
        if groups(g) ~= "Pooled"
            in_group = in_group & data.DatasetID == dataset_ids(g);
        end
        x = data.(spec.variable)(in_group);
        st = PROST.PROSTAnalyzer.analyze_stats(x).summary;

        row = table(string(spec.variable), spec.subset, groups(g), st.n, ...
            st.Median, st.IQR, st.Mean, st.SD, NaN, NaN, st.Skewness, st.Kurtosis, NaN, ...
            'VariableNames', {'Variable', 'Subset', 'Dataset', 'n', 'Median', 'IQR', ...
            'Mean', 'SD', 'RCV_Q', 'RCV_M', 'Skewness', 'Kurtosis', 'Pct_posterior'});
        if ismember(spec.variable, ["R_H" "R"])
            row.RCV_Q = st.CV_IQR;
            row.RCV_M = st.CV_MAD;
        end
        if ismember(spec.variable, ["u_c" "u_c_H"])
            row.Pct_posterior = 100 * mean(x < 0);
        end
        summary = [summary; row]; %#ok<AGROW>
    end
end

%% Pooled RCV of R_H and R after Removing the Dataset Centres
% Rescales each leg by its dataset median, so the pooled spread no longer
% contains the between-dataset shift of the centre.
for variable = ["R_H" "R"]
    for subset = ["all", "stable"]
        in_subset = true(height(data), 1);
        if subset == "stable"
            in_subset = is_stable;
        end
        x = data.(variable)(in_subset);
        id = data.DatasetID(in_subset);
        x_centered = x;
        for d = dataset_ids'
            x_centered(id == d) = x(id == d) / median(x(id == d));
        end
        st = PROST.PROSTAnalyzer.analyze_stats(x_centered).summary;
        fprintf("Pooled %s / dataset median (%s legs): RCV_Q = %.1f %%, RCV_M = %.1f %%\n", ...
            variable, subset, st.CV_IQR, st.CV_MAD)
        if variable == "R_H"
            summary_centered.(subset) = st;
        else
            summary_centered_R.(subset) = st;
        end
    end
end

%% Bootstrap CIs of the per-Dataset Median u_c and u_c_H
% Participants are resampled with replacement within each dataset and keep all
% their legs, so the CI accounts for the two legs of a participant being dependent.
u_c_ci = table;
for variable = ["u_c" "u_c_H"]
    for subset = ["all", "stable"]
        in_subset = true(height(data), 1);
        if subset == "stable"
            in_subset = is_stable;
        end
        for d = dataset_ids'
            rows = data(in_subset & data.DatasetID == d, :);
            draws = PROST.utils.cluster_bootstrap(rows, @(boot_data, ~) median(boot_data.(variable)), ...
                n_boot, boot_seed, Strata="");
            ci = prctile(draws, [2.5 97.5]);

            u_c_ci = [u_c_ci; table(variable, subset, d, height(rows), numel(unique(rows.ParticipantID)), ...
                median(rows.(variable)), median(draws), ci(1), ci(2), ...
                'VariableNames', {'Variable', 'Subset', 'Dataset', 'n_legs', 'n_participants', ...
                'Median', 'BootMedian', 'CI_lower', 'CI_upper'})]; %#ok<AGROW>
        end
    end
end

disp(summary)
disp(u_c_ci)

% Distinct variable names, so loading the file next to other results cannot clash
if save_flag
    saved.distribution_summary = summary;
    saved.distribution_summary_centered = summary_centered;
    saved.distribution_summary_centered_R = summary_centered_R;
    saved.distribution_u_c_ci = u_c_ci;
    saved.distribution_settings = struct('boot_seed', boot_seed, 'n_boot', n_boot, ...
        'R_H_cutoff', R_H_cutoff);
    saved.distribution_provenance = PROST.utils.provenance();
    save("Distribution_By_Dataset_Results", "-struct", "saved")
end
