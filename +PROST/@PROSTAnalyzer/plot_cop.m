function fig = plot_cop(obj, who_to_plot, opts, save_opts)
%PLOT_COP plots the both the shank CS and lab CS CoP data, ankle and 
% knee trajectories for each trial in who_to_plot. 
% Notice: here we can choose the anatomical side to use for the shank CS and 
% the marker trajectories. This can be different than the default "lateral" as 
% used in the PROST database for all other plots and analyses since we are 
% taking the data directly from the data records. Leave empty to use the default 
% "lateral".
%
% Input :
%   who_to_plot - A PROSTDatasetList object that lists the datasets, 
%                 participants and trials to plot for each side. 
%                 Default: the entire database in the data records is plotted 
%                 for both left and right sides (not recommended unless the 
%                 database is small).
%
% Name-Value pair options :
%   number_of_axes_in_fig - number of axes per figure to plot. Default: 6.
%   show - a value denoting whether to show the figures or save them. Specified 
%          as 'on' or 'off', or as numeric or logical 1 (true) or 0 (false). A 
%          value of 'on' is equivalent to true, and 'off' is equivalent to false.
%               - 'on' - show the figure.
%               - 'off' - save the figure.
%          Default: "on".
%   file_type - the type to save the figure if saved. 
%               Default: 'fig'.
%   append - if show = 'off', whether to append this figure to an existing file
%            with the same name in the file path. Specified as 'on' or 'off', or 
%            as numeric or logical 1 (true) or 0 (false). A value of 'on' is 
%            equivalent to true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: false.
%   anatomical_side - which anatomical side to use for the knee and ankle 
%                     trajectories and calculation of the shank CS. 
%                     Choose between: 'lateral', 'medial' and 'mean'. 
%                     Default: 'lateral'.
%
% Output :
%   fig - array of figure handles of all the created plots.

    arguments
        obj 
        who_to_plot                {mustBeScalarOrEmpty, mustBeAOrEmpty(who_to_plot, "PROST.PROSTDatasetList")} = []
        opts.number_of_axes_in_fig {mustBeScalarOrEmpty, mustBeInteger} = 6
        opts.anatomical_side       {mustBeTextScalar, mustBeMember(opts.anatomical_side, ["lateral" "medial" "mean"])} = "lateral"
    end
      arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState =  true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, 1) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end


    % Prep Input Arguments
    if isempty(who_to_plot)
        who_to_plot = PROST.PROSTDatasetList();
        dataset_ids = [obj.DataRecords.Dataset_id];
        for dataset_id=dataset_ids
            who_to_plot.add_to_list(dataset_id);
        end
    end

    number_of_axes_in_fig = opts.number_of_axes_in_fig;
    anatomical_side = opts.anatomical_side;

    show = save_opts.show;
    file_type = save_opts.file_type;
    append = save_opts.append;
    prepare = save_opts.prepare;
    prepare_options = save_opts.prepare_options;

    % Prep Output Arguments
    fig = gobjects(0);
   
    % Start plotting
    fig_counter = 0;
    fprintf("Plotting CoP...\n");
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
            if ~dataset.Data(participant_id).Is_included
                if isempty(dataset.Data(participant_id).Uniform_data.left.step) && ...
                   isempty(dataset.Data(participant_id).Uniform_data.right.step)
                    PROST.PROSTWarning.warn("CoPPlot", "NoSteps", ...
                        "Dataset %d (%s) P%d does not have any valid steps. Skipping", ...
                        dataset_id, dataset_name, participant_id)
                    continue
                else
                    PROST.PROSTWarning.warn("CoPPlot", "NotIncluded", ...
                    "Dataset %d (%s) P%d not included in database. Skipping.", ...
                    dataset_id, dataset_name, participant_id)
                    continue
                end
            end

            % Get steps
            step_numbers = [];
            step_sides = [];
            for side=["left" "right"]
                side_capitalized = PROST.utils.capitalize(side);
                step_numbers_tmp = 1:length(dataset.Data(participant_id).Uniform_data.(side).step);
                if ~isempty(step_numbers_tmp)
                    step_idx = who_to_plot.is_in_list_trials(dataset_id, participant_id, step_numbers_tmp, side_capitalized);
                    step_numbers = [step_numbers step_numbers_tmp(step_idx)];
                    step_sides = [step_sides side + strings(size(step_numbers_tmp(step_idx)))];
                end
            end
            
            for s_idx=1:length(step_numbers)
                % Get step data
                step_number = step_numbers(s_idx);
                side = step_sides(s_idx);
                capitalized_side = PROST.utils.capitalize(side);
                step = dataset.Data(participant_id).Uniform_data.(side).step(step_number);

                if ~step.Is_included
                    PROST.PROSTWarning.warn("CoPPlot", "NotIncluded", ...
                        "Dataset %d (%s) P%d step %d %s not included in database. Skipping", ...
                        dataset_id, dataset_name, participant_id, step_number, side)
                    continue
                end

                % Create new figure for new set of axes
                if axes_counter == 0
                    fig_counter = fig_counter + 1;
                    fig_name = "CoP Plots: Lab CS & shank CS";
                    fig(fig_counter) = figure(Name=fig_name, Visible=show);
                    % n_cols = ceil(sqrt(number_of_axes_in_fig));
                    % n_rows = ceil(number_of_axes_in_fig / n_cols);
                    % tOuter = tiledlayout(fig(fig_counter), n_rows, 2*n_cols, TileSpacing="compact", Padding="compact");
                    tOuter = tiledlayout(fig(fig_counter), TileSpacing="compact", Padding="compact");
                    sgtitle(fig(fig_counter), replace(fig(fig_counter).Name, "_", " "), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME);
                end

                % Inner tile for pair of Ankle-Knee Trajectories and CoPs in
                % World and Shank Frames
                % tInner = tOuter;
                tInner = tiledlayout(tOuter, 1, 2, Units="normalized", TileSpacing="none", Padding="none");
                tInner.Layout.Tile = axes_counter + 1;
                title(tInner, erase(dataset_name, "_") + " P" + participant_id + ": Step " + num2str(step_number) + " " + capitalized_side, FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME);

                % Time vector
                time = 0:100; % Time vector for temporally aligned data to 101 points

                % Get CoP and ankle, knee trajectories after temporal alignment
                cop = step.COP;
                cop.z = 0.*cop.x;
                ankle = step.Markers.Ankle.(anatomical_side);
                knee = step.Markers.Knee.(anatomical_side);
                if isempty(ankle) || isempty(knee)
                    throw(PROST.PROSTError("DataRecords", "MissingAnatomicalSide", ...
                        "The dataset %s has no marker trajectories with anatomical side %s.", dataset_name, anatomical_side));
                end

                % Plot ankle-knee trajectories and CoP in lab CS.
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
                ax_lab = nexttile(tInner);
                title(ax_lab, "Laboratory CS", FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME);

                % Set axis parameters
                ax_lab.FontUnits = "points";
                ax_lab.FontSize = obj.FONT_SIZE;
                ax_lab.FontName = obj.FONT_NAME;
                ax_lab.TitleFontWeight = obj.FONT_WEIGHT;
                ax_lab.FontWeight = obj.FONT_WEIGHT;
                hold(ax_lab, 'on');
                grid(ax_lab, "on");
                
                X = [ankle.x; knee.x];
                Y = [ankle.z; knee.z];
                h_lab = gobjects(3, 1);
                plot(ax_lab, X, Y, LineStyle=obj.LINE_STYLE_SOLID, LineWidth=0.5, Color=obj.LINE_COLOR)
                h_lab(1) = scatter(ax_lab, ankle.x, ankle.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                h_lab(2) = scatter(ax_lab, knee.x, knee.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                h_lab(3) = scatter(ax_lab, cop.x, 0*cop.z, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_TRIANGLE_UP, 'filled', DisplayName='CoP', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                xlabel(ax_lab, "x [mm]")
                ylabel(ax_lab, "z [mm]")

                % Get step data in shank CS
                shank_cop = step.Shank_cop.(anatomical_side); %obj.convert_to_shank_frame(cop, knee, ankle);
                shank_ankle = obj.convert_to_shank_frame(ankle, knee, ankle);
                shank_knee = obj.convert_to_shank_frame(knee, knee, ankle);

                % Plot ankle-knee trajectories and CoP in shank CS.
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
                ax_shank = nexttile(tInner);
                title(ax_shank, "Shank CS", FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)

                ax_shank.FontUnits = "points";
                ax_shank.FontSize = obj.FONT_SIZE;
                ax_shank.FontName = obj.FONT_NAME;
                ax_shank.TitleFontWeight = obj.FONT_WEIGHT;
                ax_shank.FontWeight = obj.FONT_WEIGHT;
                hold(ax_shank, 'on');
                grid(ax_shank, "on");

                X = [shank_ankle.u; shank_knee.u];
                Y = [shank_ankle.w; shank_knee.w];
                plot(ax_shank, X, Y, LineStyle=obj.LINE_STYLE_SOLID, LineWidth=0.5, Color=obj.LINE_COLOR)
                h_shank = gobjects(3, 1);
                h_shank(1) = scatter(ax_shank, shank_ankle.u, shank_ankle.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_SQUARE, 'filled', DisplayName='Ankle', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                h_shank(2) = scatter(ax_shank, shank_knee.u, shank_knee.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_CIRCLE, 'filled', DisplayName='Knee', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                h_shank(3) = scatter(ax_shank, shank_cop.u, shank_cop.w, obj.MARKER_SIZE_SCATTER, time, obj.MARKER_TRIANGLE_UP, 'filled', DisplayName='CoP', MarkerEdgeColor="black", MarkerEdgeAlpha=0.5);
                xlabel(ax_shank, "u [mm]")
                ylabel(ax_shank, "w [mm]")
                legend(ax_shank, h_shank, Location="best");
                cb = colorbar(ax_shank, 'eastoutside');
                cb.Label.String = "% IC to OIC";

                % Update axis counter
                axes_counter = axes_counter + 1;

                % Save figure
                if axes_counter == number_of_axes_in_fig || (participant_id == participants(end) && s_idx == length(step_numbers))
                    tl = tOuter.Children;
                    for k = numel(tl):-1:1
                        ax = findall(tl(k), 'Type', 'Axes');
                        enforce_equal_height(ax(2), ax(1))
                    end
                    if ~show
                        drawnow
                        file_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/COP Plots");
                        PROST.utils.save_figure(fig(fig_counter), file_path, file_type=file_type, append=append, prepare=prepare, prepare_options=prepare_options);
                        fprintf("Saved figure...\n")
                    end
                    
                    % Reset axis counter
                    axes_counter = 0;
                end
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

function enforce_equal_height(ax1, ax2)
%ENFORCE_EQUAL_HEIGHT enforces visually symmetric pairs of axes where data is
% "zoomed-in" similarly. Also forces same grid sizes for comparison of data 
% units.

    % 1. lock metric scaling
    % axis(ax1, 'tight');
    % axis(ax2, 'tight');
    daspect(ax1, [1 1 1])
    daspect(ax2, [1 1 1])

    % ensure limits are computed from data first
    drawnow;

    % 2. extract limits AFTER equal scaling
    x1 = xlim(ax1); y1 = ylim(ax1);
    x2 = xlim(ax2); y2 = ylim(ax2);

    % 3. enforce SAME data-unit height in *mm-space sense*
    %    (this is what makes vertical grid count comparable)
    span1 = diff(y1);
    span2 = diff(y2);

    targetSpan = max(span1, span2);   % preserve all data
    % 4. align baseline (different values allowed)
    base1 = y1(1);
    base2 = y2(1);

    % 5. PAD ONLY UPWARD (key requirement)
    daspect(ax1, [1 1 1]);
    daspect(ax2, [1 1 1]);
    ylim(ax1, [base1, base1 + targetSpan]);
    ylim(ax2, [base2, base2 + targetSpan]);

    % 6. re-lock aspect after limit change
    % daspect(ax1, [1 1 1]);
    % daspect(ax2, [1 1 1]);
end