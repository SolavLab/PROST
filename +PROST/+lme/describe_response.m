function describe_response(data, spec)
% DESCRIBE_RESPONSE(DATA, SPEC)
% Robust descriptive summary of a response, by participant: uses participant-level
% means first to avoid double-weighting participants with bilateral measurements.
% Prints pooled and per-dataset statistics, plots histograms, QQ-plots and a
% boxplot per dataset, and tests homoscedasticity across datasets.
%
% Input :
%   data - the data table of measurements, after the cutoff.
%   spec - struct with fields name (the response column) and scale ("linear"
%          or "log"). The coefficients of variation are printed for "linear" only.
%
% Example usage :
%   PROST.lme.describe_response(data_final, struct('name', 'R', 'scale', "linear"))

    response_name = spec.name;
    is_log = PROST.lme.is_log_scale(spec);

    participantMeans = groupsummary(data, 'ParticipantIDGlobal', 'mean', response_name);

    med_RH  = median(participantMeans.("mean_" + response_name));
    iqr_RH  = iqr(participantMeans.("mean_" + response_name));
    mean_RH = mean(participantMeans.("mean_" + response_name));
    sd_RH   = std(participantMeans.("mean_" + response_name));

    fprintf('Participant-level %s: total median = %.4f, total IQR = %.4f\n', response_name, med_RH, iqr_RH);
    fprintf('Participant-level %s: total mean = %.4f, total SD = %.4f (sensitive to skew, report for completeness)\n', response_name, mean_RH, sd_RH);

    figure
    tl=tiledlayout(2, 4);
    participant_id_global = string(participantMeans.ParticipantIDGlobal);
    for d=["1" "2" "3" "4"]
        mean_per_dataset = participantMeans.("mean_" + response_name)(startsWith(participant_id_global, d));
        fprintf('\n--- Participant-level %s: Dataset %s Stats ---\n', response_name, d)
        fprintf('n = %d\n', numel(mean_per_dataset))
        fprintf('Mean (SD) = %.3f (%.3f)\n', mean(mean_per_dataset), std(mean_per_dataset))
        fprintf('Median (IQR) = %.3f (%.3f)\n', median(mean_per_dataset), iqr(mean_per_dataset))
        % A coefficient of variation needs a ratio scale; on a log scale the
        % mean can be negative and the ratio is meaningless.
        if ~is_log
            fprintf('Coeffcient of Variation = %.3f %%\n', 100*std(mean_per_dataset) / mean(mean_per_dataset))
            fprintf('MAD Coeffcient of Variation = %.3f %%\n', 100*mad(mean_per_dataset, 1) / median(mean_per_dataset))
        end
        fprintf('range = %.3f, min = %.3f, max = %.3f\n', range(mean_per_dataset), min(mean_per_dataset), max(mean_per_dataset))

        nexttile(tl)
        histogram(mean_per_dataset)
        title(sprintf("Participant-level %s: Dataset %s Histogram: Skew = %.3f, Kurtosis = %.3f", response_name, d, skewness(mean_per_dataset), kurtosis(mean_per_dataset)))

        nexttile(tl)
        qqplot(mean_per_dataset)
        title(sprintf("Participant-level %s: Dataset %s QQ-Plot", response_name, d))
    end
    figure
    boxplot(participantMeans.("mean_" + response_name), extract(participant_id_global, 1))
    title(sprintf("Participant-level %s: Boxplot", response_name))
    xlabel("Dataset ID")
    ylabel(response_name)

    [p, stats] = vartestn(participantMeans.("mean_" + response_name), extract(participant_id_global, 1), 'TestType', 'LeveneAbsolute', Display='off');
    fprintf('\n--- Variance Homoscedasticity Tests ---\n')
    fprintf('Levene Absolute: fstat = %.4f, df = [%d %d], p = %.4g\n', stats.fstat, stats.df(1), stats.df(2), p);
    PROST.lme.flignerKilleen(participantMeans.("mean_" + response_name), extract(participant_id_global, 1));
end
