function stat = covariate_refit(boot_data, lme, lme_base)
% STAT = COVARIATE_REFIT(BOOT_DATA, LME, LME_BASE)
% Statistic of one bootstrap replicate of a covariate model: [beta, tau2, sigma2,
% ICC, pseudo_R2]. pseudo_R2 is NaN without a baseline (LME_BASE = []). The models
% are unweighted, so no weights are carried over.
%
% Example usage :
%   stat = PROST.lme.covariate_refit(boot_data, lme, lme_base)

    lme_boot = fitlme(boot_data, char(lme.Formula), 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
    [ICC, tau2, sigma2] = PROST.lme.model_metrics(lme_boot, Display="off");
    pseudo_R2 = NaN;
    if ~isempty(lme_base)
        lme_base_boot = fitlme(boot_data, char(lme_base.Formula), 'FitMethod', 'REML', 'DummyVarCoding', 'effects');
        [~, tau2_base] = PROST.lme.model_metrics(lme_base_boot, Display="off");
        pseudo_R2 = 1 - tau2 / tau2_base;
    end
    stat = [lme_boot.Coefficients.Estimate', tau2, sigma2, ICC(1), pseudo_R2];
end
