function [fig, speed_table] = plot_speed_distribution(obj, dataset_ids, opts, save_opts)
%PLOT_SPEED_DISTRIBUTION plots histograms of the measured walking speed of the
% valid steps, one tile per dataset. Datasets listed in by_category are split by
% their source speed condition, with optional reference marks for the nominal
% speed of each condition.
%
% Input :
%   dataset_ids - the IDs of the datasets to plot. Default: all datasets.
%
% Name-Value pair options :
%   by_category - the IDs of the datasets to plot separately for each speed
%                 category, one overlaid histogram per category ordered by its
%                 mean measured speed. Default: [] (no dataset is split).
%   reference - a dictionary mapping a speed category to its nominal speed
%               [km/hour], marked in the matching colour on the split datasets.
%               A scalar value is drawn as a dashed vertical line, and a cell
%               holding a [lower upper] vector as a shaded band. For example:
%               dictionary(["V1" "C1"], {1.0, [0 1.44]}). Categories that are
%               missing from the dictionary get no mark. Default: no marks.
%   bin_width - the histogram bin width [km/hour]. Default: 0.25.
%   x_limits - the speed axis limits [km/hour], shared by all tiles.
%              Default: [0, the maximum speed rounded up to bin_width].
%   show - a value denoting whether to show the figure or save it. Specified
%          as 'on' or 'off', or as numeric or logical 1 (true) or 0 (false).
%               - 'on' - show the figure.
%               - 'off' - save the figure.
%          Default: "on".
%   file_type - the type(s) to save the figure in if saved, as a string or a
%               string array (e.g. ["pdf" "svg" "jpeg" "fig"]). Default: 'fig'.
%   append - if show = 'off', whether to append this figure to an existing file
%            with the same name in the file path. Default: false.
%   overwrite - whether to replace an existing file with the same name instead
%               of saving a new file with an incremented "_a", "_b", ... suffix.
%               Ignored when append is on. Default: false.
%   prepare - if show = 'off', whether to prepare the figure for publication
%             when saving (see prep_figure_for_publish utils function).
%             Default: true.
%   prepare_options - if prepare = "on", options for paper preparation (see
%                     prep_figure_for_publish utils function).
%
% Output :
%   fig - the figure handle.
%   speed_table - the plotted data, as returned by get_step_speeds.

    arguments
        obj
        dataset_ids             (1, :) double = [obj.DataRecords.Dataset_id]
        opts.by_category        (1, :) double = []
        opts.reference          dictionary = dictionary(string.empty, {})
        opts.bin_width          (1, 1) double {mustBePositive} = 0.25
        opts.x_limits           (1, :) double = []
    end
    arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.overwrite      (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, :) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end

    speed_table = obj.get_step_speeds(dataset_ids);

    x_limits = opts.x_limits;
    if isempty(x_limits)
        x_limits = [0, opts.bin_width*ceil(max(speed_table.Speed)/opts.bin_width)];
    end
    edges = x_limits(1):opts.bin_width:x_limits(2);

    fig = figure(Name="Stat Plots: Speed Distribution", Visible=save_opts.show);
    tl = tiledlayout(fig, "flow", TileSpacing="compact", Padding="compact");
    for dataset_id = dataset_ids
        ax = nexttile(tl);
        hold(ax, "on")
        rows = speed_table.Dataset_id == dataset_id;

        if ismember(dataset_id, opts.by_category)
            % Order the categories by their mean measured speed, so colours
            % run from the slowest to the fastest condition.
            category_means = groupsummary(speed_table(rows, :), "Speed_category", "mean", "Speed");
            category_means = sortrows(category_means, "mean_Speed");
            categories = category_means.Speed_category';
            colors = ax.ColorOrder;
            for k = 1:numel(categories)
                color = colors(mod(k - 1, size(colors, 1)) + 1, :);
                if isKey(opts.reference, categories(k))
                    nominal = opts.reference{categories(k)};
                    if isscalar(nominal)
                        xline(ax, nominal, "--", Color=color, LineWidth=obj.LINE_WIDTH, HandleVisibility="off");
                    else
                        xregion(ax, nominal(1), nominal(2), FaceColor=color, FaceAlpha=0.12, HandleVisibility="off");
                    end
                end
                histogram(ax, speed_table.Speed(rows & speed_table.Speed_category == categories(k)), edges, ...
                    FaceColor=color, DisplayName=categories(k));
            end
            legend(ax, Location="northeast");
        else
            histogram(ax, speed_table.Speed(rows), edges);
        end

        title(ax, obj.get_dataset_name(dataset_id))
        xlim(ax, x_limits)
        grid(ax, "on")
        ax.FontSize = obj.FONT_SIZE;
        ax.FontName = obj.FONT_NAME;
    end
    % Axis labels on the outer tiles only (axes labels, unlike tiledlayout
    % labels, are resized by prep_figure_for_publish)
    drawnow
    n_cols = tl.GridSize(2);
    axs = flip(findobj(tl.Children, Type="axes"))';
    n_tiles = numel(axs);
    for k = 1:n_tiles
        if mod(k - 1, n_cols) == 0
            ylabel(axs(k), "Number of steps")
        end
        if k > n_tiles - n_cols
            xlabel(axs(k), "Speed [km/h]")
        end
    end

    % Save figure
    if ~save_opts.show
        figure_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Stat Plots");
        PROST.utils.save_figure(fig, figure_path, file_type=save_opts.file_type, append=save_opts.append, ...
            overwrite=save_opts.overwrite, prepare=save_opts.prepare, prepare_options=save_opts.prepare_options);
        fprintf("Saved figures...\n")
    end
end
