function is_log = is_log_scale(spec)
% IS_LOG = IS_LOG_SCALE(SPEC)
% Whether the response of SPEC is modelled on a log scale. Errors on an unknown
% scale rather than guess which ICC back-transform applies.
%
% Example usage :
%   is_log = PROST.lme.is_log_scale(struct('name', 'log_R_H', 'scale', "log"))

    if ~ismember(spec.scale, ["linear" "log"])
        error("Unknown response scale ""%s"": no ICC back-transform is defined for it.", spec.scale)
    end
    is_log = spec.scale == "log";
end
