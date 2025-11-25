function plot_ros(obj, who_to_plot, number_of_axes_in_fig, show, file_type)
%PLOT_ROS plots the shank frame CoP data and the fitted ROS arc for all
% participants in who_to_plot.
% Input :
%   who_to_plot - a cell array with pairs of dataset id and
%                 list of participants to plot. Example: {1, [1 2 3 4]}
%                 plots the data and ROS arc of the left and right feet
%                 for participant 1, 2, 3 and 4 in dataset 1. Plots all
%                 participants of all datasets if non are provided.
%   number_of_axes_in_fig - number of axes per figure to plot.
%                           Default: 6.
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.

    disp("Plotting ROS...")
    % Prep Input Arguments
    if nargin < 5
        file_type = [];
    end
    if nargin < 4
        show = 'on';
    end
    if nargin < 3
        number_of_axes_in_fig = 6;
    end
    if nargin < 2 || isempty(who_to_plot)
        n_data_records = length(obj.DataRecords);
        who_to_plot = cell(n_data_records, 2);
        who_to_plot(:, 1) = {obj.DataRecords.Dataset_id}';
    end
    for who_index=1:size(who_to_plot, 1)
        if size(who_to_plot, 2) == 1 || isempty(who_to_plot{who_index, 2})
            dataset_id = who_to_plot{who_index, 1};
            dataset = obj.get_dataset(dataset_id);
            who_to_plot{who_index, 2} = [dataset.Data.Participant_id];
        end
    end

    % Set plot parameters
    x_limits = [-100 200];
    y_limits = [-100 50];
    color_arc = dictionary(["right" "left"], {obj.COLOR_RIGHT_DARK obj.COLOR_LEFT_DARK});
    color_scatter = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});
    % color_scatter = dictionary(["right" "left"], {[0.0, 1.0, 0.0] [1.0, 0.0, 0.0]});
    marker_size = 5;
    markers = 'o+*.xsdv><phn';
    line_width = 2;
    x_label = "x [mm]";
    y_label = "z [mm]";

    % Start plotting
    fig_counter = 0;
    if strcmp(show, 'off')
        disp("Saving figures...")
    end
    for who=who_to_plot'
        axes_counter = 0;
        dataset_id = who{1};
        if ~obj.dataset_exists(dataset_id)
            error(PROST.PROSTError("DataRecords", "MissingDataset", ...
                "Dataset %d not in data records.", dataset_id));
        end
        dataset_name = obj.get_dataset_name(dataset_id);
        participants = who{2};
        for participant_id=participants
            [samples, entry_numbers] = obj.get_sample_entry(dataset_id, participant_id);
            if isempty(samples)
                continue
            end

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig  = figure(Name="ROS PLots: " + dataset_name + " Plot " + fig_counter, Visible=show);
                tiledlayout(fig)
            end

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            hold(ax, "on")
            grid(ax, "on")
            axis(ax, "equal");
            pbaspect(ax, [1 1 1]);
            xticks(ax, x_limits(1):50:x_limits(2));
            yticks(ax, y_limits(1):50:y_limits(2));
            ax.XLim = x_limits;
            ax.YLim = y_limits;
            text(ax, x_limits(1), y_limits(2) - 10, erase(dataset_name, "_") + " P" + participant_id, FontSize=9, FontWeight="bold")
            plot(0, 0, MarkerSize=marker_size, Marker='o', MarkerEdgeColor="black", MarkerFaceColor="black")

            % Plot trials of participant
            for i=1:height(samples)
                entry_number = entry_numbers(i);
                sample = samples(i, :);

                % get point cloud of corresponding entry in samples table.
                point_cloud = obj.PointClouds{entry_number};

                % Assuming point_cloud is an Nx3 matrix with columns: x, z, num_trial
                x = point_cloud(:, 1);
                z = point_cloud(:, 2);
                trial_num = point_cloud(:, 3);

                % Get arc parameters
                [radius, center_x, center_z, ang_start, ang_end, residual] = ...
                    deal(sample.Radius, sample.Center_x, sample.Center_z, sample.Ang_start, sample.Ang_end, sample.Residual);

                % Get side
                side = sample.Side;

                % Calculate arc values
                ang_vec = linspace(ang_start, ang_end, length(x));
                z_sign = sign(z - center_z);
                arc_points = [center_x + radius*sind(ang_vec); center_z + radius.*z_sign.*cosd(ang_vec)];
                circle_vec = linspace(0, 360, length(x));
                circle_points = [center_x + radius*sind(circle_vec); center_z - radius*cosd(circle_vec)];

                % Plot point cloud and arc
                % scatter(ax, x, z, marker_size, color_scatter{side}, '.'); % point cloud
                gscatter(x, z, trial_num, color_scatter{side}, markers(1), marker_size, 'off', "filled");
                plot(ax, arc_points(1, :), arc_points(2, :), '-', Color=color_arc{side}, LineWidth=line_width); % fitted arc
                plot(ax, circle_points(1, :), circle_points(2, :), '--', Color=color_arc{side}, LineWidth=line_width); % fitted circle
                plot(ax, center_x, min(circle_points(2, :)), 'o', MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=marker_size); % nadir

                % Print parameter values and residual
                txt = sprintf("radius: %.2f [mm], center: (%.2f, %.2f) [mm], residual: %.2f [mm]", radius, center_x, center_z, residual);
                text(ax, x_limits(1), y_limits(2) - 10 - i*10, txt, Color=color_arc{side}, FontSize=9, FontName="FixedWidth", FontWeight="bold")

                xlabel(ax, x_label);
                ylabel(ax, y_label);
            end

            axes_counter = axes_counter + 1;

            % Create legend
            if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                % Dummy plots for legend in last axes
                sides = ["right", "left"];
                n_sides = length(sides);
                h = gobjects(n_sides*4, 1);
                for i=1:n_sides
                    side = sides(i);
                    h(i) = scatter(ax, NaN, NaN, marker_size, color_scatter{side}(1, :), markers(1), "filled", DisplayName=side);
                    h(i + 2) = plot(ax, NaN, NaN, '-', Color=color_arc{side}, LineWidth=line_width, DisplayName=string(side) + " fitted arc");
                    h(i + 4) = plot(ax, NaN, NaN, '--', Color=color_arc{side}, LineWidth=line_width, DisplayName=string(side) + " fitted circle");
                    h(i + 6) = plot(ax,  NaN, NaN, 'o', MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=marker_size, DisplayName=string(side) + " nadir");
                end

                lgd = legend(h, FontSize=12, FontWeight="bold");
                lgd.Layout.Tile = 'east';

                if strcmp(show, 'off')
                    PROST.PROSTAnalyzer.save_figure(fig, [], "ROS PLots", file_type);
                end

                axes_counter = 0;
            end
        end
    end
    if strcmp(show, 'off')
        disp("All figures saved.")
    end
end