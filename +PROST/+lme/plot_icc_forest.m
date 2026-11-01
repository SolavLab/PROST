function plot_icc_forest(results, spec)
% PLOT_ICC_FOREST(RESULTS, SPEC)
% Forest plot of the per-dataset ICCs with their bootstrap CIs, and the pooled
% ICC of the final model below them. Marker area is proportional to the number of
% participants. CIs are drawn only when the bootstrap was run.
%
% Input :
%   results - the results of one response: fields ICC, per_dataset, and
%             optionally boot (the pooled bootstrap).
%   spec - struct with fields name and scale.
%
% Example usage :
%   PROST.lme.plot_icc_forest(results.log_R_H, struct('name', 'log_R_H', 'scale', "log"))

    T = results.per_dataset.table;
    n_datasets = height(T);
    has_ci = ismember('ICC_CI_lower', T.Properties.VariableNames);

    % Undocked at the paper aspect ratio: prep_figure_for_publish scales the height
    % with the width, so a docked window would give the dock's aspect ratio
    figure(Name="Final LME - " + spec.name + ": Per-Dataset ICC", WindowStyle="normal", ...
           Units="points", Position=[0 0 468 170])
    hold on
    y = n_datasets + 1:-1:2;
    if has_ci
        errorbar(T.ICC, y, [], [], T.ICC - T.ICC_CI_lower, T.ICC_CI_upper - T.ICC, ...
                 'k', 'LineStyle', 'none', 'CapSize', 0, 'LineWidth', 0.75)
    end
    scatter(T.ICC, y, 12 + 0.6*T.n_participants, 'k', 's', 'filled')

    % Pooled ICC: final model, dataset fixed effect
    pooled = results.ICC;
    if isfield(results, 'boot')
        ci = results.boot.boot_inferences{'ICC', {'CI_lower', 'CI_upper'}};
        patch([ci(1) pooled ci(2) pooled], [1 1.25 1 0.75], 'k')
    else
        plot(pooled, 1, 'kd', 'MarkerFaceColor', 'k')
    end
    xline(pooled, ':')

    % participants / legs, so the published figure needs no title or legend
    labels = ["Dataset " + T.DatasetID + " (" + T.n_participants + " / " + T.n_legs + ")"; ...
              "Pooled (" + sum(T.n_participants) + " / " + sum(T.n_legs) + ")"];
    yticks(1:n_datasets + 1)
    yticklabels(flip(labels))
    ylim([0.4 n_datasets + 1.6])
    xlim([0 1])
    if PROST.lme.is_log_scale(spec)
        xlabel('ICC_{log}')
    else
        xlabel('ICC')
    end
    title(sprintf("Per-dataset ICC - %s", spec.name), 'Interpreter', 'none')
    box on
    hold off
end
