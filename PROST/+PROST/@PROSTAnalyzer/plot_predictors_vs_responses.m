function [fig, correlations] = plot_predictors_vs_responses(obj, predictors_list, responses_list, opts, filt_opts)
%PLOT_PREDICTORS_VS_RESPONSES plots the predictors (anthropometric parameters)
% v.s. the responses (ROS parameters).
% Input :
%   predictors_list - list of anthropometric parameters to plot.
%   responses_list - list of ROS parameters to plot.
%   Name-Value pair options:
%   number_of_axes_in_fig - number of axes per figure to plot.
%   norm_var_name - variable name by which we normalize the responses.
%   show - a value denoting whether to show the figures or save them. Specified 
%          as 'on' or 'off', or as numeric or logical 1 (true) or 0 (false). A 
%          value of 'on' is equivalent to true, and 'off' is equivalent to false.
%               - 'on' - show the figure.
%               - 'off' - save the figure.
%          Default: "on".
%   file_type - the type to save the figure if saved. 
%               Default: 'fig'.
%   append - if show = 'off', whether to append this figure to an existing file
%            with the same name in the file path. Specified as 'on' or 'off', or 
%            as numeric or logical 1 (true) or 0 (false). A value of 'on' is 
%            equivalent to true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: false.
%   Options for filtering the response data:
%   filter - which filter to use for the response data. Either 'outlier' to 
%            filter outlier points, 'winsor' for Winsorizing the data or 'none'.
%            Default: 'none'.
%   filter_options - a struct containing filter-dependent options. 
%                    - When filtering outliers, these are the options for the 
%                    isoutlier function. The Name-Value pairs for the 
%                    function need to be defined under the field 
%                    'NameValues' in the form: NameValues.name = value.
%                    - When Winsorizing, this must contain the percentile
%                    threshold 'p' as a two-element row vector with
%                    elements in the range [0-100].
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
        opts.number_of_axes_in_fig {mustBeScalarOrEmpty, mustBeInteger} = []
        opts.norm_var_name         {mustBeTextScalarOrEmpty} = []
        opts.show                  (1, 1) matlab.lang.OnOffSwitchState = true
        opts.file_type             {mustBeTextScalar, mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"
        opts.append                (1, 1) matlab.lang.OnOffSwitchState = false
        filt_opts.filter           {mustBeMember(filt_opts.filter, ["winsor" "outlier" "none"])} = "none"
        filt_opts.filter_options   struct = []
    end

    % Prep Input Arguments
    if ~isempty(opts.number_of_axes_in_fig) 
        number_of_axes_in_fig = opts.number_of_axes_in_fig; 
    else 
        number_of_axes_in_fig = numel(predictors_list);
    end
    show = opts.show;
    file_type = opts.file_type;
    norm_var_name = opts.norm_var_name;
    append = opts.append;
    filter = filt_opts.filter;

    % Prep Output Arguments
    fig = gobjects(0);
    correlations = struct;
    
    % Get Data
    [predictors, predictor_names, predictor_units, predictor_types] = obj.get_predictors(predictors_list);
    [responses, response_names, response_units, ~] = obj.get_responses(responses_list);
    n_predictors = numel(predictor_names);
    n_responses = numel(response_names);

    % Get Sides
    sides = table2array(obj.get_sample_var("Side"));
    unique_sides = categories(sides);
    n_sides = numel(unique_sides);
    side_color = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT}); % Define colors for sides

    % Get Dataset IDs
    dataset_ids = table2array(obj.get_sample_var("Dataset_id"));
    unique_dataset_ids = unique(dataset_ids)';
    n_dataset_ids = numel(unique_dataset_ids);

    % Start plotting
    axes_counter = 0;
    fig_counter = 0;
    fprintf("Plotting Predictors vs Responses...\n");
   
    for response_index=1:n_responses
        % Get response data
        response = responses{:, response_index};
        response_unit = response_units{response_index};
        response_name = response_names{response_index};
        y = response;
        y_name = replace(response_name, "_", " ");
        y_unit = replace(response_unit, "_", " ");
        
        % Normalize response
        if ~isempty(norm_var_name)
            norm_entry = obj.get_samples(norm_var_name);
            norm_var = PROST.utils.convert_units(table2array(norm_entry), norm_entry.Properties.VariableUnits{:}, response_unit);
            response = response ./ norm_var; % normalized response
            y = response;
            y_name = response_name + " / " + norm_var_name;
            y_unit = "-";
        end

        
        % Filter response outliers / Winsorize
        switch filter
            case "none"
                % ignore filter_opts entirely
            case "winsor"
                % validate Winsor-specific options
                f_opts = filt_opts.filter_options;
                if ~isfield(f_opts, "p")
                    PROST.PROSTError("Winsor", "WrongFilterOptions", "winsor requires 'p' field in filter_opts")
                end
                y = PROST.utils.winsorize(y, f_opts.p);
            case "outlier"
                f_opts = filt_opts.filter_options;

                if isempty(f_opts)
                    mask = isoutlier(y);
                else
                    % Convert name-values
                    name_value = {};
                    if isfield(f_opts, "NameValues")
                        name_value= namedargs2cell(f_opts.NameValues);
                    end
    
                    % validate fields relevant to isoutlier
                    if isfield(f_opts, "movmethod") && strlength(f_opts.movmethod) > 0 % Moving method
                        mustBeMember("window", fields(f_opts));
                        mustBeNonempty(f_opts.window);
                        mask = isoutlier(y, f_opts.movmethod, f_opts.window, name_value{:});
                    elseif isfield(f_opts, "method") && strlength(f_opts.method) > 0 % Outlier method
                        switch f_opts.method
                            case "percentiles"
                                mustBeMember("threshold", fields(f_opts));
                                mustBeNonempty(f_opts.threshold);
                                mask = isoutlier(y, "percentiles", f_opts.threshold, name_value{:});
                            otherwise
                                mask = isoutlier(x, f_opts.method, name_value{:});
                        end
                    else
                        throw(PROST.PROSTError("PlotPredictorsVsResponses", "WrongFilterOptions", "Invalid outlier configuration"));
                    end
                end
                y(mask) = NaN;
        end

        correlations.(response_name) = struct;   
        for predictor_index=1:n_predictors
            % Get predictor data
            predictor = predictors{:, predictor_index};
            predictor_unit = predictor_units{predictor_index};
            predictor_name = predictor_names{predictor_index};
            predictor_type = predictor_types{predictor_index};
            predictor_numeric = (strcmp(predictor_type, "double") || strcmp(predictor_type, "doublenan"));
            x = predictor;
            x_name = replace(predictor_name, "_", " ");
            x_unit = replace(predictor_unit, "_", " ");
            % if (x_unit == "m" || x_unit == "mm") && (y_unit == "m" || y_unit == "mm")
            %     x = PROST.utils.convert_units(x, x_unit, y_unit);
            %     x_unit = y_unit;
            % end
            if ~predictor_numeric
                x = categorical(x);
                x_cateogries = categories(x);
            end

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig_name = "Predictors vs Responses: " + y_name;
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
            if strcmp(predictor_unit, response_unit)
                axis(ax, 'equal');
                pbaspect(ax, [1 1 1]);
            end            

            % Test Predictor-Response Correlations
            correlation_struct = struct;
            if predictor_numeric % Regression and Spearman rank coefficients
                % Spearman rank coefficient
                [rho, pvalue] = corr(x, y, "Type", "Spearman", Rows="complete");
                correlation_struct.Spearman.rho = rho;
                correlation_struct.Spearman.pvalue = pvalue;

                % Pearson coefficient
                [rho, pvalue] = corr(x, y, "Type", "Pearson", Rows="complete");
                correlation_struct.Pearson.rho = rho;
                correlation_struct.Pearson.pvalue = pvalue;
                
                % Rsquared (coefficient of determination)
                correlation_struct.Rsquared = correlation_struct.Pearson.rho.^2;
            else % Wilcoxon rank sum test (equivalent to the Mann-Whitney U-test)
                y1 = y(x == x_cateogries(1));
                y2 = y(x == x_cateogries(2));
                [pvalue, h] = ranksum(y1, y2);
                correlation_struct.Wilcoxon.h = h;
                correlation_struct.Wilcoxon.pvalue = pvalue;
            end % predictor_numeric

            correlations.(response_name).(predictor_name) = correlation_struct;

            % Plot predictors vs responses for both sides
            % directions = dictionary(["right" "left"], ["positive" "negative"]);
            if predictor_numeric
                h_plot = gscatter(ax, x, y, {sides, dataset_ids}, [], obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");
               
                for i_side=1:n_sides
                    for i_dataset=1:n_dataset_ids
                        i = (i_side - 1).*n_dataset_ids + i_dataset;
                        side = unique_sides{i_side};
                        dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
                        h_plot(i).DisplayName = sprintf('%s %s', dataset_name, side);
                        h_plot(i).Color = side_color{side};
                        h_plot(i).MarkerFaceColor = side_color{side};
                        h_plot(i).MarkerEdgeColor = side_color{side};

                    end
                end

                % Regression and Spearman rank coefficients
                if correlations.(response_name).(predictor_name).Rsquared > 0.5
                    plot(ax, x, y_pred, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_DASHED, Color=obj.LINE_COLOR, DisplayName="Linear Regression");
                end
                txt = sprintf(" R^2 = %.2g\n" + ...
                              " Spearman: \\rho = %.2g, p = %.2g", ...
                    correlations.(response_name).(predictor_name).Rsquared, ...
                    correlations.(response_name).(predictor_name).Spearman.rho, ...
                    correlations.(response_name).(predictor_name).Spearman.pvalue);
            else  
                h_plot = violinplot(ax, x, y, GroupByColor=sides);
                for i_side=1:n_sides
                    side = unique_sides{i_side};
                    h_plot(i_side).DisplayName = sprintf('%s', side);
                    % plot_h(i_side).DensityDirection = directions(side);
                    h_plot(i_side).FaceColor = side_color{side};
                    h_plot(i_side).EdgeColor = side_color{side};
                end
                % Wilcoxon \ Mann-Whitney U-test
                txt = sprintf(" Wilcoxon: H = %d, p = %.2g", ...
                    correlations.(response_name).(predictor_name).Wilcoxon.h, ...
                    correlations.(response_name).(predictor_name).Wilcoxon.pvalue);
            end % predictor_numeric

            text(ax, 0.01, 1, txt, ...
                Units="normalized", ...
                FontSize=obj.FONT_SIZE_TEXT, ...
                FontName=obj.FONT_NAME_TEXT, ...
                FontWeight=obj.FONT_WEIGHT_TEXT, ...
                HorizontalAlignment="left", ...
                VerticalAlignment="top", ...
                BackgroundColor="white");
            drawnow

            % Set axis labels
            x_label = x_name;
            x_label = x_label + " [" + x_unit + "]";
            y_label = y_name;
            y_label = y_label +  " [" + y_unit + "]";
            xlabel(ax, x_label);
            ylabel(ax, y_label);

            % Set axis params
            xlim(ax, 'padded');
            ylim(ax, 'padded');

            % Increment counter
            axes_counter = axes_counter + 1;

            % Save figure and create legend
            if axes_counter == number_of_axes_in_fig || (predictor_index==n_predictors)
                % Dummy plots for legend in last axes
                ax1 = axes(Position=ax.Position, Visible="off");
                ax1.FontUnits = "points";
                ax1.FontSize = obj.FONT_SIZE;
                ax1.FontName = obj.FONT_NAME;
                ax1.TitleFontWeight = obj.FONT_WEIGHT;
                ax1.FontWeight = obj.FONT_WEIGHT;
                hold(ax1, "on")
                grid(ax1, "on")
                h_gscatter = gscatter(ax1, nan(1, n_dataset_ids), nan(1, n_dataset_ids), unique_dataset_ids, 'k', obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");
                for i_dataset=1:n_dataset_ids
                     dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
                     h_gscatter(i_dataset).DisplayName = dataset_name;
                end
                h_fill1 =  fill(ax1, nan(1, 4), nan(1, 4), side_color{"right"}, FaceColor=side_color{"right"}, FaceAlpha=0.2, EdgeColor=side_color{"right"}, DisplayName="Right");
                h_fill2 = fill(ax1, nan(1, 4), nan(1, 4), side_color{"left"}, FaceColor=side_color{"left"}, FaceAlpha=0.2, EdgeColor=side_color{"left"}, DisplayName="Left");
                h_dummy = [h_gscatter', h_fill1, h_fill2];

                % Legend
                lgd = legend(ax, h_dummy, Location="layout");
                lgd.Layout.Tile = "east";
                ax1.Visible = "off";
                
                % Save figures
                if ~show
                    drawnow
                    file_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Predictors vs Responses");
                    PROST.PROSTAnalyzer.save_figure(fig(fig_counter), file_path, file_type, append);
                    fprintf("Saved figure...\n")
                end

                % Reset axis counter
                axes_counter = 0;
            end
        end
    end
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