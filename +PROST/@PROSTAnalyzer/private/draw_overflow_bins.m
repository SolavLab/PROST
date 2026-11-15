function h = draw_overflow_bins(ax, x_lim, bin_width, n_below, n_above, colors, line_width)
%DRAW_OVERFLOW_BINS limits ax to x_lim and draws the observations beyond each
% limit as one hollow overflow bin just past that edge, with an x-tick label
% giving its range (as mplhep's flow="show"). With one row of colors the bin is a
% single hollow histogram bar; with several, a hollow stacked bar with one
% segment per stack, in the stack's colour.
%
% Input :
%   x_lim - [lower upper] limits of the visible bins, on bin edges.
%   bin_width - width of the visible bins; the overflow bins use it too.
%   n_below, n_above - heights of the overflow bins, one element per stack, in
%                      the same scaling as the visible bins.
%   colors - one RGB row per stack.
%   line_width - edge line width of the overflow bins.
%
% Output :
%   h - handles of the overflow bins.
    arguments
        ax
        x_lim           (1, 2) double
        bin_width       (1, 1) double
        n_below         (1, :) double
        n_above         (1, :) double
        colors          (:, 3) double
        line_width      (1, 1) double
    end

    h = gobjects(0);
    gap = bin_width/2;
    full_lim = x_lim;
    overflow_ticks = [];
    overflow_labels = strings(0);
    counts = {n_below n_above};
    symbols = ["<" ">"];
    for s = 1:2
        if sum(counts{s}) == 0
            continue
        end
        edges = sort(x_lim(s) + (2*s - 3)*[gap gap + bin_width]);
        if size(colors, 1) == 1
            h(end + 1) = histogram(ax, BinEdges=edges, BinCounts=counts{s}, ...
                      FaceColor="none", EdgeColor=colors, LineWidth=line_width, ...
                      HandleVisibility="off"); %#ok<AGROW>
        else
            base = 0;
            for k = find(counts{s} > 0)
                h(end + 1) = rectangle(ax, Position=[edges(1) base bin_width counts{s}(k)], ...
                                       EdgeColor=colors(k, :), LineWidth=line_width); %#ok<AGROW>
                base = base + counts{s}(k);
            end
        end
        full_lim(s) = edges(s);
        % Label the bin's range, not its size: a number on the bar would be
        % read against the y-axis, which a count or percentage is not
        overflow_ticks(end + 1) = mean(edges); %#ok<AGROW>
        overflow_labels(end + 1) = sprintf("%s%g", symbols(s), x_lim(s)); %#ok<AGROW>
    end
    xlim(ax, full_lim);

    % Keep ticks off the gaps, which have no x scale, and mark the overflow bins
    % by their ranges
    ticks = ax.XTick;
    ticks = ticks(ticks >= x_lim(1) & ticks <= x_lim(2));
    labels = string(ax.XAxis.TickLabelFormat);
    labels = compose(labels, ticks);
    [ticks, order] = sort([ticks overflow_ticks]);
    labels = [labels overflow_labels];
    ax.XTick = ticks;
    ax.XTickLabel = labels(order);
end
