function fig = plot_ros(obj, who_to_plot, opts)
%PLOT_ROS plots the shank frame CoP data and the fitted ROS arc of each side for 
% all participants in who_to_plot. It also plots either the nadir, or circle 
% center with accompanying circle that matches each ROS arc.
% Input :
%   who_to_plot - A PROSTDatasetList object that lists the datasets and
%                 participants to plot for each side. 
%                 Default: all participants and all datasets are plotted for
%                 both left and right sides.
%   number_of_axes_in_fig - number of axes per figure to plot. Default: 6.
%   plot_type - either "nadir" for plotting the nadir point of the circle 
%               matching the ROS arc, "circle" for the circle center point and
%               the circle itself. Default: "circle".
%   show - whether to show the figures or save them. Either "on" for showing the 
%          figures or "off" for saving them. Default: "on".
%   file_type - the type to save the figure if saved. Default: fig.
% Output :
%   fig - array of figure handles of all the created plots.

    arguments
        obj 
        who_to_plot                {mustBePRSOTDatasetListOrEmpty(who_to_plot)} = []
        opts.plot_type             {mustBeMember(opts.plot_type, ["circle" "nadir"])}
        opts.number_of_axes_in_fig {mustBeInteger, mustBeScalarOrEmpty} = 6
        opts.show                  {mustBeMember(opts.show, ["on" "off"])} = "on"
        opts.file_type             {mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"

    end

    % Prep Input Arguments
    number_of_axes_in_fig = opts.number_of_axes_in_fig;
    show = opts.show;
    file_type = opts.file_type;
    plot_type = opts.plot_type;
    if isempty(who_to_plot)
        who_to_plot = PROST.PROSTDatasetList();
        dataset_ids = [obj.DataRecords.Dataset_id];
        for dataset_id=dataset_ids
            who_to_plot.add_to_list(dataset_id);
        end
    end

    % Set plot parameters
    color_arc = dictionary(["right" "left"], {obj.COLOR_RIGHT_DARK obj.COLOR_LEFT_DARK});
    color_scatter = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});
    x_label = "u [mm]";
    y_label = "w [mm]";

    % Start plotting
    fig = gobjects(0);
    fig_counter = 0;
    if strcmp(show, 'off')
        fprintf("Saving ROS...\n");
    else
        fprintf("Plotting ROS...\n");
    end
    for i=1:length([who_to_plot.List.Dataset_id])
        axes_counter = 0;
        
        % Get data
        dataset_id = who_to_plot.List(i).Dataset_id;
        if ~obj.dataset_exists(dataset_id)
            throw(PROST.PROSTError("DataRecords", "MissingDataset", ...
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
                fig(fig_counter) = figure(Name="ROS Plots: " + dataset_name, Visible=show);
                if strcmp(show, "off")
                    screen_size = get(0,'ScreenSize');
                    fig(fig_counter).WindowStyle = 'normal';
                    fig(fig_counter).Position = screen_size;
                end
                n_cols = ceil(sqrt(number_of_axes_in_fig));
                n_rows = ceil(number_of_axes_in_fig / n_cols);
                tl = tiledlayout(fig(fig_counter), n_rows, n_cols, TileSpacing="compact", Padding="compact");
                sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "))
            end

            % Initialize axis
            ax = nexttile(tl);

            % Set axis parameters
            hold(ax, "on")
            grid(ax, "on")
            axis(ax, "equal");
            pbaspect(ax, [1 1 1]);
            title(ax, erase(dataset_name, "_") + " P" + participant_id, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT)

            % Plot 0 point
            scatter(ax, 0, 0, obj.MARKER_SIZE_SCATTER, "black", obj.MARKER_CIRCLE, "filled");
            
            % Plot trials of participant
            offset = 0;
            for j=1:height(samples)
                entry_number = entry_numbers(j);
                sample = samples(j, :);

                % get point cloud of corresponding entry in samples table.
                point_cloud = obj.PointClouds{entry_number};

                % Assuming point_cloud is an Nx3 matrix with columns: x, z, num_trial
                u = point_cloud(:, 1);
                w = point_cloud(:, 2);
                trial_nums = point_cloud(:, 3);
                unique_trial_nums = unique(trial_nums);

                % Get arc parameters
                [radius, center_horizontal, center_vertical, ang_start, ang_end, residual] = ...
                    deal(sample.Radius, sample.Center_horizontal, sample.Center_vertical, sample.Ang_start, sample.Ang_end, sample.Residual);
                
                % Get side
                side = sample.Side;

                % Calculate arc values
                ang_vec = linspace(ang_start, ang_end, length(u));
                z_sign = sign(w - center_vertical);
                arc_points = [center_horizontal + radius*sind(ang_vec); center_vertical + radius.*z_sign.*cosd(ang_vec)];
                circle_vec = linspace(0, 360, length(u));
                circle_points = [center_horizontal + radius*sind(circle_vec); center_vertical - radius*cosd(circle_vec)];

                % Plot point cloud
                for k = unique_trial_nums(:)'
                    idx = trial_nums == k;
                    h_scat = scatter(ax, u(idx), w(idx), obj.MARKER_SIZE_SCATTER, color_scatter{side}, obj.MARKER_DOT, MarkerEdgeAlpha=obj.MARKER_FACE_ALPHA, MarkerFaceAlpha=obj.MARKER_FACE_ALPHA); % point cloud

                    % Optional: custom datatip text field
                    trialVals = repmat(k, sum(idx), 1);
                    h_scat.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trialVals);
                end
                
                % Plot ROS fitted arc and circle
                plot(ax, arc_points(1, :), arc_points(2, :), LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted arc
                if strcmp(plot_type, "circle")
                    plot(ax, circle_points(1, :), circle_points(2, :), LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted circle
                    scatter(ax, center_horizontal, center_vertical, obj.MARKER_SIZE_SCATTER, color_arc{side}, obj.MARKER_CIRCLE, "filled"); % center
                elseif strcmp(plot_type, "nadir")
                    scatter(ax, center_horizontal, min(circle_points(2, :)), obj.MARKER_SIZE_SCATTER, color_arc{side}, obj.MARKER_CIRCLE, "filled"); % ndir
                else
                    throw(PROST.PROSTError("PlotROS", "WrongPlotType", ...
                        "plot_type should be either 'circle' or 'nadir'."))
                end

                % Print Text on axis
                txt = sprintf("(%.2f, %.2f), R: %.2f [mm],\nresidual: %.2f [mm]", center_horizontal, center_vertical, radius, residual);
                txt_handle = text(ax, ...
                                  0, 1 - offset, txt, ...
                                  Units="normalized", ...
                                  Color=color_arc{side}, ...
                                  FontSize=obj.FONT_SIZE, ...
                                  FontName="FixedWidth", ...
                                  FontWeight="bold", ...
                                  HorizontalAlignment="left", ...
                                  VerticalAlignment="top");
                drawnow 
                offset = offset + txt_handle.Extent(4);
    
                xlabel(ax, x_label);
                ylabel(ax, y_label);
            end

            % Update axis counter
            axes_counter = axes_counter + 1;

            % Create legend and save figure
            if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                % Dummy plots for legend in last axes
                n_plots = 3 + strcmp(plot_type, "circle");
                h = gobjects(2*n_plots + 1, 1);
                h(1) = scatter(ax, NaN, NaN, obj.MARKER_SIZE_SCATTER, "black", obj.MARKER_CIRCLE, "filled", DisplayName="ankle point");
                h(2) = scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{"left"}(1, :), obj.MARKER_DOT, DisplayName="left");
                h(3) = scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{"right"}(1, :), obj.MARKER_DOT, DisplayName="right");
                h(4) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{"left"}, LineWidth=obj.LINE_WIDTH, DisplayName="left fitted arc");
                h(5) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{"right"}, LineWidth=obj.LINE_WIDTH, DisplayName="right fitted arc");
                
                if strcmp(plot_type, "circle")
                    h(6) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{"left"}, LineWidth=obj.LINE_WIDTH, DisplayName="left fitted circle");
                    h(7) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{"right"}, LineWidth=obj.LINE_WIDTH, DisplayName="right fitted circle");
                    h(8) = scatter(ax, NaN, NaN, obj.MARKER_SIZE_SCATTER, color_arc{"left"}, obj.MARKER_CIRCLE, "filled", DisplayName="left center");
                    h(9) = scatter(ax, NaN, NaN, obj.MARKER_SIZE_SCATTER, color_arc{"right"}, obj.MARKER_CIRCLE, "filled", DisplayName="right center");

                else
                    h(6) = scatter(ax, NaN, NaN, obj.MARKER_SIZE_SCATTER, color_arc{"left"}, obj.MARKER_CIRCLE, "filled", DisplayName="left nadir");
                    h(7) = scatter(ax, NaN, NaN, obj.MARKER_SIZE_SCATTER, color_arc{"right"}, obj.MARKER_CIRCLE, "filled", DisplayName="right nadir");
                end
                
                % Legend
                lgd = legend(h, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT, Location="layout");
                lgd.Layout.Tile = "east";

                % Save figures
                if strcmp(show, 'off')
                    drawnow
                    figure_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/ROS Plots");
                    PROST.PROSTAnalyzer.save_figure(fig(fig_counter), figure_path, file_type);
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
function mustBePRSOTDatasetListOrEmpty(x)
    if isempty(x)
        return
    end
    mustBeA(x, "PROST.PROSTDatasetList");
end
