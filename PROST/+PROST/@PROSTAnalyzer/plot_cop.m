function plot_cop(obj, who_to_plot, number_of_axes_in_fig, show, file_type, anatomical_side)
%PLOT_COP Summary of this function goes here
%   Detailed explanation goes here

    % Prep Input Arguments
    if nargin < 6 || isempty(anatomical_side)
        anatomical_side = "lateral";
    end
    if nargin < 5 || isempty(file_type)
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
            who_to_plot.add_to_list(dataset_ids);
        end
    end
   
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
            % Get steps
            step_numbers_left = 1:length(dataset.Data(participant_id).Uniform_data.left.step);
            step_idx_left = who_to_plot.is_in_list_trials(dataset_id, participant_id, step_numbers_left, "Left");
            step_numbers_left = step_numbers_left(step_idx_left);
            step_numbers_right = 1:length(dataset.Data(participant_id).Uniform_data.right.step);
            step_idx_right = who_to_plot.is_in_list_trials(dataset_id, participant_id, step_numbers_right, "Right");         
            step_numbers_right = step_numbers_right(step_idx_right);

            step_numbers = [step_numbers_left step_numbers_right];
            step_sides = ["left" + strings(size(step_numbers_left)) "right" + strings(size(step_numbers_right))];
            for s_idx=1:length(step_numbers)
                step_number = step_numbers(s_idx);
                side = step_sides(s_idx);

                % Get step data
                trial = dataset.Data(participant_id).Uniform_data.(side).step(step_number);

                if ~trial.Is_included
                    continue
                end

                % Create new figure for new set of axes
                if axes_counter == 0
                    fig_counter = fig_counter + 1;
                    fig  = figure(Name="COP Plots: " + dataset_name + " Plot " + fig_counter, Visible=show);
                    tOuter = tiledlayout(fig, 'TileSpacing', 'tight', 'Padding', 'tight');
                    sgtitle(fig, replace(fig.Name, "_", " "))
                end

                % Inner tile for pair of Ankle-Knee Trajectories and COPs in
                % World and Shank Frames
                tInner = tiledlayout(tOuter, 1, 2, 'Units','normalized', 'Padding', 'tight', 'TileSpacing','tight');
                tInner.Layout.Tile = axes_counter + 1;
                title(tInner, "P" + participant_id + " (" + side + "): Step " + num2str(step_number))

                % Time vector
                time = 0:100; % Time vector for temporally aligned data to 101 points

                % Get COP and ankle, knee trajectories after temporal alignment
                cop = trial.COP;
                cop.z = 0.*cop.x;
                ankle = trial.Markers.Ankle.(anatomical_side);
                knee = trial.Markers.Knee.(anatomical_side);

                % Plot ankle-knee trajectories in space.
                % Should look like this:
                % ::::::--=====--::::....
                % ::::::--=+%@%#*+=-------:::::::.
                % .::::-:=-*@@%#+==----::::::::..
                % ..::::.=+#@@%*+=-----::::::..
                %  .:-:..=*@@@%*===---:-::..
                %  ..:-=-+*@@@#++=-----:..
                %   .:::=+%@@%*++===-:
                %   .:-=-+@@@%*+++-.
                %    .--=#@@@%*=..
                %    .:=+%@@*:.
                %     :-+@#:
                %     .-+*.
                ax1 = nexttile(tInner, 1);
                X = [ankle.x; knee.x];
                Y = [ankle.z; knee.z];
                plot(ax1, X, Y, LineStyle=obj.LINE_STYLE_SOLID, LineWidth=obj.LINE_WIDTH, Color=obj.LINE_COLOR)
                hold(ax1, 'on');
                grid(ax1, "on");
                axis(ax1, 'tight');
                axis(ax1, 'equal');
                pbaspect(ax1, [1 1 1])
                s = scatter(ax1, ankle.x, ankle.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle');
                s = scatter(ax1, knee.x, knee.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee');
                s = scatter(ax1, cop.x, 0*cop.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_UP, 'filled', DisplayName='COP');
                title(ax1, "World Frame")

                % Get data in shank frame
                shank_cop = trial.Shank_cop.(anatomical_side);
                shank_ankle = obj.convert_to_shank_frame(ankle, knee, ankle);
                shank_knee = obj.convert_to_shank_frame(knee, knee, ankle);

                % Plot COP in shank frame
                % Should look like this:
                %     ...
                %    .--.
                %     ..
                %     ..
                %     ..
                %     ..
                %     ..
                %     ..
                %     ..
                %     ::.
                %     ...
                %                     ...
                %                 .:=*+:.
                %  ....     .:--+++=-..
                % .-++++++++++-:..
                ax2 = nexttile(tInner, 2);
                X = [shank_ankle.x; shank_knee.x];
                Y = [shank_ankle.z; shank_knee.z];
                plot(ax2, X, Y, LineStyle=obj.LINE_STYLE_SOLID, LineWidth=obj.LINE_WIDTH, Color=obj.LINE_COLOR)
                hold(ax2, 'on');
                grid(ax2, "on");
                axis(ax2, 'tight');
                axis(ax2, 'equal');
                % pbaspect([1 1 1])
                h = gobjects(3, 1);
                h(1) = scatter(ax2, shank_ankle.x, shank_ankle.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle');
                h(2) = scatter(ax2, shank_knee.x, shank_knee.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee');
                h(3) = scatter(ax2, shank_cop.x, shank_cop.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_UP, 'filled', DisplayName='COP');
                title(ax2, "Shank Frame")
                xlabel(tInner, "x [mm]")
                ylabel(ax1, "z [mm]")
                legend(ax2, h, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT, Location="best");
                cb = colorbar(ax2, 'eastoutside', FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT);
                cb.Label.String = 'WA + SS %';
                axes_counter = axes_counter + 1;

                % Create Legend
                if axes_counter == number_of_axes_in_fig || (participant_id == participants(end) && s_idx == length(step_numbers))
                    if strcmp(show, 'off')
                        PROST.PROSTAnalyzer.save_figure(fig, "../../figures/ROS Analysis/COP Plots", file_type);
                    end
                    axes_counter = 0;
                end
            end
        end
    end
    if strcmp(show, 'off')
        disp("All figures saved.")
    end
end
