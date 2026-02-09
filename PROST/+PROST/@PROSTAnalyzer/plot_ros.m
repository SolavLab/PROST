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
                fig  = figure(Name="ROS Plots: " + dataset_name + " Plot " + fig_counter, Visible=show);
                tiledlayout(fig)
            end

            % Initialize axis
            ax = nexttile;

            % Set axis parameters
            hold(ax, "on")
            grid(ax, "on")
            axis(ax, "equal");
            pbaspect(ax, [1 1 1]);
            plot(0, 0, MarkerSize=obj.MARKER_SIZE, Marker=obj.MARKER_CIRCLE, MarkerEdgeColor="black", MarkerFaceColor="black")  

            % Plot trials of participant
            R = [];
            X = [];
            Z = [];
            Res = [];
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

                % Plot point cloud and arc
                for k = unique_trial_nums(:)'
                    idx = trial_nums == k;
                    h_scat = scatter(ax, x(idx), z(idx), obj.MARKER_SIZE_SCATTER, color_scatter{side}, obj.MARKER_DOT); % point cloud

                    % Optional: custom datatip text field
                    trialVals = repmat(k, sum(idx), 1);
                    h_scat.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', trialVals);
                end

                plot(ax, arc_points(1, :), arc_points(2, :), LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted arc
                plot(ax, circle_points(1, :), circle_points(2, :), LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH); % fitted circle
                plot(ax, center_x, center_z, Marker=obj.MARKER_CIRCLE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=obj.MARKER_SIZE); % center
                
                xlabel(ax, x_label);
                ylabel(ax, y_label);
            end
            
            % Print Text on axis
            text(ax, 0, 1, erase(dataset_name, "_") + " P" + participant_id, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT, Units="normalized")
            for j=1:height(samples)
                sample = samples(j, :);
                side = sample.Side;

                % Print parameter values and residual
                txt = sprintf("(%.2f, %.2f), R: %.2f [mm]", X(j), Z(j), R(j));
                text(ax, X(j), Z(j), txt, Color=color_arc{side}, FontSize=obj.FONT_SIZE, FontName="FixedWidth", FontWeight=obj.FONT_WEIGHT)

                % Print parameter values and residual
                txt = sprintf("residual: %.2f [mm]", Res(j));
                text(0, 1 - 0.05*j, txt, Color=color_arc{side}, FontSize=obj.FONT_SIZE, FontName="FixedWidth", FontWeight=obj.FONT_WEIGHT, Units="normalized")
            end
            axes_counter = axes_counter + 1;

            % Create legend
            if axes_counter == number_of_axes_in_fig || participant_id == participants(end)
                % Dummy plots for legend in last axes
                sides = ["right", "left"];
                n_sides = length(sides);
                h = gobjects(n_sides*4, 1);
                for j=1:n_sides
                    side = sides(j);
                    h(j) = scatter(ax, NaN, NaN, obj.MARKER_SIZE, color_scatter{side}(1, :), obj.MARKER_DOT, DisplayName=side);
                    h(j + 2) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_SOLID, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH, DisplayName=string(side) + " fitted arc");
                    h(j + 4) = plot(ax, NaN, NaN, LineStyle=obj.LINE_STYLE_DASHED, Color=color_arc{side}, LineWidth=obj.LINE_WIDTH, DisplayName=string(side) + " fitted circle");
                    h(j + 6) = plot(ax,  NaN, NaN, Marker=obj.MARKER_CIRCLE, MarkerFaceColor=color_arc{side}, MarkerEdgeColor=color_arc{side}, MarkerSize=obj.MARKER_SIZE, DisplayName=string(side) + " center");
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