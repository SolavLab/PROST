function per_dataset_diagnostics(data, response_name, unit)
% PER_DATASET_DIAGNOSTICS(DATA, RESPONSE_NAME, UNIT)
% Normality of the residuals and random effects, and residuals vs fitted, of the
% per-dataset ICC models (response ~ 1 + (1|ParticipantID), one per dataset).
% With few participants (Dataset 1) the checks have little power.
% UNIT is the unit of the response for the axis labels (default "[-]").
%
% Example usage :
%   PROST.lme.per_dataset_diagnostics(data_final, 'log_R_H')

    if nargin < 3
        unit = "[-]";
    end
    for d = categories(data.DatasetID)'
        data_d = data(data.DatasetID == d{1}, :);
        lme = fitlme(data_d, [response_name ' ~ 1 + (1|ParticipantID)'], 'FitMethod', 'REML');
        name = "Per-dataset ICC model, Dataset " + d{1} + " - " + response_name;
        fprintf('\n===== Diagnostics: %s (%d legs) =====\n', name, height(data_d))
        res = residuals(lme, 'ResidualType', 'Pearson');
        PROST.lme.normality_check(res, name + " Residual [-]", 'anderson')
        PROST.lme.normality_check(randomEffects(lme), name + " Random Effects " + unit, 'anderson')
        figure(Name=name + " Residuals vs Fitted")
        scatter(fitted(lme), res, 15, 'filled')
        yline(0, '--r')
        xlabel("Fitted values " + unit)
        ylabel('Pearson residuals [-]')
        title(name + " Residuals vs Fitted", 'Interpreter', 'none')
    end
end
