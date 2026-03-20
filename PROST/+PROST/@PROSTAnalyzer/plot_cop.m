function fig = plot_cop(obj, who_to_plot, opts)
%PLOT_COP plots the both the shank frame and world frame COP data, ankle and 
% knee trajectories for each trial in who_to_plot. 
% Notice: here we can choose the anatomical side to use for the shank frame and 
% the marker trajectories. This can be different than the default "lateral" as 
% used in the PROST database for all other plots and analyses since we are 
% taking the data directly from the data records. Leave empty to use the default 
% "lateral".
% Input :
%   who_to_plot - A PROSTDatasetList object that lists the datasets, 
%                 participants and trials to plot for each side. 
%                 Default: all trials of all participants and all datasets are 
%                 plotted for both left and right sides (not recommended unless 
%                 there are a small number of trials overall).
%   opts - Name-Value pairs of options for plotting.
%       opts.number_of_axes_in_fig - number of axes per figure to plot. 
%                                    Default: 6.
%       opts.show - whether to show the figures or save them. Either "on" for 
%                   showing the figures or "off" for saving them. 
%                   Default: "on".
%       opts.file_type - the type to save the figure if saved. 
%                        Default: fig.
%       opts.anatomical_side - which anatomical side to use for the knee and 
%                              ankle trajectories and calculation of the shank 
%                              frame. Choose between: "lateral", "medial" and 
%                              "mean". 
%                              Default: "lateral".
% Output :
%   fig - array of figure handles of all the created plots.

    arguments
        obj 
        who_to_plot                {mustBeScalarOrEmpty, mustBeAOrEmpty(who_to_plot, "PROST.PROSTDatasetList")} = []
        opts.number_of_axes_in_fig {mustBeScalarOrEmpty, mustBeInteger} = 6
        opts.show                  {mustBeTextScalar, mustBeMember(opts.show, ["on" "off"])} = "on"
        opts.file_type             {mustBeTextScalar, mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"
        opts.anatomical_side       {mustBeTextScalar, mustBeMember(opts.anatomical_side, ["lateral" "medial" "mean"])} = "lateral"
    end

    % Prep Input Arguments
    number_of_axes_in_fig = opts.number_of_axes_in_fig;
    show = opts.show;
    file_type = opts.file_type;
    anatomical_side = opts.anatomical_side;
    if isempty(who_to_plot)
        who_to_plot = PROST.PROSTDatasetList();
        dataset_ids = [obj.DataRecords.Dataset_id];
        for dataset_id=dataset_ids
            who_to_plot.add_to_list(dataset_id);
        end
    end
   
    % Start plotting
    fig_counter = 0;
    fig = gobjects(0);
    if strcmp(show, 'off')
        fprintf("Saving COP...\n");
    else
        fprintf("Plotting COP...\n");
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
                capitalized_side = PROST.utils.capitalize(side);

                % Get step data
                trial = dataset.Data(participant_id).Uniform_data.(side).step(step_number);

                if ~trial.Is_included
                    continue
                end

                % Create new figure for new set of axes
                if axes_counter == 0
                    fig_counter = fig_counter + 1;
                    if strcmp(show, "off") && any(strcmp(file_type, ["pdf" "gif"]))
                        fig_name = "COP Plots: " + dataset_name;
                    else
                        fig_name = "COP Plots: Plot " + fig_counter;
                    end
                    fig(fig_counter)  = figure(Name=fig_name, Visible=show);
                    if strcmp(show, "off")
                        screen_size = get(0,'ScreenSize');
                        fig(fig_counter).WindowStyle = 'normal';
                        fig(fig_counter).Position = screen_size;
                    end
                    n_cols = ceil(sqrt(number_of_axes_in_fig));
                    n_rows = ceil(number_of_axes_in_fig / n_cols);
                    tOuter = tiledlayout(fig(fig_counter), n_rows, n_cols, TileSpacing="compact", Padding="compact");
                    sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "))
                end

                % Inner tile for pair of Ankle-Knee Trajectories and COPs in
                % World and Shank Frames
                tInner = tiledlayout(tOuter, 1, 2, Units="normalized", TileSpacing="tight", Padding="tight");
                tInner.Layout.Tile = axes_counter + 1;
                title(tInner, erase(dataset_name, "_") + " P" + participant_id + ": Step " + num2str(step_number) + " " + capitalized_side, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT)

                % Time vector
                time = 0:100; % Time vector for temporally aligned data to 101 points

                % Get COP and ankle, knee trajectories after temporal alignment
                cop = trial.COP;
                cop.z = 0.*cop.x;
                ankle = trial.Markers.Ankle.(anatomical_side);
                knee = trial.Markers.Knee.(anatomical_side);
                if isempty(ankle) || isempty(knee)
                    throw(PROST.PROSTError("DataRecords", "MissingAnatomicalSide", ...
                        "The dataset %s has no marker trajectories with anatomical side %s.", dataset_name, anatomical_side));
                end

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
                axis(ax1, 'equal');
                pbaspect(ax1, [1 1 1])
                s = scatter(ax1, ankle.x, ankle.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle');
                s = scatter(ax1, knee.x, knee.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee');
                s = scatter(ax1, cop.x, 0*cop.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_UP, 'filled', DisplayName='COP');
                title(ax1, "World Frame", FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT)
                xlabel(ax1, "x [mm]")
                ylabel(ax1, "z [mm]")

                % Get data in shank frame
                shank_cop = obj.convert_to_shank_frame(cop, knee, ankle);
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
                X = [shank_ankle.u; shank_knee.u];
                Y = [shank_ankle.w; shank_knee.w];
                plot(ax2, X, Y, LineStyle=obj.LINE_STYLE_SOLID, LineWidth=obj.LINE_WIDTH, Color=obj.LINE_COLOR)
                hold(ax2, 'on');
                grid(ax2, "on");
                axis(ax2, 'equal');
                pbaspect([1 1 1])
                h = gobjects(3, 1);
                h(1) = scatter(ax2, shank_ankle.u, shank_ankle.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle');
                h(2) = scatter(ax2, shank_knee.u, shank_knee.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee');
                h(3) = scatter(ax2, shank_cop.u, shank_cop.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_UP, 'filled', DisplayName='COP');
                title(ax2, "Shank Frame", FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT)
                xlabel(ax2, "u [mm]")
                ylabel(ax2, "w [mm]")
                legend(ax2, h, FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT, Location="best");
                cb = colorbar(ax2, 'eastoutside', FontSize=obj.FONT_SIZE, FontWeight=obj.FONT_WEIGHT);
                cb.Label.String = "% IC to OIC";
                axes_counter = axes_counter + 1;

                % Save figure
                if axes_counter == number_of_axes_in_fig || (participant_id == participants(end) && s_idx == length(step_numbers))
                    if strcmp(show, 'off')
                        drawnow
                        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/COP Plots");
                        PROST.PROSTAnalyzer.save_figure(fig(fig_counter), file_path, file_type);
                    end
                    
                    % Reset axis counter
                    axes_counter = 0;
                end
            end
        end
    end
    if strcmp(show, 'off')
        fprintf("All figures saved.\n");
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
