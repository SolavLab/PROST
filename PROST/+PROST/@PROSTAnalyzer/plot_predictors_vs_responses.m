function [fig, correlations] = plot_predictors_vs_responses(obj, predictors_list, responses_list, opts, filt_opts)
%PLOT_PREDICTORS_VS_RESPONSES plots the predictors (anthropometric parameters)
% v.s. the responses (ROS parameters).
% Input :
%   predictors_list - list of anthropometric parameters to plot.
%   responses_list - list of ROS parameters to plot.
%   opts - Name-Value pairs of options for plotting.
%       opts.number_of_axes_in_fig - number of axes per figure to plot.
%       opts.norm_var_name - variable name by which we normalize the responses.
%       opts.show - whether to show the figures or save them. Either "on"
%                   (default) for showing the figures or "off" for saving them.
%       opts.file_type - the type to save the figure if saved.
%       opts.append - Logical 1 (true) to append this figure to "COP Plots".
%                     Logical 0 (false) otherwise.
%                     Appending only works for "pdf" and "gif" file types.
%                     Default: false.
%   filt_opts - options for filtering the response data
%       filt_opts.filter - which filter to use for the response data. Either
%                          "outlier" to filter outlier points, "winsor" for 
%                          Winsorizing the data or "none".
%                          Default: "none".
%       filt_opts.options - a struct containing filter-dependent options. 
%                           When filtering outliers, these are the options for 
%                           the isoutlier function. The Name-Value pairs for the 
%                           function need to be defined under the field 
%                           "NameValues" in the form: NameValues.name = value.
%                           When Winsorizing, this must contain the percentile
%                           threshold "p" as a two-element row vector with
%                           elements in the range [0-100].
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
        opts.show                  {mustBeTextScalar, mustBeMember(opts.show, ["on" "off"])} = "on"
        opts.file_type             {mustBeTextScalar, mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"
        opts.append                (1, 1) logical = false
        filt_opts.filter           {mustBeMember(filt_opts.filter, ["winsor" "outlier" "none"])} = "none"
        filt_opts.options =        []
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

    % Get Dataset IDs
    dataset_ids = table2array(obj.get_sample_var("Dataset_id"));
    unique_dataset_ids = unique(dataset_ids)';
    n_dataset_ids = numel(unique_dataset_ids);

    % Define colors for sides
    color = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});

    % Start plotting
    axes_counter = 0;
    fig_counter = 0;
    if strcmp(show, 'off')
        fprintf("Saving Predictors vs Responses...\n");
    else
        fprintf("Plotting Predictors vs Responses...\n");
    end
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
                f = filt_opts.options;
                if ~isfield(f, "p")
                    PROST.PROSTError("Winsor", "WrongFilterOptions", "winsor requires 'p' field in filter_opts")
                end
                y = PROST.utils.winsorize(y, f.p);
            case "outlier"
                f = filt_opts.options;

                % Convert name-values
                name_value = {};
                if isfield(f, "NameValues")
                    name_value= namedargs2cell(f.NameValues);
                end

                % validate fields relevant to isoutlier
                if isfield(f, "movmethod") && strlength(f.movmethod) > 0 % Moving method
                    mustBeMember("window", fields(f));
                    mustBeNonempty(f.window);
                    mask = isoutlier(y, f.movmethod, f.window, name_value{:});
                elseif isfield(f, "method") && strlength(f.method) > 0 % Outlier method
                    switch f.method
                        case "percentiles"
                            mustBeMember("threshold", fields(f));
                            mustBeNonempty(f.threshold);
                            mask = isoutlier(y, "percentiles", f.threshold, name_value{:});
                        otherwise
                            mask = isoutlier(x, f.method, name_value{:});
                    end
                else
                    PROST.PROSTError("Outlier", "WrongFilterOptions", "Invalid outlier configuration");
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
            if ~predictor_numeric
                x = categorical(x);
                x_cateogries = categories(x);
            end

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                if strcmp(show, "off") && any(strcmp(file_type, ["pdf" "gif"])) && append
                    fig_name = "Predictors vs Responses";
                else
                    fig_name = "Predictors vs Responses: " + response_name + " Plot " + fig_counter;
                end
                fig(fig_counter)  = figure(Name=fig_name, Visible=show);
                tiledlayout(fig(fig_counter), TileSpacing="compact", Padding="compact");
                if strcmp(show, "off")
                    screen_size = get(0, 'ScreenSize');
                    fig(fig_counter).WindowStyle = 'normal';
                    fig(fig_counter).Position = [1 1 0.6*screen_size(3) 0.5*screen_size(4)];
                    
                else
                    sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
                end
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
                        h_plot(i).Color = color{side};
                        h_plot(i).MarkerFaceColor = color{side};
                        h_plot(i).MarkerEdgeColor = color{side};

                    end
                end

                % Regression and Spearman rank coefficients
                if correlations.(response_name).(predictor_name).Rsquared > 0.5
                    plot(ax, x, y_pred, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_DASHED, Color=obj.LINE_COLOR, DisplayName="Linear Regression");
                end
                txt = sprintf(" Rsquared = %.2g\n" + ...
                    " Spearman: rho = %.2g, p-value = %.2g", ...
                    correlations.(response_name).(predictor_name).Rsquared, ...
                    correlations.(response_name).(predictor_name).Spearman.rho, ...
                    correlations.(response_name).(predictor_name).Spearman.pvalue);
            else  
                h_plot = violinplot(ax, x, y, GroupByColor=sides);
                for i_side=1:n_sides
                    side = unique_sides{i_side};
                    h_plot(i_side).DisplayName = sprintf('%s', side);
                    % plot_h(i_side).DensityDirection = directions(side);
                    h_plot(i_side).FaceColor = color{side};
                    h_plot(i_side).EdgeColor = color{side};
                end
                % Wilcoxon \ Mann-Whitney U-test
                txt = sprintf(" Wilcoxon: h = %d, p-value = %.2g", ...
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
                h_fill1 =  fill(ax1, nan(1, 4), nan(1, 4), color{"right"}, FaceColor=color{"right"}, FaceAlpha=0.2, EdgeColor=color{"right"}, DisplayName="Right");
                h_fill2 = fill(ax1, nan(1, 4), nan(1, 4), color{"left"}, FaceColor=color{"left"}, FaceAlpha=0.2, EdgeColor=color{"left"}, DisplayName="Left");
                h_dummy = [h_gscatter', h_fill1, h_fill2];

                % Legend
                lgd = legend(ax, h_dummy, Location="layout");
                lgd.Layout.Tile = "east";
                ax1.Visible = "off";
                
                % Save figures
                if strcmp(show, 'off')
                    drawnow
                    file_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Predictors vs Responses");
                    PROST.PROSTAnalyzer.save_figure(fig(fig_counter), file_path, file_type, append);
                end

                % Reset axis counter
                axes_counter = 0;
            end
        end
    end
    if strcmp(show, 'off')
        fprintf("All figures saved.\n");
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