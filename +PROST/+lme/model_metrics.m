function [ICC, tau2, sigma2] = model_metrics(model, name, opts)
% [ICC, TAU2, SIGMA2] = MODEL_METRICS(MODEL, NAME)
% Computes metrics of variance components from the Mixed-Effects Model and
% displays them in the command window.
%
% Input :
%   model - the mixed effects model
%   name - the name of the model for printing. "" by default.
%
% Name-Value pair options:
%   Display - whether to display or suppress results to the command line. 
%             Specified as 'on' or 'off', or as numeric or logical 1 (true) or 0 
%             (false). A value of 'on' is equivalent to true, and 'off' is 
%             equivalent to false.
%             - "on" - display (default).
%             - "off" - suppress.
%
%   ICC - Inter-class correlation. The ratio between the random effect component
%         variance and total variance. Returns either ICC1 or [ICC1, ICC2] 
%         according to Bliese 2000:
%           ICC1 = tau^2 / (tau^2 + sigma^2)
%         If model weights exist:
%           ICC2 = tau^2 / (tau^2 + sigma^2 * mean(1./w)), w = weights.
%   tau2 - variance of the random effects component
%   sigma2 - homoscedastic variance of the residual component 
%            (assuming weight = 1).
%
% Example usage :
%   PROST.lme.model_metrics(lme, "LMM");
%   ICC = PROST.lme.model_metrics(lme, "LMM");
%   ICC = PROST.lme.model_metrics(lme, Display="off");
%   [ICC, tau2, sigma2] = PROST.lme.model_metrics(lme, "LMM");


    arguments
        model
        name    (1, 1) string = ""
        opts.Display (1, 1) matlab.lang.OnOffSwitchState = "on"
    end

    [psi, sigma2] = covarianceParameters(model);
    tau2 = psi{1}(1, 1);
    total_variance = tau2 + sigma2;
    ICC1 = tau2 ./ (tau2 + sigma2);
    ICC = ICC1;
    
    weights =  model.ObservationInfo.Weights;
    if any(diff(weights) ~= 0)
        sigma2_avg = sigma2 * mean(1 ./ weights);
        total_variance = tau2 + sigma2_avg;
        ICC2 = tau2 ./ (tau2 + sigma2_avg);
        ICC = [ICC ICC2];
    end

    if opts.Display
        % Display metrics formatted for publication
        fprintf('\n--- %s - Hierarchical Variance Decomposition Metrics ---\n', name);
        fprintf('Participant-Level Variance:                          %8.3f\n', tau2);
        fprintf('Residual-Level Variance (reference with no weights): %8.3f\n', sigma2);
        fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
        fprintf('Total Variance:                                      %8.4f\n', total_variance);
        fprintf('ICC1:                                                %8.4f\n', ICC1);
        if any(diff(weights) ~= 0)
            fprintf('Residual-Level Variance (averaged weights):          %8.3f\n', sigma2_avg);
            fprintf('ICC2:                                                %8.4f\n', ICC2);
        end
    end
end
