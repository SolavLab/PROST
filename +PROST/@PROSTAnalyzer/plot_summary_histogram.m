function [fig, summary] = plot_summary_histogram(obj, var_name, normalizer_name, opts, save_opts)
%PLOT_SUMMARY_HISTOGRAM plots a descriptive count histogram of an IPD variable,
% stacked by group (by default, by dataset), with the pooled median and IQR, the
% median and IQR of each group, and reference values (zero, literature). One
% observation per IPD row (leg). No distributions are fitted; for fitting and
% goodness of fit use plot_stats.
%
% Input :
%   var_name - the name of the numeric IPD variable to plot.
%   normalizer_name - the name of the IPD variable to normalize by (e.g.
%                     "Height"). Leave empty for no normalization.
%
% Name-Value pair options :
%   stack_by - the IPD variable whose categories form the stacks.
%              Default: "Dataset_id" (labelled by dataset name).
%   BinMethod - histcounts bin method for the pooled bin edges, shared by all
%               stacks. Default: "fd" (Freedman-Diaconis).
%   coverage - the minimal fraction of observations shown within the x-axis
%              limits, in (0, 1]; the rest are drawn as one stacked overflow
%              bin past each limit. Display only: all statistics use every
%              observation. Default: 1 (full range).
%   group_summary - how each group's median and IQR are shown: "strip" (a
%                   dot-and-whisker row per group above the bars), "lines" (a
%                   vertical line at each group's median) or "none".
%                   Default: "strip".
%   show_literature - whether to draw the literature values that apply to the
%                     variable and normalization (see plot_comparison_values).
%                     Default: true.
%   zero_line - whether to draw a line at zero. Default: true for the signed
%               variables Center_horizontal, Center_vertical, Ang_start and
%               Ang_end, false otherwise.
%   show, append, overwrite, file_type, prepare, prepare_options - the shared
%       figure save options; see plot_stats.
%
% Output :
%   fig - the figure handle.
%   summary - table with one row per group and a final "Pooled" row: N,
%             Median, Q1 and Q3 of the plotted (normalized) values.
    arguments
        obj
        var_name                {mustBeTextScalar}
        normalizer_name         = []
        opts.stack_by           (1, 1) string = "Dataset_id"
        opts.BinMethod          (1, 1) string = "fd"
        opts.coverage           (1, 1) double {mustBeInRange(opts.coverage, 0, 1, "exclude-lower")} = 1
        opts.group_summary      (1, 1) string {mustBeMember(opts.group_summary, ["strip" "lines" "none"])} = "strip"
        opts.show_literature    (1, 1) logical = true
        opts.zero_line          (1, 1) logical = is_signed_variable(var_name)
    end
    arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState =  true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.overwrite      (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, :) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end

    % Data: one value and one group per leg
    [value, value_name, value_units] = get_plot_variable(obj, var_name, normalizer_name);
    group_var = obj.get_IPD_samples(opts.stack_by).(opts.stack_by);
    valid = ~isnan(value);
    value = value(valid);
    group = categorical(group_var(valid));
    groups = categories(group);
    n_groups = numel(groups);
    group_labels = group_display_names(obj, opts.stack_by, groups);

    % Stack colours: the toolbox default colours in a fixed order, so group k
    % keeps its colour when groups are added (blue and light blue last, as they
    % are nearest in hue to the median and IQR). A default equal to the median or
    % IQR colour is skipped. Groups beyond the defaults take MATLAB's lines
    % colormap, which may clash with the defaults or the reference lines.
    defaults = [obj.COLOR_DEFAULT_ORANGE; obj.COLOR_DEFAULT_YELLOW; obj.COLOR_DEFAULT_PURPLE; ...
                obj.COLOR_DEFAULT_GREEN; obj.COLOR_DEFAULT_RED; obj.COLOR_DEFAULT_BLUE; ...
                obj.COLOR_DEFAULT_LIGHTBLUE];
    defaults = defaults(~ismember(defaults, [obj.COLOR_MEDIAN; obj.COLOR_IQR], "rows"), :);
    n_default = min(n_groups, size(defaults, 1));
    colors = [defaults(1:n_default, :); lines(n_groups - n_default)];

    summary = summarize(value, group, groups, group_labels);

    % Figure
    fig_name = "Stat Plots: " + value_name + " - Summary Histogram";
    fig = figure(Name=fig_name, Visible=save_opts.show);
    tl = tiledlayout(fig, 1, 1, TileSpacing="compact", Padding="compact");
    ax = nexttile(tl);
    style_axes(obj, ax);
    title(ax, replace(fig_name, "_", " "));
    xlabel(ax, value_name + " [" + value_units + "]");
    ylabel(ax, "Count of Observations [-]");

    % Reference values first, so the x-limits can keep them in view
    pooled = summary(end, :);
    [h_ref, h_lit] = plot_comparison_values(obj, ax, pooled.Median, [pooled.Q1 pooled.Q3], ...
        normalizer_name, var_name, value_units, ...
        orientation="vertical", ...
        show_zero=opts.zero_line, ...
        show_literature=opts.show_literature);

    % Counts on pooled bin edges, clipped to the coverage window
    ref_lines = [findobj(h_ref, 'flat', 'Type', 'constantline'); h_lit(:)];
    ref_values = arrayfun(@(l) l.Value, ref_lines)';
    [edges, counts, x_lim, n_below, n_above] = binned_counts(value, group, groups, ...
        opts.BinMethod, opts.coverage, ref_values);
    h_bars = draw_stacked_histogram(obj, ax, edges, counts, colors, group_labels);

    % The IQR band stays behind the bars and the reference lines in front: the
    % Layer defaults of ConstantRegion ("bottom") and ConstantLine ("top")

    txt = sprintf(" n = %d", numel(value));
    if ~isempty(x_lim)
        draw_overflow_bins(ax, x_lim, edges(2) - edges(1), n_below, n_above, colors, obj.BAR_EDGE_WIDTH);
        txt = txt + sprintf(" (%d below / %d above x-limits)", sum(n_below), sum(n_above));
    end
    add_n_textbox(obj, ax, txt);

    if opts.group_summary ~= "none"
        draw_group_summary(obj, ax, summary.Median(1:n_groups), ...
            [summary.Q1(1:n_groups) summary.Q3(1:n_groups)], colors, opts.group_summary);
    end

    legend(ax, [h_bars h_ref], Location="best");

    % Save figure
    if ~save_opts.show
        figure_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Stat Plots");
        PROST.utils.save_figure(fig, figure_path, file_type=save_opts.file_type, ...
            append=save_opts.append, overwrite=save_opts.overwrite, ...
            prepare=save_opts.prepare, prepare_options=save_opts.prepare_options);
        fprintf("Saved figure...\n")
    end
end

function labels = group_display_names(obj, stack_by, groups)
%GROUP_DISPLAY_NAMES names each stack: the dataset name for Dataset_id,
% otherwise the category itself.
    labels = string(groups(:)');
    if stack_by == "Dataset_id"
        for k = 1:numel(groups)
            labels(k) = string(obj.get_dataset_name(str2double(groups{k})));
        end
    end
    labels = replace(labels, "_", " ");
end

function summary = summarize(value, group, groups, group_labels)
%SUMMARIZE returns N, median and quartiles per group and pooled (last row). The
% quartiles come from iqr, as in analyze_stats (Table 5).
    names = [group_labels "Pooled"];
    n_rows = numel(names);
    [N, Median, Q1, Q3] = deal(zeros(n_rows, 1));
    for k = 1:n_rows
        if k < n_rows
            v = value(group == groups{k});
        else
            v = value;
        end
        [~, q] = iqr(v);
        N(k) = numel(v);
        Median(k) = median(v);
        Q1(k) = q(1);
        Q3(k) = q(2);
    end
    summary = table(N, Median, Q1, Q3, RowNames=cellstr(names));
end

function [edges, counts, x_lim, n_below, n_above] = binned_counts(value, group, groups, bin_method, coverage, ref_values)
%BINNED_COUNTS bins every group on the pooled bin edges. With coverage < 1 it
% returns the visible edges and counts only, and the per-group counts beyond
% each limit; x_lim lies on bin edges, so every observation is counted exactly
% once. The window is widened to keep ref_values in view.
    [~, edges] = histcounts(value, BinMethod=bin_method);
    width = edges(2) - edges(1);

    x_lim = coverage_limits(value, coverage, true, ref_values);
    if ~isempty(x_lim)
        % Extend the bin grid to the window, in whole bins
        n_lo = max(0, ceil((edges(1) - x_lim(1))/width));
        n_hi = max(0, ceil((x_lim(2) - edges(end))/width));
        edges = [edges(1) - width*(n_lo:-1:1), edges, edges(end) + width*(1:n_hi)];
    end

    n_groups = numel(groups);
    all_counts = zeros(n_groups, numel(edges) - 1);
    for k = 1:n_groups
        all_counts(k, :) = histcounts(value(group == groups{k}), edges);
    end

    if isempty(x_lim)
        counts = all_counts;
        n_below = zeros(1, n_groups);
        n_above = zeros(1, n_groups);
        return
    end

    % Snap outward to bin edges (as plot_stats does)
    i_lo = find(edges <= x_lim(1), 1, 'last');
    i_hi = find(edges >= x_lim(2), 1);
    if isempty(i_lo), i_lo = 1; end
    if isempty(i_hi), i_hi = numel(edges); end
    n_below = sum(all_counts(:, 1:i_lo - 1), 2)';
    n_above = sum(all_counts(:, i_hi:end), 2)';
    counts = all_counts(:, i_lo:i_hi - 1);
    edges = edges(i_lo:i_hi);
    x_lim = edges([1 end]);
end
