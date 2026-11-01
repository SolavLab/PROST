function ICC_original = icc_original_scale(tau2, sigma2)
% ICC_ORIGINAL = ICC_ORIGINAL_SCALE(TAU2, SIGMA2)
% Back-transforms the ICC of a model fitted on log(y) to the scale of y, assuming
% normal random effects and residuals on the log scale (y is lognormal):
%   ICC = (exp(tau2) - 1) / (exp(tau2 + sigma2) - 1)
% Not valid for a model of an untransformed response. Element-wise.
%
% Input :
%   tau2 - participant-level variance on the log scale.
%   sigma2 - residual variance on the log scale.
%
% Example usage :
%   ICC_original = PROST.lme.icc_original_scale(0.070, 0.089)

    ICC_original = (exp(tau2) - 1) ./ (exp(tau2 + sigma2) - 1);
end
