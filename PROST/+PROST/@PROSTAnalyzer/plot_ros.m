function plot_ros(obj, who_to_plot, number_of_axes_in_fig, plot_type, show, file_type)
%PLOT_ROS plots the shank frame CoP data and the fitted ROS arc for all
% participants in who_to_plot.
% Input :
%   who_to_plot - A PROSTDatasetList object that lists the datasets and
%                 participants to plot for each side. 
%                 Default: all participants and all datasets are plotted for
%                 both left and right sides.
%   number_of_axes_in_fig - number of axes per figure to plot.
%                           Default: 6.
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.

    disp("Plotting ROS...")
    % Prep Input Arguments
    if nargin < 6
        file_type = [];
    end
    if nargin < 5 || isempty(plot_type)
        plot_type = "circle";
    end
    if nargin < 4 || isempty(show)
        show = 'on';
    end
    if nargin < 3 || isempty(number_of_axes_in_fig)
        number_of_axes_in_fig = 6;
    end
    if nargin < 2 || isempty(who_to_plot)
        who_to_plot = PROST.PROSTDatasetList();
        dataset_ids = [obj.DataRecords.Dataset_id];
        for dataset_id=dataset_ids
            who_to_plot.add_to_list(dataset_id);
        end
    end

    % Set plot parameters
    color_arc = dictionary(["right" "left"], {obj.COLOR_RIGHT_DARK obj.COLOR_LEFT_DARK});
    color_scatter = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});
    x_label = "x [mm]";
    y_label = "z [mm]";

    % Start plotting
    fig_counter = 0;
    if strcmp(show, 'off')
        disp("Saving figures...")
    end
    for i=1:length([who_to_plot.List.Dataset_id])
        axes_counter = 0;
        
        % Get data
        dataset_id = who_to_plot.List(i).Dataset_id;
        if ~obj.dataset_exists(dataset_id)
            error(PROST.PROSTError("DataRecords", "MissingDataset", ...
                "Dataset %d not in data records.", dataset_id));
        end
        dataset = obj.get_dataset(dataset_id);
        dataset_name = obj.get_dataset_name(dataset_id);
        participants = [dataset.Data.Participant_id];
        participant_idx = participants(who_to_plot.is_in_list_participants(dataset_id, participants));
        participants = participants(participant_idx);

        for participant_id=participants
            sides = ["left" "right"];
            left_idx = who_to_plot.is_in_list_side(dataset_id, participant_id, "Left");
            right_idx = who_to_plot.is_in_list_side(dataset_id, participant_id, "Right");

            [samples, entry_numbers] = obj.get_sample_entry(dataset_id, participant_id, sides([left_idx right_idx]));
            if isempty(samples)
                continue
            end

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig = figure(Name="ROS Plots: " + dataset_name + " Plot " + fig_counter, Visible=show);
                n_cols = ceil(sqrt(number_of_axes_in_fig));
                n_rows = ceil(number_of_axes_in_fig / n_cols);
                tiledlayout(fig, n_rows, n_cols)
            end

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            hold(ax, "on")
            grid(ax, "on")
            axis(ax, "equal");
            pbaspect(ax, [1 1 1]);
            title(ax, erase(dataset_name, "_") + " P" + participant_id, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT)

            % Plot 0 point
            plot(ax, 0, 0, MarkerSize=obj.MARKER_SIZE, Marker=obj.MARKER_CIRCLE, MarkerEdgeColor="black", MarkerFaceColor="black")  
            
            % Plot trials of participant
            R = [];
            X = [];
            Z = [];
            Res = [];
            offset = 0;
            for j=1:height(samples)
                entry_number = entry_numbers(j);
                sample = samples(j, :);

                % get point cloud of corresponding entry in samples table.
                point_cloud = obj.PointClouds{entry_number};

                % Assuming point_cloud is an Nx3 matrix with columns: x, z, num_trial
                x = point_cloud(:, 1);
                z = point_cloud(:, 2);
                trial_nums = point_cloud(:, 3);
                unique_trial_nums = unique(trial_nums);

                % Get arc parameters
                [radius, center_x, center_z, ang_start, ang_end, residual] = ...
                    deal(sample.Radius, sample.Center_x, sample.Center_z, sample.Ang_start, sample.Ang_end, sample.Residual);
                
                % Save arc parameters
                R = [R radius];
                X = [X center_x];
                Z = [Z center_z];
                Res = [Res residual];

                % Get side
                side = sample.Side;

                % Calculate arc values
                ang_vec = linspace(ang_start, ang_end, length(x));
                z_sign = sign(z - center_z);
                arc_points = [center_x + radius*sind(ang_vec); center_z + radius.*z_sign.*cosd(ang_vec)];
                circle_vec = linspace(0, 360, length(x));
                circle_points = [center_x + radius*sind(circle_vec); center_z - radius*cosd(circle_vec)];

                % Plot point cloud
                for k = unique_trial_nums(:)'
                    idx = trial_nums == k;
                    h_scat = scatter(ax, x(idx), z(idx), obj.MARKER_SIZE_SCATTER, color_scatter{side}, obj.MARKER_DOT, MarkerEdgeAlpha=obj.MARKER_FACE_ALPHA, MarkerFaceAlpha=obj.MARKER_FACE_ALPHA); % point cloud

                    % Optional: custom datatip text field
                    trialVals = repmat(k, sum(idx), 1);
                    h_scat.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trialVals);
                end
                
                % Plot ROS fitted arc and circle
                plot(ax, arc_points(1, :), arc_points(2, :), LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted arc
                if strcmp(plot_type, "circle")
                    plot(ax, circle_points(1, :), circle_points(2, :), LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted circle
                    plot(ax, center_x, center_z, Marker=obj.MARKER_CIRCLE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=obj.MARKER_SIZE); % center
                elseif strcmp(plot_type, "azimuth")
                    plot(ax, center_x, min(circle_points(2, :)), Marker=obj.MARKER_CIRCLE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=obj.MARKER_SIZE); % azimuth
                else
                    error(PROST.PROSTError("PlotROS", "WrongPlotType", ...
                        "plot_type should be either 'circle' or 'azimuth'."))
                end

                % Print Text on axis
                txt = sprintf("(%.2f, %.2f), R: %.2f [mm],\nresidual: %.2f [mm]", center_x, center_z, radius, residual);
                t = text(ax, ...
                         0, 1 - offset, txt, ...
                         Units="normalized", ...
                         Color=color_arc{side}, ...
                         FontSize=obj.FONT_SIZE, ...
                         FontName="FixedWidth", ...
                         FontWeight=obj.FONT_WEIGHT, ...
                         HorizontalAlignment="left", ...
                         VerticalAlignment="top");
                % if strcmp(show, "on")
                    drawnow
                % end
                offset = offset + t.Extent(4);
    
                xlabel(ax, x_label);
                ylabel(ax, y_label);
            end

            % Update axis counter
            axes_counter = axes_counter + 1;

            % Create legend and save figures
            if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                % Dummy plots for legend in last axes
                sides = ["left", "right"];
                n_sides = length(sides);
                n_plots = 3 + strcmp(plot_type, "circle");
                h = gobjects(n_sides*n_plots, 1);
                for j=1:n_sides
                    i = 0;
                    side = sides(j);
                    h(j + i) = scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{side}(1, :), obj.MARKER_DOT, DisplayName=string(side));
                    i = i + n_sides;
                    h(j + i) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH, DisplayName=string(side) + " fitted arc");
                    i = i + n_sides;
                    if strcmp(plot_type, "circle")
                        h(j + i) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH, DisplayName=string(side) + " fitted circle");
                        i = i + n_sides;
                    end
                    h(j + i) = plot(ax, NaN, NaN, Marker=obj.MARKER_CIRCLE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=obj.MARKER_SIZE, DisplayName=string(side) + " " + "circle");
                end
                
                % Legend
                lgd = legend(h, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT);
                lgd.Layout.Tile = 'east';
                
                % Save figures
                if strcmp(show, 'off')
                    file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/ROS Plots");
                    PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
                end
                
                % Reset axis counter
                axes_counter = 0;
            end
        end
    end
    if strcmp(show, 'off')
        disp("All figures saved.")
    end
end