function fig = plot_ros(obj, who_to_plot, opts, save_opts)
%PLOT_ROS plots the shank frame CoP data and the fitted ROS arc of each side for 
% all participants in who_to_plot. It also plots either the nadir, or circle 
% center with accompanying circle that matches each ROS arc.
%
% Input :
%   who_to_plot - A PROSTDatasetList object that lists the datasets and
%                 participants to plot for each side. 
%                 Default: all participants and all datasets are plotted for
%                 both left and right sides.
%
% Name-Value pair options :
%   number_of_axes_in_fig - number of axes per figure to plot. 
%                           Default: 6.
%   plot_type - either "nadir" for plotting the nadir point of the 
%                        circle matching the ROS arc, "circle" for the circle 
%                        center point and the circle itself.
%                        Default: "circle".
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
% Output :
%   fig - array of figure handles of all the created plots.

    arguments
        obj 
        who_to_plot                {mustBeScalarOrEmpty, mustBeAOrEmpty(who_to_plot, "PROST.PROSTDatasetList")} = []
        opts.plot_type             {mustBeTextScalar, mustBeMember(opts.plot_type, ["circle" "nadir"])} = "circle"
        opts.number_of_axes_in_fig {mustBeScalarOrEmpty, mustBeInteger} = 6
    end
    arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState =  true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.overwrite      (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, :) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end

    % Prep Input Arguments
    number_of_axes_in_fig = opts.number_of_axes_in_fig;
    plot_type = opts.plot_type;

    show = save_opts.show;
    file_type = save_opts.file_type;
    append = save_opts.append;
    overwrite = save_opts.overwrite;
    prepare = save_opts.prepare;
    prep_options = save_opts.prepare_options;
    
    if isempty(who_to_plot)
        who_to_plot = PROST.PROSTDatasetList();
        dataset_ids = [obj.DataRecords.Dataset_id];
        for dataset_id=dataset_ids
            who_to_plot.add_to_list(dataset_id);
        end
    end

    % Prep Output Arguments
    fig = gobjects(0);

    % Set plot parameters
    color_arc = dictionary(["right" "left"], {obj.COLOR_RIGHT_DARK obj.COLOR_LEFT_DARK});
    color_scatter = dictionary(["right" "left"], {obj.COLOR_RIGHT_BRIGHT obj.COLOR_LEFT_BRIGHT});
    x_label = "u [mm]";
    y_label = "w [mm]";

    % Start plotting
    fig_counter = 0;
    fprintf("Plotting ROS...\n");
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

            [samples, row_numbers] = obj.get_IPD_samples_by_entry(dataset_id, participant_id, sides([left_idx right_idx]));
            if isempty(samples)
                continue
            end

            % Create new figure for new set of axes
            if axes_counter == 0
                fig_counter = fig_counter + 1;
                fig_name = "ROS Plots: ROS Arc & " + PROST.utils.capitalize(plot_type);
                fig(fig_counter) = figure(Name=fig_name, Visible=show);
                n_cols = ceil(sqrt(number_of_axes_in_fig));
                n_rows = ceil(number_of_axes_in_fig / n_cols);
                tl = tiledlayout(fig(fig_counter), n_rows, n_cols, TileSpacing="compact", Padding="compact");
                sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
            end

            % Initialize axis
            ax = nexttile(tl);

            % Set axis parameters
            ax.FontUnits = "points";
            ax.FontSize = obj.FONT_SIZE;
            ax.FontName = obj.FONT_NAME;
            ax.TitleFontWeight = obj.FONT_WEIGHT;
            ax.FontWeight = obj.FONT_WEIGHT;
            hold(ax, "on")
            grid(ax, "on")
            axis(ax, "equal");
            pbaspect(ax, [1 1 1]);
            title(ax, erase(dataset_name, "_") + " P" + participant_id)

            % Plot trials of participant
            offset = 0;
            for j=1:height(samples)
                row_number = row_numbers(j);
                sample = samples(j, :);

                % get point cloud of corresponding entry in samples table.
                point_cloud = obj.PointClouds{row_number};

                % Assuming point_cloud is an Nx3 matrix with columns: u, w,
                % num_step
                u = point_cloud(:, 1);
                w = point_cloud(:, 2);
                step_nums = point_cloud(:, 3);
                unique_step_nums = unique(step_nums);

                % Get arc parameters
                [radius, center_horizontal, center_vertical, ang_start, ang_end, residual] = ...
                    deal(sample.Radius, sample.Center_horizontal, sample.Center_vertical, sample.Ang_start, sample.Ang_end, sample.Residual_rms);
                
                % Get side
                side = sample.Side;

                % Calculate arc values
                arc_angle_vec = linspace(ang_start, ang_end, length(u));
                z_sign = sign(w - center_vertical);
                arc_points = [center_horizontal + radius*sind(arc_angle_vec); center_vertical + radius.*z_sign.*cosd(arc_angle_vec)];
                circle_angle_vec = linspace(0, 360, length(u));
                circle_points = [center_horizontal + radius*sind(circle_angle_vec); center_vertical - radius*cosd(circle_angle_vec)];

                % Plot point cloud
                for k = unique_step_nums(:)'
                    idx = step_nums == k;
                    h_scat = scatter(ax, u(idx), w(idx), obj.MARKER_SIZE_SCATTER, color_scatter{side}, obj.MARKER_DOT, MarkerEdgeAlpha=obj.MARKER_ALPHA, MarkerFaceAlpha=obj.MARKER_ALPHA); % CoP point cloud

                    % Custom datatip text field
                    trialVals = repmat(k, sum(idx), 1);
                    h_scat.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trialVals);
                end
                
                % Plot ROS fitted arc and circle
                plot(ax, arc_points(1, :), arc_points(2, :), LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted arc
                if strcmp(plot_type, "circle")
                    plot(ax, circle_points(1, :), circle_points(2, :), LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % circle
                    plot(ax, center_horizontal, center_vertical, Marker=obj.MARKER_CENTER, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, LineStyle="none", LineWidth=obj.MARKER_LINE_WIDTH); % center
                    plot(ax, [center_horizontal arc_points(1, 1)], [center_vertical arc_points(2, 1)], LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % start angle line
                    plot(ax, [center_horizontal arc_points(1, end)], [center_vertical arc_points(2, end)], LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % end angle line

                elseif strcmp(plot_type, "nadir")
                    plot(ax, center_horizontal, min(circle_points(2, :)), Marker=obj.MARKER_NADIR, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, LineStyle="none", LineWidth=obj.MARKER_LINE_WIDTH); % ndir
                else
                    throw(PROST.PROSTError("PlotROS", "WrongPlotType", ...
                        "plot_type should be either 'circle' or 'nadir'."))
                end

                % Print Text on axis
                txt = sprintf(" C: (%.2f, %.2f), R: %.2f [mm],\n residual RMS: %.2f [mm]", center_horizontal, center_vertical, radius, residual);
                txt_handle = text(ax, ...
                                  0.01, 1 - offset, txt, ...
                                  Units="normalized", ...
                                  Color=color_arc{side}, ...
                                  FontSize=obj.FONT_SIZE_TEXT, ...
                                  FontName=obj.FONT_NAME_TEXT, ...
                                  FontWeight=obj.FONT_WEIGHT_TEXT, ...
                                  HorizontalAlignment="left", ...
                                  VerticalAlignment="top", ...
                                  BackgroundColor="white");
                drawnow 
                offset = offset + txt_handle.Extent(4) + 0.01;
    
                xlabel(ax, x_label);
                ylabel(ax, y_label);
            end

            % Plot ankle point
            plot(ax, 0, 0, Marker=obj.MARKER_ANKLE, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor="black", MarkerEdgeColor="black", LineStyle="none", LineWidth=obj.MARKER_LINE_WIDTH);
            

            % Update axis counter
            axes_counter = axes_counter + 1;

            % Create legend and save figure
            if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                % Dummy plots for legend in last axes
                h = gobjects(0);
                h = [h plot(ax, NaN, NaN, Marker=obj.MARKER_ANKLE, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor="black", MarkerEdgeColor="black", LineWidth=obj.MARKER_LINE_WIDTH, LineStyle="none", DisplayName="Ankle")]; % dummy ankle
                h = [h scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{"left"}(1, :), obj.MARKER_DOT, DisplayName="CoP_L")]; % dummy left CoP
                h = [h scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{"right"}(1, :), obj.MARKER_DOT, DisplayName="CoP_R")]; % dummy right CoP
                h = [h plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{"left"}, LineWidth=obj.LINE_WIDTH, DisplayName="Arc_L")]; % dummy left arc
                h = [h plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{"right"}, LineWidth=obj.LINE_WIDTH, DisplayName="Arc_R")];  % dummy right arc
                
                if strcmp(plot_type, "circle")
                    h = [h plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{"left"}, LineWidth=obj.LINE_WIDTH, DisplayName="Circle_L")]; % dummy left circle
                    h = [h plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{"right"}, LineWidth=obj.LINE_WIDTH, DisplayName="Circle_R")]; % dummy right circle
                    h = [h plot(ax, NaN, NaN, Marker=obj.MARKER_CENTER, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{"left"}, MarkerEdgeColor=color_arc{"left"}, LineWidth=obj.MARKER_LINE_WIDTH, LineStyle="none", DisplayName="Center_L")]; % dummy left center
                    h = [h plot(ax, NaN, NaN, Marker=obj.MARKER_CENTER, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{"right"}, MarkerEdgeColor=color_arc{"right"}, LineWidth=obj.MARKER_LINE_WIDTH, LineStyle="none", DisplayName="Center_R")]; % dummy right center
                else                    
                    h = [h plot(ax, NaN, NaN, Marker=obj.MARKER_NADIR, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{"right"}, MarkerEdgeColor=color_arc{"right"}, LineWidth=obj.MARKER_LINE_WIDTH, LineStyle="none", DisplayName="Nadir_L")]; % dummy left nadir
                    h = [h plot(ax, NaN, NaN, Marker=obj.MARKER_NADIR, MarkerSize=obj.MARKER_SIZE, MarkerFaceColor=color_arc{"left"}, MarkerEdgeColor=color_arc{"left"}, LineWidth=obj.MARKER_LINE_WIDTH, LineStyle="none", DisplayName="Nadir_R")]; % dummy right nadir
                end

                % Legend
                lgd = legend(h, Location="eastoutside");

                % Save figures
                if ~show
                    drawnow
                    figure_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/ROS Plots");
                    PROST.utils.save_figure(fig(fig_counter), figure_path, file_type=file_type, append=append, overwrite=overwrite, prepare=prepare, prepare_options=prep_options);
                    fprintf("Saved figure...\n")
                end
                
                % Reset axis counter
                axes_counter = 0;
            end
        end
    end
end

% --------- helper functions ------------
function mustBeAOrEmpty(value, classname)
%MUSTBEAOREMPTY Validate that value comes from one of specified classes or is an
% empty array.
    if isempty(value)
        return
    end
    mustBeA(value, classname);
end
