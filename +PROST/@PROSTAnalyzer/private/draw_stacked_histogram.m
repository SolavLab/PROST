function h = draw_stacked_histogram(obj, ax, edges, counts, colors, labels)
%DRAW_STACKED_HISTOGRAM draws precomputed bin counts as a stacked histogram, one
% stack segment per group.
%
% Input :
%   edges - bin edges (1 x n_bins+1), equally spaced.
%   counts - bin counts (n_groups x n_bins).
%   colors - one RGB row per group.
%   labels - display name of each group.
%
% Output :
%   h - the bar series, one per group.
    arguments
        obj
        ax
        edges       (1, :) double
        counts      (:, :) double
        colors      (:, 3) double
        labels      (1, :) string
    end

    centers = edges(1:end - 1) + diff(edges)/2;
    % Bar width 1 makes adjacent bars touch, as in a histogram
    h = bar(ax, centers, counts', 1, "stacked", EdgeColor=obj.LINE_COLOR, LineWidth=obj.BAR_EDGE_WIDTH);
    for k = 1:numel(h)
        h(k).FaceColor = colors(k, :);
        h(k).DisplayName = labels(k);
    end
end
