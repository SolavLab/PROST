function stat = lme_refit(boot_data, boot_rows, model)
% STAT = LME_REFIT(BOOT_DATA, BOOT_ROWS, MODEL)
% Statistic of one cluster bootstrap replicate (see PROST.utils.cluster_bootstrap):
% refits MODEL on the resample and returns its parameters. An error of the refit
% propagates, so cluster_bootstrap records it as the reason of a failed replicate.
%
% Input :
%   boot_data - the resampled table, with a new ID per drawn participant
%               (see PROST.utils.cluster_resample).
%   boot_rows - the rows of the table MODEL was fitted on in the resample.
%   model - the fitted LME model.
%
% Output :
%   stat - [beta, tau2, sigma2, ICC]: the fixed effects with the effects-coded
%          last dataset appended, the variance components and ICC1 =
%          tau2 / (tau2 + sigma2) on the model scale.
%
% Example usage :
%   [boot_data, boot_rows] = PROST.utils.cluster_resample(data, PROST.utils.boot_stream(1, 1));
%   stat = PROST.lme.lme_refit(boot_data, boot_rows, lme)

    % Weights follow their rows, so a weighted model stays weighted (all ones if not)
    weights = model.ObservationInfo.Weights(boot_rows);

    lme_boot = fitlme(boot_data, char(model.Formula), ...
        'FitMethod', model.FitMethod, ...
        'Weights', weights, ...
        'DummyVarCoding', 'effects');

    beta_boot = lme_boot.Coefficients.Estimate';
    beta_boot(end + 1) = -sum(beta_boot(2:end));
    [ICC, tau2_boot, sigma2_boot] = PROST.lme.model_metrics(lme_boot, Display="off");
    stat = [beta_boot, tau2_boot, sigma2_boot, ICC(1)];
end
