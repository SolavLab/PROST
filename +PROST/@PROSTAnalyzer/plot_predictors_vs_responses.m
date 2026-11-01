function [fig, correlations] = plot_predictors_vs_responses(obj, predictors_list, responses_list, opts, save_opts, filt_opts)
%PLOT_PREDICTORS_VS_RESPONSES plots the predictors (anthropometric parameters)
% v.s. the responses (ROS parameters).
%
% Input :
%   predictors_list - list of anthropometric parameters to plot. Leave empty to 
%                     plot all predictors.
%   responses_list - list of ROS parameters to plot. Leave empty to plot all 
%                    responses.
%
% Name-Value pair options :
%   number_of_axes_in_fig - number of axes per figure to plot.
%   normalizer_name - variable name by which we normalize the responses.
%   coverage - the minimal fraction of legs shown within the y-axis limits, in
%              (0, 1]; at most floor((1 - coverage)*n) legs fall outside the
%              limits. Legs outside the limits are drawn as open markers on the
%              axis edge. Display only: the correlations are computed on all legs.
%              The limits are one-sided from 0 for non-negative responses and
%              otherwise the shortest window that excludes the most extreme legs
%              in either tail. Use 1 to show all legs. Default: 0.95.
%   show - a value denoting whether to show the figures or save them. Specified 
%          as 'on' or 'off', or as numeric or logical 1 (true) or 0 (false). A 
%          value of 'on' is equivalent to true, and 'off' is equivalent to false.
%               - 'on' - show the figure.
%               - 'off' - save the figure.
%          Default: "on".
%   file_type - the type(s) to save the figure in if saved, as a string or a
%               string array (e.g. ["pdf" "svg" "jpeg" "fig"]). Default: 'fig'.
%   append - if show = 'off', whether to append this figure to an existing file
%            with the same name in the file path. Specified as 'on' or 'off', or 
%            as numeric or logical 1 (true) or 0 (false). A value of 'on' is 
%            equivalent to true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: false.
%   overwrite - whether to replace an existing file with the same name instead
%               of saving a new file with an incremented "_a", "_b", ... suffix.
%               Ignored when append is on. Default: false.
%   filter - the type of filter to use on the data. Either 'none', 'outlier' or
%            'winsor'.
%   filter_options - a struct of filter specific options.
%       'outlier' - the struct contains the isoutlier options in the form:
%                   filter_options.method = "median" / "mean" / "quartiles" /
%                                           "grubbs" / "gesd" / "percentiles".
%                   filter_options.threshold - percentiles threshold.
%                   filter_options.movmethod = "movmedian" / "movmean".
%                   filter_options.window - movmethod window length.
%                   filter_options.dim - operating dimension.
%                   Name-Value pairs need to be under the 'NameValues' field in 
%                   the form: filter_options.NameValues.name = value.
%       'winsor' - the struct contains a single field 'p' of the percentile
%                  threshold as a two-element row vector with elements in the range 
%                  [0-100]: filter_options.p = [a b]. a must be smaller than b.
%
% Output :
%   fig - array of figure handles of all the created plots.
%   correlations - the correlation calculation information for each response and
%                  predictor. Includes Rsquared, Pearson and Spearman
%                  coefficients for numeric data and Wilcoxon test result for
%                  categorical data.
    
    arguments
        obj
        predictors_list            {mustBeTextOrEmpty} = []
        responses_list             {mustBeTextOrEmpty} = []
        opts.normalizer_name       {mustBeTextScalarOrEmpty} = []
        opts.coverage              (1, 1) double {mustBeInRange(opts.coverage, 0, 1, "exclude-lower")} = 0.95
    end
     arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState =  true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.overwrite      (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, :) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end
    arguments
        filt_opts.filter           = "none"
        filt_opts.filter_options   = struct([])
    end

    % Prep Input Arguments
    normalizer_name = opts.normalizer_name;
    coverage = opts.coverage;

    show = save_opts.show;
    file_type = save_opts.file_type;
    append = save_opts.append;
    overwrite = save_opts.overwrite;
    prepare = save_opts.prepare;
    prepare_options = save_opts.prepare_options;

    filter = filt_opts.filter;
    filter_options = filt_opts.filter_options;

    % Prep output arguments
    fig = gobjects(0);
    
    % Get data
    predictors = obj.get_predictors(predictors_list);
    predictor_names = string(predictors.Properties.VariableNames);
    predictor_units = string(predictors.Properties.VariableUnits);
    predictor_types = string(predictors.Properties.VariableTypes);
    n_predictors = numel(predictor_names);

    responses = obj.get_responses(responses_list);
    response_names = string(responses.Properties.VariableNames);
    response_units = string(responses.Properties.VariableUnits);
    response_labels = response_names;
    n_responses = numel(response_names);

    % Separate predictors into numeric and categorical
    idx_numeric_predictor = (strcmp(predictor_types, "double") | strcmp(predictor_types, "doublenan"));

    numeric_predictors = predictors(:, idx_numeric_predictor);
    numeric_predictor_names = predictor_names(idx_numeric_predictor);
    numeric_predictor_units = predictor_units(idx_numeric_predictor);
    n_numeric_predictors = numel(numeric_predictor_names);

    categorical_predictors = predictors(:, ~idx_numeric_predictor);
    categorical_predictor_names = predictor_names(~idx_numeric_predictor);
    n_categorical_predictors = numel(categorical_predictor_names);
    % categorical_predictor_units = strings(1, n_categorical_predictors); %predictor_units(~idx_numeric_predictor);


    % Normalize responses
    if ~isempty(normalizer_name)
        normalizer = obj.get_IPD_samples(normalizer_name);
        normalizer_unit = normalizer.Properties.VariableUnits;
        normalizer = table2array(normalizer);
        normalizer = PROST.utils.convert_units(normalizer, normalizer_unit, response_units);
        responses = responses ./ normalizer; % normalized response
        response_labels = response_labels + " / " + normalizer_name;
        response_units = "-" + strings(size(response_names));
    end

    % Filter outliers / Winsorize from response and compute correlations
    responses = filter_outliers(responses, filter, filter_options);
    correlations = PROST.PROSTAnalyzer.compute_correlations(predictors, responses);

    % Get sides & dataset IDs for plot colors
    sides = table2array(obj.get_IPD_samples_by_variable("Side"));
    unique_sides = categories(sides);
    n_sides = numel(unique_sides);
    side_color = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT}); % Define colors for sides
    violin_directions = dictionary(["right" "left"], ["positive" "negative"]); % Define violin plot directions for sides

    dataset_ids = table2array(obj.get_IPD_samples_by_variable("Dataset_id"));
    unique_dataset_ids = unique(dataset_ids)';
    n_dataset_ids = numel(unique_dataset_ids);

    % Start plotting
    axes_counter = 0;
    fig_counter = 0;
    fprintf("Plotting Predictors vs Responses...\n");
    for r_idx=1:n_responses
        % Get response data
        response_name = response_names{r_idx};
        y = responses{:, r_idx};
        y_unit = response_units(r_idx);
        y_label = replace(response_labels(r_idx) + " [" + y_unit + "]", "_", " ");
        y_median = median(y);
        [~, y_iqr] = iqr(y);

        % Create new figure for new set of axes
        fig_counter = fig_counter + 1;
        fig_name = "Predictors vs Responses: " + response_labels(r_idx);
        fig(fig_counter)  = figure(Name=fig_name, Visible=show);
        n_axes = n_predictors;
        n_cols = ceil(sqrt(n_predictors));
        n_rows = ceil(n_axes / n_cols);
        tl = tiledlayout(fig(fig_counter), n_rows, n_cols, TileSpacing="compact", Padding="compact");
        title(tl, replace(fig(fig_counter).Name, "_", " "), sprintf("Filter: %s", filter), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)

        % Plotting numeric data
        for p_idx=1:n_numeric_predictors
            % Get predictor data
            x = numeric_predictors{:, p_idx};
            x_unit = numeric_predictor_units(p_idx);
            x_label = replace(numeric_predictor_names(p_idx) + " [" + x_unit + "]", "_", " ");

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            ax.FontUnits = "points";
            ax.FontSize = obj.FONT_SIZE;
            ax.FontName = obj.FONT_NAME;
            ax.TitleFontWeight = obj.FONT_WEIGHT;
            ax.FontWeight = obj.FONT_WEIGHT;
            hold(ax, "on")
            grid(ax, "on")
            if strcmp(x_unit, y_unit)
                axis(ax, 'equal');
                pbaspect(ax, [1 1 1]);
            end

            % Plot predictors vs responses for both sides
            h_gscatter = gscatter(ax, x, y, {sides, dataset_ids}, [], obj.MARKERS(1:n_dataset_ids), 1, 'off', "filled");
            for i_side=1:n_sides
                for i_dataset=1:n_dataset_ids
                    i = (i_side - 1).*n_dataset_ids + i_dataset;
                    side = unique_sides{i_side};
                    dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
                    h_gscatter(i).DisplayName = sprintf('%s %s', dataset_name, side);
                    h_gscatter(i).Color = side_color{side};
                    h_gscatter(i).MarkerFaceColor = side_color{side};
                    h_gscatter(i).MarkerEdgeColor = side_color{side};

                end
            end
            
            % Plot values for comparison
            h_compare = plot_comparison_values(obj, ax, y_median, y_iqr, normalizer_name, response_name, y_unit);

            txt = sprintf(" R^2 = %.2g\n" + ...
                          " Spearman: \\rho = %.2g, p = %.2g\n" + ...
                          " Pearson: r = %.2g, p = %.2g", ...
                correlations.(response_name).Numeric.Rsquared(p_idx), ...
                correlations.(response_name).Numeric.Spearman_rho(p_idx), ...
                correlations.(response_name).Numeric.Spearman_p(p_idx), ...
                correlations.(response_name).Numeric.Pearson_r(p_idx), ...
                correlations.(response_name).Numeric.Pearson_p(p_idx));
            text(ax, 0.01, 1, txt, ...
                Units="normalized", ...
                FontSize=obj.FONT_SIZE_TEXT, ...
                FontName=obj.FONT_NAME_TEXT, ...
                FontWeight=obj.FONT_WEIGHT_TEXT, ...
                HorizontalAlignment="left", ...
                VerticalAlignment="top", ...
                BackgroundColor="white");
            drawnow

            % Set axis params
            xlabel(ax, x_label);
            ylabel(ax, y_label);
            xlim(ax, 'padded');
            ylim(ax, 'padded');

            % Increment counter
            axes_counter = axes_counter + 1;
        end % p_idx=1:n_numeric_predictores

        % Plotting categorical data
        for p_idx=1:n_categorical_predictors
            % Get predictor data
            x = categorical(categorical_predictors{:, p_idx});
            x_label = replace(categorical_predictor_names(p_idx), "_", " ");

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig_name = "Predictors vs Responses: " + y_names;
                fig(fig_counter)  = figure(Name=fig_name, Visible=show);
                tl = tiledlayout(fig(fig_counter), TileSpacing="compact", Padding="compact");
                title(tl, replace(fig(fig_counter).Name, "_", " "), sprintf("Filter: %s", filter), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
            end

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            ax.FontUnits = "points";
            ax.FontSize = obj.FONT_SIZE;
            ax.FontName = obj.FONT_NAME;
            ax.TitleFontWeight = obj.FONT_WEIGHT;
            ax.FontWeight = obj.FONT_WEIGHT;
            hold(ax, "on")
            grid(ax, "on")

            % Plot predictors vs responses for both sides
            h_violin = gobjects(n_sides, 1);
            for i_side=1:n_sides
                side = unique_sides{i_side};
                idx = sides == side;
                h_violin(i_side) = violinplot(ax, x(idx), y(idx));
                h_violin(i_side).DisplayName = sprintf('%s', side);
                h_violin(i_side).DensityDirection = violin_directions(side);
                h_violin(i_side).FaceColor = side_color{side};
                h_violin(i_side).EdgeColor = side_color{side};
            end
            
            % Plot values for comparison
            h_compare = plot_comparison_values(obj, ax, y_median, y_iqr, normalizer_name, response_name, y_unit);

            % Wilcoxon \ Mann-Whitney U-test
            txt = sprintf(" Wilcoxon: H = %d, p = %.2g\n r_{rb} = %.2f", ...
                correlations.(response_name).Categorical.Wilcoxon_H(p_idx), ...
                correlations.(response_name).Categorical.Wilcoxon_p(p_idx), ...
                correlations.(response_name).Categorical.Wilcoxon_r_rb(p_idx));
            text(ax, 0.01, 1, txt, ...
                Units="normalized", ...
                FontSize=obj.FONT_SIZE_TEXT, ...
                FontName=obj.FONT_NAME_TEXT, ...
                FontWeight=obj.FONT_WEIGHT_TEXT, ...
                HorizontalAlignment="left", ...
                VerticalAlignment="top", ...
                BackgroundColor="white");
            drawnow

            % Set axis params
            xlabel(ax, x_label);
            ylabel(ax, y_label);
            xlim(ax, 'padded');
            ylim(ax, 'padded');

            % Increment counter
            axes_counter = axes_counter + 1;
        end % p_idx=1:n_categorical_predictores

        % Limit the y-axes to the coverage fraction of legs
        [n_below, n_above] = clip_to_coverage(obj, findobj(tl, 'Type', 'axes'), y, coverage);
        if n_below + n_above > 0
            tl.Subtitle.String = sprintf("Filter: %s | %d legs above / %d below the y-axis limits (coverage %.2g)", ...
                                         filter, n_above, n_below, coverage);
        end

        % Save figure and create legend
        % Dummy plots for legend in last axes
        h_gscatter = gscatter(ax, nan(1, n_dataset_ids), nan(1, n_dataset_ids), unique_dataset_ids, 'k', obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");
        for i_dataset=1:n_dataset_ids
            dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
            h_gscatter(i_dataset).DisplayName = dataset_name;
        end
        h_fill1 = fill(ax, nan(1, 4), nan(1, 4), side_color{"right"}, FaceColor=side_color{"right"}, FaceAlpha=0.2, EdgeColor=side_color{"right"}, DisplayName="Right");
        h_fill2 = fill(ax, nan(1, 4), nan(1, 4), side_color{"left"}, FaceColor=side_color{"left"}, FaceAlpha=0.2, EdgeColor=side_color{"left"}, DisplayName="Left");
     
        h_dummy = [h_gscatter', h_fill1, h_fill2 h_compare];

        % Legend
        lgd = legend(ax, h_dummy, Location="layout");
        lgd.Layout.Tile = axes_counter + 1;
        lgd.NumColumns = 2;

        % Save figures
        if ~show
            drawnow
            file_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Predictors vs Responses");
            PROST.utils.save_figure(fig(fig_counter), file_path, file_type=file_type, append=append, overwrite=overwrite, prepare=prepare, prepare_options=prepare_options);
            fprintf("Saved figure...\n")
        end

        % Reset axis counter
        axes_counter = 0;

    end % r_idx=1:n_responses
end


% --------- helper functions ------------
function mustBeTextScalarOrEmpty(value)
%MUSTBETEXTSCALAROREMPTY Validate that value is single piece of text or an empty
% array.
    if isempty(value)
       return
    end
    mustBeTextScalar(value);    
end

function mustBeTextOrEmpty(value)
%MUSTBETEXTOREMPTY Validate that value is string array, character vector, or
% cell array of character vectors or an empty array.
    if isempty(value)
       return
    end
    mustBeText(value);
end

function h = plot_comparison_values(obj, ax, y_m, y_range, normalizer_name, response_name, y_unit)
    arguments
        obj
        ax
        y_m             (1, 1) double
        y_range         (1, 2) double
        normalizer_name {mustBeTextScalarOrEmpty} = []
        response_name   (1, 1) string = "Radius"
        y_unit          (1, 1) string = "mm"
    end

    h = gobjects(0);
    % Plot 0 value
    h = [h yline(ax, 0, Color=obj.LINE_COLOR, LineWidth=1, DisplayName="Zero")];

    % Plot representative values
    h = [h yline(ax, y_m, Color=obj.COLOR_DEFAULT_BLUE, LineWidth=1, DisplayName="Median")];
    h = [h yregion(y_range(1), y_range(2), FaceAlpha=0.1, FaceColor=obj.COLOR_DEFAULT_BLUE, EdgeColor="none", DisplayName="IQR")];

    % Plot values from literature for comparison
    if ~isempty(normalizer_name) && normalizer_name == "Height"
        paper_colors = orderedcolors("gem");
        paper_colors = paper_colors(2:end, :);

        if response_name == "Radius"
            % Median height-normalised radii of measured ROS of able-bodied walking.
            % Ankle-foot ROS (CoP in the shank, knee-ankle, CS, as in PROST):
            % Hansen & Childress, 2004 (A) "Effects of shoe heel height..." and Hansen
            % & Meier, 2010 "Roll-over shapes of the ankle-foot and knee-ankle-foot
            % systems of able-bodied children". Knee-ankle-foot ROS (CoP in a
            % hip-ankle CS, not directly comparable to PROST): Hansen et al., 2004 (B)
            % "Roll-over shapes of human locomotor systems: effects of walking speed"
            % and Hansen & Childress, 2005 "Effects of adding weight to the torso...".
            hansen_effects_2004_radius = 0.19;
            hansen_roll_over_2010_radius = 0.22;
            hansen_roll_over_2004_radius = 0.15;
            hansen_effects_2005_radius = 0.16;

            h = [h yline(ax, hansen_effects_2004_radius,   Color=paper_colors(1, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2004 (A)")];
            h = [h yline(ax, hansen_roll_over_2010_radius, Color=paper_colors(2, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2010")];
            h = [h yline(ax, hansen_roll_over_2004_radius, Color=paper_colors(3, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2004 (B)")];
            h = [h yline(ax, hansen_effects_2005_radius,   Color=paper_colors(4, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2005")];
        elseif response_name == "Center_horizontal"
            % Median height-normalised centre horizontal coordinates of measured
            % knee-ankle-foot ROS of able-bodied walking (CoP in a hip-ankle CS, not
            % directly comparable to the shank-based PROST ankle-foot ROS): Hansen et
            % al., 2004 (B) "Roll-over shapes of human locomotor systems: effects of
            % walking speed" and Hansen & Childress, 2005 "Effects of adding weight to
            % the torso...".
            hansen_roll_over_2004_center_hor = 0.006;
            hansen_effects_2005_center_hor = 0.011;

            h = [h yline(ax, hansen_roll_over_2004_center_hor, Color=paper_colors(1, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2004 (B)")];
            h = [h yline(ax, hansen_effects_2005_center_hor,   Color=paper_colors(2, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Hansen, 2005")];
        end
    elseif isempty(normalizer_name) && response_name == "Center_horizontal"
        paper_colors = orderedcolors("gem");
        paper_colors = paper_colors(2:end, :);

        % Arc-centre offsets anterior to the tibial axis imposed on rigid arc feet
        % (design values, not measured ROS): Adamczyk et al., 2006, p. 3957 and
        % Adamczyk & Kuo, 2013, p. 2725. In m:
        adamczyk_advantages_2006_center_hor = 0.076;
        adamczyk_mechanical_2013_center_hor = 0.058;
        to_unit = @(v) PROST.utils.convert_units(v, "m", y_unit);

        h = [h yline(ax, to_unit(adamczyk_advantages_2006_center_hor), Color=paper_colors(1, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Adamczyk, 2006")];
        h = [h yline(ax, to_unit(adamczyk_mechanical_2013_center_hor), Color=paper_colors(2, :), Linewidth=1, LineStyle=obj.LINE_STYLE_DASHED, DisplayName="Adamczyk, 2013")];
    end
end

function [n_below, n_above] = clip_to_coverage(obj, axs, y, coverage)
%CLIP_TO_COVERAGE sets common y-axis limits on axs that show at least the
% coverage fraction of y, and draws the markers outside them as open markers on
% the axis edge. One-sided from 0 for non-negative y, otherwise the shortest
% window of the coverage fraction, wherever the excluded samples fall. The
% limits are widened to keep the comparison lines in view and rounded outward to
% a round step. At most floor((1 - coverage)*n) samples fall outside the limits.
% Changes only the display, never the plotted statistics.
    lines = findobj(axs, 'Type', 'constantline', 'InterceptAxis', 'y');
    [lim, n_below, n_above] = coverage_limits(y, coverage, false, [lines.Value]);
    if isempty(lim)
        return
    end
    for ax = axs(:)'
        markers = findobj(ax, 'Type', 'line');
        markers = markers(~strcmp(get(markers, {'Marker'}), 'none'));
        for l = markers'
            out = l.YData < lim(1) | l.YData > lim(2);
            if ~any(out)
                continue
            end
            line(ax, l.XData(out), min(max(l.YData(out), lim(1)), lim(2)), ...
                 LineStyle="none", Marker=l.Marker, MarkerSize=obj.MARKER_SIZE, ...
                 MarkerEdgeColor=l.Color, MarkerFaceColor="none", Clipping="off", ...
                 HandleVisibility="off");
            l.YData(out) = NaN;
        end
        ylim(ax, lim);
    end
end