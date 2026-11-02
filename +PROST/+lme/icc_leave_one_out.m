function loo = icc_leave_one_out(model, model_name)
% LOO = ICC_LEAVE_ONE_OUT(MODEL, MODEL_NAME)
% Sensitivity of the ICC to single participants: refits MODEL with each
% participant left out in turn, with the same formula, fit method, weights and
% exclusions. Prints the most influential participants and the range of the ICC,
% and plots its distribution. Participants with nearly flat ROS legs just below
% the R_H cutoff can move the ICC much more than the rest.
%
% Input :
%   model - the fitted mixed effects model.
%   model_name - the name of the model for printing.
%
% Output :
%   loo - table with one row per participant: ParticipantIDGlobal, ICC1_Without
%         (ICC1 of the refit without the participant) and Delta_ICC1 (its
%         difference from the ICC1 of MODEL).
%
% Example usage :
%   loo = PROST.lme.icc_leave_one_out(results.log_R.lme, "Final LME - log_R")

    data = model.Variables;
    weight = model.ObservationInfo.Weights;
    excluded = model.ObservationInfo.Excluded;
    formula = model.Formula.char;
    ICC_all = PROST.lme.model_metrics(model, Display="off");
    ICC_all = ICC_all(1);

    participants = unique(data.ParticipantIDGlobal(~excluded));
    ICC_without = nan(numel(participants), 1);
    for k = 1:numel(participants)
        keep = data.ParticipantIDGlobal ~= participants(k);
        lme_k = fitlme(data(keep, :), formula, ...
                       'FitMethod', model.FitMethod, ...
                       'Weights', weight(keep), ...
                       'DummyVarCoding', 'effects', ...
                       'Exclude', excluded(keep));
        ICC_k = PROST.lme.model_metrics(lme_k, Display="off");
        ICC_without(k) = ICC_k(1);
    end

    loo = table(participants, ICC_without, ICC_without - ICC_all, ...
        'VariableNames', {'ParticipantIDGlobal', 'ICC1_Without', 'Delta_ICC1'});
    [~, order] = sort(abs(loo.Delta_ICC1), 'descend');
    fprintf('\n--- %s - Leave-One-Participant-Out ICC1 (ICC1 = %.4f) --- \n', model_name, ICC_all)
    disp(loo(order(1:10), :))
    fprintf('ICC1 range when one participant is left out: %.4f - %.4f\n', min(ICC_without), max(ICC_without));

    figure(Name="Leave-One-Participant-Out ICC: " + model_name)
    histogram(ICC_without, 40);
    xline(ICC_all, 'r', LineWidth=1.5);
    xlabel('ICC(1) without one participant'); ylabel('Participants');
    title("Leave-One-Participant-Out ICC: " + model_name, Interpreter='none');
    grid on
end
