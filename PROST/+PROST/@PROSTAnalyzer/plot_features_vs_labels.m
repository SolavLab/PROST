function plot_features_vs_labels(obj, features_list, labels_list, number_of_axes_in_fig, norm_var_name, show, file_type)
%PLOT_FEATURES_VS_LABELS plots the features (anthropometric parameters)
% v.s. the labels (ROS parameters).
% Input :
%   features_list - list of anthropometric parameters to plot.
%   labels_list - list of ROS parameters to plot.
%   number_of_axes_in_fig - number of axes per figure to plot.
%   norm_var_name - variable name by which we normalize the labels.
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.

    % Prep Input Arguments
    if nargin < 7
        file_type = [];
    end
    if nargin < 6 || isempty(show)
        show = 'on';
    end
    if nargin < 5
        norm_var_name = [];
    end
    if nargin < 3
        labels_list = {};
    end
    if nargin < 2
        features_list = {};
    end

    % Get Data
    [features, feature_names, feature_units, feature_types] = obj.get_features(features_list);
    [labels, label_names, label_units, label_types] = obj.get_labels(labels_list);
    n_features = numel(feature_names);
    n_labels = numel(label_names);

    % Prep Input Arguments
    if nargin < 4 || isempty(number_of_axes_in_fig)
        number_of_axes_in_fig = length(label_names);
    end

    % Get Sides
    sides = table2array(obj.get_sample_var("Side"));
    unique_sides = unique(sides);
    n_sides =  length(unique_sides);

    % Get Dataset IDs
    dataset_ids = table2array(obj.get_sample_var("Dataset_id"));
    unique_dataset_ids = unique(dataset_ids)';
    n_dataset_ids = length(unique_dataset_ids);

    % dataset_ids_left = dataset_ids(sides == "left");
    % dataset_ids_right = dataset_ids(sides == "right");
    % unique_dataset_ids_left = unique(dataset_ids_left)';
    % unique_dataset_ids_right = unique(dataset_ids_right)';
    % n_dataset_ids_left = length(unique_dataset_ids_left);
    % n_dataset_ids_right = length(unique_dataset_ids_right);

    % % Get Residuals
    % residuals = table2array(obj.get_sample_var("Residual"));
    %
    % % Normalize inverse residuals for reasonable marker sizes
    % inv_residuals  = 1 ./ residuals;
    % norm_inv_residuals = (inv_residuals  / max(inv_residuals));
    %
    % % Scale marker sizes (adjust 200 as needed)
    % sz_residuals  = obj.MARKER_SIZE_SCATTER * norm_inv_residuals;

    % Define colors for sides
    color = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});

    % Start plotting
    axes_counter = 0;
    fig_counter = 0;
    if strcmp(show, 'off')
        fprintf("Saving Features vs Labels...\n");
    else
        fprintf("Plotting Features vs Labels...\n");
    end
    for feature_index=1:n_features
        for label_index=1:n_labels
            % Get feature data
            x = features{:, feature_index};
            x_unit = replace(feature_units{feature_index}, "_", " ");
            x_name = replace(feature_names{feature_index}, "_", " ");
            x_type = feature_types{feature_index};
            x_numeric = (strcmp(x_type, "double") || strcmp(x_type, "doublenan"));

            % Get label data
            y = labels{:, label_index};
            y_unit = replace(label_units{label_index}, "_", " ");
            y_name = replace(label_names{label_index}, "_", " ");
            y_type = label_types{label_index};
            y_numeric = (strcmp(y_type, "double") || strcmp(y_type, "doublenan"));

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig  = figure(Name="Features vs Labels: " + x_name + " vs " + strjoin(replace(label_names, "_", " "), ", ") + " Plot " + fig_counter, Visible=show);
                tiledlayout(fig)
                sgtitle(fig, fig.Name)
            end

            % Initialize axis
            ax = nexttile;
            hold(ax, "on");

            % Set axis labels
            x_label = x_name;
            if ~isempty(x_unit)
                x_label = x_label + " [" + x_unit + "]";
            end
            y_label = y_name;
            if ~isempty(y_unit)
                y_label = y_label +  " [" + y_unit + "]";
            end

            % Calculate linear regression if numeric
            if y_numeric
                if ~isempty(norm_var_name)
                    % Normalize label values
                    norm_entry = obj.get_samples(norm_var_name);
                    norm_var = PROST.utils.convert_units(table2array(norm_entry), norm_entry.Properties.VariableUnits{:}, "mm");
                    y = y ./ norm_var; % normalized label
                    y_label = y_name + " / " + norm_var_name;
                end
                if x_numeric
                    % Create linear model
                    X = [ones(size(x)), x]; % intercept + predictor
                    b = X \ y; % regression coefficients

                    y_pred = X * b;

                    SSres = sum((y - y_pred).^2);
                    SStot = sum((y - mean(y)).^2);
                    Rsquared = 1 - SSres/SStot;
                end
            end

            % Plot features vs labels for both sides
            h = gscatter(ax, x, y, {sides, dataset_ids}, [], obj.MARKERS(1:n_dataset_ids), obj.MARKER_SIZE, 'off', "filled");

            for i_side=1:n_sides
                for i_dataset=1:n_dataset_ids
                    i = (i_side - 1).*n_dataset_ids + i_dataset;
                    dataset_name = obj.get_dataset_name(unique_dataset_ids(i_dataset));
                    h(i).DisplayName = sprintf('%s %s', dataset_name, unique_sides(i_side));
                    h(i).Color = color{unique_sides(i_side)};
                    h(i).MarkerFaceColor = color{unique_sides(i_side)};
                    h(i).MarkerEdgeColor = color{unique_sides(i_side)};
                end
            end
            % end
            lgd = legend(FontSize=12, FontWeight="bold");

            % Set axis limits
            xlim(ax, 'padded');
            ylim(ax, 'padded');

            % Plot regression model if numeric
            if x_numeric && y_numeric
                plot(ax, x, y_pred, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_DASHED, Color=obj.LINE_COLOR, DisplayName="Linear Regression");
                x_limits = xlim(ax);
                y_limits = ylim(ax);
                text(ax, x_limits(1), y_limits(2) - 0.25, "Rsquared = " + Rsquared, FontSize=obj.FONT_SIZE, FontWeight="bold", Color=obj.LINE_COLOR)
            end

            % Set axis params
            xlabel(ax, x_label);
            ylabel(ax, y_label);
            grid(ax, "on");
            if ~isempty(x_unit) && ~isempty(y_unit) && strcmp(x_unit, y_unit)
                axis(ax, 'equal');
            end

            % Increment counter
            axes_counter = axes_counter + 1;

            % Save figures and reset axes counter
            if axes_counter == number_of_axes_in_fig || (feature_index==n_features && label_index==n_labels)
                if strcmp(show, 'off')
                    file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/Features vs Labels");
                    PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
                end

                axes_counter = 0;
            end
        end
    end
    if strcmp(show, 'off')
        fprintf("All figures saved.\n");
    end
end