function h = draw_group_summary(obj, ax, medians, quartiles, colors, style)
%DRAW_GROUP_SUMMARY marks each group's median and IQR on a histogram whose
% x-axis carries the variable.
%
% Input :
%   medians - one median per group.
%   quartiles - [Q1 Q3], one row per group.
%   colors - one RGB row per group.
%   style - "strip": a dot-and-whisker row per group (dot = median, whisker =
%           IQR) in a band above the bars, which raises the y-limit;
%           "lines": a vertical line at each group's median, in the group's
%           colour (the IQR is not drawn, to keep the bars readable).
%
% Output :
%   h - the drawn objects, one per group.
    arguments
        obj
        ax
        medians     (:, 1) double
        quartiles   (:, 2) double
        colors      (:, 3) double
        style       (1, 1) string {mustBeMember(style, ["strip" "lines"])}
    end

    n_groups = numel(medians);
    h = gobjects(1, n_groups);
    switch style
        case "strip"
            % The band starts above the tallest stack; the y-ticks stay below it,
            % since the band has no count scale
            y_top = ax.YLim(2);
            ticks = ax.YTick;
            step = 0.07*y_top;
            y_rows = y_top + step*(1:n_groups);
            for k = 1:n_groups
                h(k) = errorbar(ax, medians(k), y_rows(k), ...
                    medians(k) - quartiles(k, 1), quartiles(k, 2) - medians(k), "horizontal", ...
                    Color=colors(k, :), ...
                    LineWidth=obj.LINE_WIDTH, ...
                    Marker=obj.MARKER_CIRCLE, ...
                    MarkerSize=obj.MARKER_SIZE, ...
                    MarkerFaceColor=colors(k, :), ...
                    CapSize=0, ...
                    HandleVisibility="off");
            end
            ylim(ax, [ax.YLim(1) y_rows(end) + step]);
            yticks(ax, ticks(ticks <= y_top));
        case "lines"
            for k = 1:n_groups
                h(k) = xline(ax, medians(k), ...
                    Color=colors(k, :), ...
                    LineWidth=obj.LINE_WIDTH, ...
                    LineStyle=obj.LINE_STYLE_SOLID, ...
                    HandleVisibility="off");
            end
    end
end
