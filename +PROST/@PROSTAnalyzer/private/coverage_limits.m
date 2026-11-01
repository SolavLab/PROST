function [lim, n_below, n_above] = coverage_limits(values, coverage, two_sided, extra_values)
%COVERAGE_LIMITS returns axis limits that show at least the coverage fraction of
% values. One-sided from 0 for non-negative values unless two_sided is true,
% otherwise the shortest window of the coverage fraction, wherever the excluded
% samples fall. The limits are widened to keep extra_values (e.g. comparison
% lines) in view and rounded outward to a round step. At most
% floor((1 - coverage)*n) samples fall outside the limits. Returns empty lim when
% coverage is 1 or there are no values.
    arguments
        values          double
        coverage        (1, 1) double
        two_sided       (1, 1) logical = false
        extra_values    double = []
    end

    values = values(~isnan(values));
    lim = [];
    n_below = 0;
    n_above = 0;
    if coverage == 1 || isempty(values)
        return
    end

    % Order statistics, so at most floor((1 - coverage)*n) samples fall outside
    values = sort(values(:));
    n = numel(values);
    n_out = floor((1 - coverage)*n);
    if values(1) >= 0 && ~two_sided
        lim = [0 values(n - n_out)];
    else
        % Shortest window holding n - n_out samples: the excluded samples are the
        % most extreme ones, split between the tails as the data dictate
        width = values(n - n_out:n) - values(1:n_out + 1);
        [~, i_start] = min(width);
        lim = [values(i_start) values(i_start + n - n_out - 1)];
    end
    lim = [min([lim(1) extra_values(:)']) max([lim(2) extra_values(:)'])];

    % Round outward to a 1-2-2.5-5 step giving about 6 intervals, independent of
    % the figure size. Widening only reduces the number of samples outside.
    raw_step = diff(lim)/6;
    magnitude = 10^floor(log10(raw_step));
    nice_steps = [1 2 2.5 5 10]*magnitude;
    tick_step = nice_steps(find(nice_steps >= raw_step, 1));
    lim = [floor(lim(1)/tick_step) ceil(lim(2)/tick_step)]*tick_step;

    n_below = sum(values < lim(1));
    n_above = sum(values > lim(2));
end
