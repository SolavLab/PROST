function [fig, correlations] = plot_predictors_vs_responses(obj, predictors_list, responses_list, opts)
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
% Output :
%   fig - array of figure handles of all the created plots.
%         When figures are saved instead of shown the figures is automatically
%         closed.
    
    arguments
        obj
        predictors_list            {mustBeTextOrEmpty} = []
        responses_list             {mustBeTextOrEmpty} = []
        opts.number_of_axes_in_fig {mustBeScalarOrEmpty, mustBeInteger} = []
        opts.norm_var_name         {mustBeTextScalarOrEmpty} = []
        opts.show                  {mustBeTextScalar, mustBeMember(opts.show, ["on" "off"])} = "on"
        opts.file_type             {mustBeTextScalar, mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"
        opts.append                (1, 1) logical = false
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

    % Prep Output Arguments
    fig = gobjects(0);
    correlations = struct;
    
    % Get Data
    [predictors, predictor_names, predictor_units, predictor_types] = obj.get_features(predictors_list);
    [responses, response_names, response_units, ~] = obj.get_labels(responses_list);
    n_predictors = numel(predictor_names);
    n_responses = numel(response_names);

    % Get Sides
    sides = table2array(obj.get_sample_var("Side"));
    unique_sides = unique(sides);
    n_sides = length(unique_sides);

    % Get Dataset IDs
    dataset_ids = table2array(obj.get_sample_var("Dataset_id"));
    unique_dataset_ids = unique(dataset_ids)';
    n_dataset_ids = length(unique_dataset_ids);

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
        % response_type = response_types{response_index};
        % response_numeric = (strcmp(response_type, "double") || strcmp(response_type, "doublenan"));
        y_name = replace(response_name, "_", " ");
        y_unit = replace(response_unit, "_", " ");
        
        % Normalize response values
        if ~isempty(norm_var_name)
            norm_entry = obj.get_samples(norm_var_name);
            norm_var = PROST.utils.convert_units(table2array(norm_entry), norm_entry.Properties.VariableUnits{:}, response_unit);
            response = response ./ norm_var; % normalized response
            y_name = response_name + " / " + norm_var_name;
            y_unit = "-";
        end

        correlations.(response_name) = struct;   
        for predictor_index=1:n_predictors
            % Get predictor data
            predictor = predictors{:, predictor_index};
            predictor_unit = predictor_units{predictor_index};
            predictor_name = predictor_names{predictor_index};
            predictor_type = predictor_types{predictor_index};
            predictor_numeric = (strcmp(predictor_type, "double") || strcmp(predictor_type, "doublenan"));
            x_name = replace(predictor_name, "_", " ");
            x_unit = replace(predictor_unit, "_", " ");

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
                    sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "), FontUnits="points", FontSize=obj.FONT_SIZE)
                end
            end

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            ax.FontUnits = "points";
            ax.FontSize = obj.FONT_SIZE;
            hold(ax, "on")
            grid(ax, "on")
            if strcmp(predictor_unit, response_unit)
                axis(ax, 'equal');
                pbaspect(ax, [1 1 1]);
            end            

            % Test Predictor-Response Correlations
            correlation_struct = struct([]);
            for i_side=1:n_sides
                i = length(correlation_struct) + 1;
                side = unique_sides(i_side);
                x = predictor(sides == unique_sides(i_side));
                y = response(sides == unique_sides(i_side));
                correlation_struct(i).Side = side;

                if predictor_numeric % Regression and Spearman rank coefficients
                    % Create linear model
                    X = [ones(size(x)), x]; % intercept + predictor
                    b = X \ y; % regression coefficients
                    y_pred = X * b;
                    SSres = sum((y - y_pred).^2);
                    SStot = sum((y - mean(y)).^2);
                    correlation_struct(i).Rsquared = 1 - SSres/SStot;
                    % Spearman rank coefficient
                    [rho, pvalue] = corr(x, y, "Type", "Spearman");
                    correlation_struct(i).Spearman.rho = rho;
                    correlation_struct(i).Spearman.pvalue = pvalue;
                    % Pearson coefficient
                    [rho, pvalue] = corr(x, y, "Type", "Pearson");
                    correlation_struct(i).Pearson.rho = rho;
                    correlation_struct(i).Pearson.pvalue = pvalue;
                else % Wilcoxon rank sum test (equivalent to the Mann-Whitney U-test)
                    x = categorical(x);
                    x_cateogries = categories(x);
                    y1 = y(x == x_cateogries(1));
                    y2 = y(x == x_cateogries(2));
                    [pvalue, h] = ranksum(y1, y2);
                    correlation_struct(i).Wilcoxon.h = h;
                    correlation_struct(i).Wilcoxon.pvalue = pvalue;
                end % predictor_numeric
            end % i_side
            correlations.(response_name).(predictor_name) = correlation_struct;

            % Plot predictors vs responses for both sides
            directions = ["positive" "negative"];
            offset = 0;
            for i_side=1:n_sides
                side = unique_sides(i_side);
                x = predictor(sides == unique_sides(i_side));
                y = response(sides == unique_sides(i_side));
                datasets_per_side = dataset_ids(sides == unique_sides(i_side));

                if predictor_numeric
                    plot_h = gscatter(ax, x, y, datasets_per_side, [], obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");
                    for i_dataset=1:n_dataset_ids
                        side = unique_sides(i_side);
                        dataset_id = unique_dataset_ids(i_dataset);
                        dataset_name = obj.get_dataset_name(dataset_id);
                        plot_h(i_dataset).DisplayName = sprintf('%s %s', dataset_name, side);
                        plot_h(i_dataset).Color = color{side};
                        plot_h(i_dataset).MarkerFaceColor = color{side};
                        plot_h(i_dataset).MarkerEdgeColor = color{side};
                    end % i_dataset

                    % Regression and Spearman rank coefficients
                    if correlations.(response_name).(predictor_name)(i_side).Rsquared > 0.5
                        plot(ax, x, y_pred, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_DASHED, Color=obj.LINE_COLOR, DisplayName="Linear Regression");
                    end
                    txt = sprintf(" Rsquared = %.2g\n" + ...
                                  " Spearman: rho = %.2g, p-value = %.2g", ...
                        correlations.(response_name).(predictor_name)(i_side).Rsquared, ...
                        correlations.(response_name).(predictor_name)(i_side).Spearman.rho, ...
                        correlations.(response_name).(predictor_name)(i_side).Spearman.pvalue);
                else
                    x = categorical(x);
                    plot_h = violinplot(ax, x, y, DensityDirection=directions(i_side));
                    plot_h.DisplayName = sprintf('%s', unique_sides(i_side));
                    plot_h.FaceColor = color{side};
                    plot_h.EdgeColor = color{side};

                    % Wilcoxon \ Mann-Whitney U-test
                    txt = sprintf(" Wilcoxon: h = %d, p-value = %.2g", ...
                        correlations.(response_name).(predictor_name)(i_side).Wilcoxon.h, ...
                        correlations.(response_name).(predictor_name)(i_side).Wilcoxon.pvalue);
                end % predictor_numeric

                txt_handle = text(ax, 0, 1 - offset, txt, ...
                                  Units="normalized", ...
                                  Color=color{side}, ...
                                  FontSize=obj.FONT_SIZE, ...
                                  FontName="FixedWidth", ...
                                  FontWeight=obj.FONT_WEIGHT, ...
                                  HorizontalAlignment="left", ...
                                  VerticalAlignment="top");
                drawnow
                offset = offset + txt_handle.Extent(4);
            end % i_side


            % Set axis labels
            x_label = x_name;
            x_label = x_label + " [" + x_unit + "]";
            y_label = y_name;
            y_label = y_label +  " [" + y_unit + "]";

            % Set axis params
            xlim(ax, 'padded');
            ylim(ax, 'padded');
            xlabel(ax, x_label);
            ylabel(ax, y_label);
            if strcmp(predictor_unit, response_unit)
                axis(ax, 'equal');
            end
            legend(ax, Location="northeast");

            % if predictor_numeric
            %     plot_h = gscatter(ax, predictor, response, {sides, dataset_ids}, [], obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");
            %
            %     % Regression and Spearman rank coefficients
            %     if Rsquared > 0.5
            %         plot(ax, predictor, y_pred, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_DASHED, Color=obj.LINE_COLOR, DisplayName="Linear Regression");
            %     end
            %     txt = sprintf("Rsquared = %.2g\nSpearman: rho = %.2g, p-value = %.2g", ...
            %                   correlations.(response_name).(predictor_name).Rsquared, ...
            %                   correlations.(response_name).(predictor_name).Spearman.rho, ...
            %                   correlations.(response_name).(predictor_name).Spearman.pvalue);
            %     text(ax, ...
            %          0, 1, txt, ...
            %          Units="normalized", ...
            %          Color=obj.LINE_COLOR, ...
            %          FontSize=obj.FONT_SIZE, ...
            %          FontName="FixedWidth", ...
            %          FontWeight=obj.FONT_WEIGHT, ...
            %          HorizontalAlignment="left", ...
            %          VerticalAlignment="top");
            % else
            %     predictor = categorical(predictor);
            %     plot_h = violinplot(predictor, response, GroupByColor=sides);
            % 
            %     % Wilcoxon \ Mann-Whitney U-test
            %     txt = sprintf("Wilcoxon: h = %d, p-value = %.2g", ...
            %                   correlations.(response_name).(predictor_name).Wilcoxon.h, ...
            %                   correlations.(response_name).(predictor_name).Wilcoxon.pvalue);
            %     text(ax, ...
            %          0, 1, txt, ...
            %          Units="normalized", ...
            %          Color=obj.LINE_COLOR, ...
            %          FontSize=obj.FONT_SIZE, ...
            %          FontName="FixedWidth", ...
            %          FontWeight=obj.FONT_WEIGHT, ...
            %          HorizontalAlignment="left", ...
            %          VerticalAlignment="top");
            % end
            % 
            % for i_side=1:n_sides
            %     for i_dataset=1:n_dataset_ids
            %         i = (i_side - 1).*n_dataset_ids + i_dataset;
            %         dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
            %         plot_h(i).DisplayName = sprintf('%s %s', dataset_name, unique_sides(i_side));
            %         plot_h(i).Color = color{unique_sides(i_side)};
            %         plot_h(i).MarkerFaceColor = color{unique_sides(i_side)};
            %         plot_h(i).MarkerEdgeColor = color{unique_sides(i_side)};
            %     end
            % end

            % Increment counter
            axes_counter = axes_counter + 1;

            % Save figure
            if axes_counter == number_of_axes_in_fig || (predictor_index==n_predictors)
                if strcmp(show, 'off')
                    drawnow
                    file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/Predictors vs Responses");
                    PROST.PROSTAnalyzer.save_figure(fig(fig_counter), file_path, file_type, append);
                    close(fig(fig_counter))
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