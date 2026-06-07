function [fig_data, fig_qq, stats] = plot_stats(obj, var_name, normalizer_name, category_name, distnames, opts, save_opts, hist_opts)
%PLOT_STATS analyzes the statistics of the given variable from the sample data, 
% estimating its distribution and plotting it compared to a histogram, the KDE 
% and a set of predetermined distributions. Also can create a QQ-plot compared 
% to each given distribution. The variable can be normalized relative to another
% variable and divided into subgroups based on categorization of a matching
% categorical variable.
% Note: Requires the Statistics and Machine Learning Toolbox™.
%
% Input :
%   var_name - the name of the variable to plot the histogram.
%   normalizer_name - the name of the variable by which to normalize.
%   category_name - the name of the categorical variable to subdivide by for
%                   better analysis.
%   distnames - list of distribution names to compare to histogram. 
%               Leave empty (default) for no distribution function to compare to. 
%               Options are "normal", "halfnormal", "lognormal", "gamma",
%               "rayleigh", "exponential", "laplace". This uses the Statistics 
%               and Machine Learning Toolbox™.
%
% Name-Value pair options :
%   function_type - the type of function to use for the histogram, KDE 
%                            and distribution plots. Not all function types 
%                            apply to all plots. This overrides the histogram 
%                            "Normalization" setting when applicable.
%                            For histogram: "pdf", "cdf", "count", 
%                                           "probability", "countdensity", 
%                                           "cumcount", "percentage".
%                            For KDEs: "pdf", "cdf", "icdf", "survivor", 
%                                      "cumhazard".
%                            For distribution functions: "pdf", "cdf", "icdf".                   
%                            Default: "count".
%   qq_plot - whether to plot QQ-plots compared to each distribution. 
%                      Either logical 1 (true) to plot the QQ or logical 0 
%                      (false) otherwise.
%                      Default: false.
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
%   prepare - if show = 'off', whether to prepare figures for publication when
%             saving. This sets figure size and fonts according to preset
%             values. Specified as 'on' or 'off', or as numeric or logical 1 
%             (true) or 0 (false). A value of 'on' is equivalent to true, and 
%             'off' is equivalent to false. 
%               - 'on' - prepare for publication.
%               - 'off' - save the figure without preparing for publication.
%            Default: true.
%   prepare_options - if prepare = "on", options for paper preparation (see
%                     prep_figure_for_publish utils function).
%   Histogram plot options - histogram parameters as Name-Value pairs. 
%                            Equivalent to options in the Matlab histogram 
%                            function.
%
% Output :
%   fig_data - figure handle for the plot of the histogram and distribution 
%              estimations.
%   fig_qq - the figure handle for the QQ-plots (if exist).
%   stats - the results of the statistical analysis including Chi2 stats and
%           AIC and BIC rankings.

    arguments
        obj
        var_name                {mustBeTextScalar}
        normalizer_name         {mustBeTextScalarOrEmpty} = []
        category_name           {mustBeTextScalarOrEmpty} = []
        distnames               (1, :) {mustBeValidDistributionOrEmpty(distnames)} = []
        opts.function_type      {mustBeTextScalar, mustBeMember(opts.function_type, ["pdf" "cdf" "icdf" "survivor" "cumhazard" "count" "probability" "countdensity" "cumcount" "percentage"])} = "count"
        opts.qq_plot            (1, 1) logical = false
    end
    arguments
        save_opts.show           (1, 1) matlab.lang.OnOffSwitchState =  true
        save_opts.append         (1, 1) matlab.lang.OnOffSwitchState = false
        save_opts.file_type      (1, 1) string {mustBeMember(save_opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "fig"
        save_opts.prepare        (1, 1) matlab.lang.OnOffSwitchState = true
        save_opts.prepare_options = struct([])
    end
    arguments
        hist_opts.?matlab.graphics.chart.primitive.Histogram
        hist_opts.DisplayName   {mustBeTextScalar} = "Histogram"
    end

    % Prep Input Arguments
    function_type = opts.function_type;
    qq_plot = opts.qq_plot;

    show = save_opts.show;
    file_type = save_opts.file_type;
    append = save_opts.append;
    prepare = save_opts.prepare;
    prepare_options = save_opts.prepare_options;
    
    % Normalize distribution names
    if ~isempty(distnames)
        distnames = convertCharsToStrings(distnames); 
        distnames = erase(lower(distnames), whitespacePattern);
    end
    distributions_no_kde = distnames;

    % Prep Output Arguments
    fig_qq = gobjects(0);
    fig_data = gobjects(0);


    % Get variable
    var = obj.get_IPD_samples(var_name);
    if ~strcmp(var.Properties.VariableTypes, "double")
        throw(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen variable must be of numeric type but is of type %s", var.Properties.VariableTypes));
    end
    value = var.(var_name);
    value_name = replace(var_name, "_", " ");
    value_units = var.Properties.VariableUnits;
    value_type = var.Properties.VariableDescriptions;

    % Get categorizing variable
    if isempty(category_name)
        category_name = "Category";
        category_var = categorical(repmat("All", size(value)));
    else
        category_var = categorical(table2array(obj.get_IPD_samples(category_name)));
    end
    category_options = categories(category_var);
    category_labels = replace(category_name + ": " + string(category_options), "_", " ");
    n_categories = numel(category_options);

    % Normalize variable
    if ~isempty(normalizer_name)
        normalizer = obj.get_IPD_samples(normalizer_name);
        if ~strcmp(normalizer.Properties.VariableTypes, "double")
            throw(PROST.PROSTError("SamplesVariable", "WrongVariableType", ...
                "The chosen normalizer must be of numeric type but is of type %s", var.Properties.VariableTypes));
        end
        try
            value = value ./ PROST.utils.convert_units(normalizer.(normalizer_name), normalizer.Properties.VariableUnits, var.Properties.VariableUnits);
            value_units = "-";
        catch
            value = value ./ normalizer;
            value_units = value_units + "/" + normalizer.Properties.VariableUnits;
        end
        value_name = value_name + " / " +  replace(normalizer_name, "_", " ");
    end

    % Determine which types of plots are applicable
    histogram_types = ["count" "probability" "percentage" "countdensity" "cumcount" "pdf" "cdf"];
    kde_types = ["pdf" "cdf" "icdf" "survivor" "cumhazard"];
    dist_types = ["pdf" "cdf" "icdf"];
    
    hist_flag = ismember(function_type, histogram_types);
    kde_flag = ismember(function_type, kde_types) && ~isempty(distnames) && ismember("kernel", distnames);
    if kde_flag
        kde_idx = strcmp("kernel", distributions_no_kde);
        distributions_no_kde(kde_idx) = [];
    end
    dist_flag = ismember(function_type, dist_types) && ~isempty(distributions_no_kde);
    dataplot_flag = hist_flag || kde_flag || dist_flag;
    qqplot_flag = qq_plot && dist_flag;

    % Override Histogram Normalization with Function Type
    if hist_flag
        hist_opts.Normalization = function_type;
    end

    % Define Statistics options
    analyze_stats_opts.TargetExp = 10;
    analyze_stats_opts.MinExpected  (1, 1) = 5;
    if kde_flag
        analyze_stats_opts.KDEFunction = function_type;
        analyze_stats_opts.KDENumPoints = 400;
        if strcmpi(value_name, "Radius") || strcmpi(value_type, "predictor")
            analyze_stats_opts.KDESupport = "positive";
        else
            analyze_stats_opts.KDESupport = "unbounded";
        end
        analyze_stats_opts.KDEKernel = "normal";
    end 

    fprintf("Plotting Statistics...\n");
    % Plot settings
    function_type_map = dictionary("count", "Count of Observations", ...
                             "probability", "Relative Probability", ...
                             "percentage", "Relative Percentage", ...
                             "countdensity", "Density of Observations", ...
                             "cumcount", "Cummulative Count", ...
                             "pdf", "Probability Density Function", ...
                             "cdf", "Cummulative Distribution Function", ...
                             "icdf", "Inverse Cummulative Distribution Function", ...
                             "survivor", "Survivor Function", ...
                             "cumhazard", "Cumulative Hazard Function");
    
    if dataplot_flag % hist_flag || kde_flag || dist_flag
        fig_data = figure(Name="Stat Plots: " + value_name + " Distribution Estimation", Visible=show);
        tl_data = tiledlayout(TileSpacing="compact", Padding="compact");
        sgtitle(fig_data, replace(fig_data.Name, "_", " "), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
        colororder(fig_data, "gem12");
    end

    if qqplot_flag
        fig_qq = figure(Name="Stat Plots: " + value_name + " QQ Plot", Visible=show);
        tl_qq = tiledlayout(TileSpacing="compact", Padding="compact");
        sgtitle(fig_qq, replace(fig_qq.Name, "_", " "), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
        colororder(fig_qq, "gem12");
    end

    % Plot for each category
    stats = [];
    for cat_idx=1:n_categories
        value_i = value(category_var == category_options{cat_idx});
        x = linspace(min(value_i), max(value_i), 1000);
        
        if dataplot_flag % hist_flag || kde_flag || dist_flag
            % Set axis parameters
            ax_data = nexttile(tl_data);
            ax_data.FontUnits = "points";
            ax_data.FontSize = obj.FONT_SIZE;
            ax_data.FontName = obj.FONT_NAME;
            ax_data.TitleFontWeight = obj.FONT_WEIGHT;
            ax_data.FontWeight = obj.FONT_WEIGHT;
            hold(ax_data, "on");
            grid(ax_data, "on");
            title(ax_data, category_labels(cat_idx))

            if function_type == "icdf"
                xlabel(ax_data, "probability")
            else
                xlabel(ax_data, value_name + " [" + value_units + "]")
            end
            ylabel(ax_data, function_type_map(function_type))
            legend(ax_data, Location='best');
        end

        if qqplot_flag
            num_axes = numel(distributions_no_kde);
            n_cols = ceil(sqrt(num_axes));
            n_rows = ceil(num_axes / n_cols);
            tl_qq_inner = tiledlayout(tl_qq, n_rows, n_cols, 'Padding', 'tight', 'TileSpacing','tight');
            tl_qq_inner.Layout.Tile = cat_idx;
            title(tl_qq_inner, category_labels(cat_idx), FontSize=obj.FONT_SIZE, FontName=obj.FONT_NAME)
        end

        if hist_flag
            hist_property_cell = namedargs2cell(hist_opts);
            h = histogram(ax_data, value_i, hist_property_cell{:});
            x_limits = h.BinLimits;
            x = linspace(x_limits(1), x_limits(2), 1000);
        end
        
        % Analyze Statistics
        property_cell = namedargs2cell(analyze_stats_opts);
        stats_i = PROST.PROSTAnalyzer.analyze_stats(value_i, distnames, property_cell{:});
        stats_i.category = category_labels(cat_idx);
        stats = [stats; stats_i];
        txt = sprintf(PROST.utils.pretty_print(stats_i.summary));
        txt = strip(splitlines(txt));
        txt = " " + txt(txt~="" & ~startsWith(txt, "-"));
        txt = join(txt, newline);
        text(ax_data, 0.01, 1, txt, ...
            Units="normalized", ...
            FontSize=obj.FONT_SIZE_TEXT, ...
            FontName=obj.FONT_NAME_TEXT, ...
            FontWeight=obj.FONT_WEIGHT_TEXT, ...
            HorizontalAlignment="left", ...
            VerticalAlignment="top", ...
            BackgroundColor="white");

        if kde_flag
            kde = stats_i.fits.kernel.kde;
            plot(ax_data, kde.xi, kde.f, ...
                LineStyle=obj.LINE_STYLE_SOLID, ...
                LineWidth=obj.LINE_WIDTH, ...
                DisplayName=sprintf("KDE bw=%.2f", kde.bw));
            plot(ax_data, kde.xi, kde.f_alt{1}, ...
                LineStyle=obj.LINE_STYLE_SOLID, ...
                LineWidth=obj.LINE_WIDTH, ...
                DisplayName=sprintf("KDE bw=%.2f", kde.bw_alt(1)));
            plot(ax_data, kde.xi, kde.f_alt{2}, ...
                LineStyle=obj.LINE_STYLE_SOLID, ...
                LineWidth=obj.LINE_WIDTH, ...
                DisplayName=sprintf("KDE bw=%.2f", kde.bw_alt(2)));
        end

        if dist_flag
            for dist_idx=1:numel(distributions_no_kde)
                distname = distributions_no_kde(dist_idx);
                key = matlab.lang.makeValidName(distname);

                if ~ismember(key, string(fieldnames(stats_i.fits)))
                    continue;
                end

                    txt = sprintf("%s Distribution", stats_i.fits.(key).name);
                    plot(ax_data, x, stats_i.fits.(key).(function_type)(x), ...
                                     LineWidth=obj.LINE_WIDTH, ...
                                     LineStyle=obj.LINE_STYLE_SOLID, ...
                                     DisplayName=txt);
                
                    if qqplot_flag
                        % Set axis parameters
                        ax_qq = nexttile(tl_qq_inner, dist_idx);
                        ax_qq.FontUnits = "points";
                        ax_qq.FontSize = obj.FONT_SIZE;
                        ax_qq.FontName = obj.FONT_NAME;
                        ax_qq.TitleFontWeight = obj.FONT_WEIGHT;
                        ax_qq.FontWeight = obj.FONT_WEIGHT;
                        hold(ax_qq, "on");
                        grid(ax_qq, "on");
                        if stats_i.fits.(key).type == "toolbox"
                            qqplot(ax_qq, value_i, stats_i.fits.(key).pd)
                        else
                            p = rand(size(x));
                            y = stats_i.fits.(key).icdf(p);
                            qqplot(ax_qq, value_i, y);
                        end
                        
                        grid(ax_qq, "on")
                        title("")
                    end % if qq_flag
            end % for distname=distnames
        end % if dist_flag
    end % for cat_idx=1:n_categories

    % Save figures
    if ~show
        figure_path = fullfile(obj.Toolbox_root, "figures/ROS Analysis/Stat Plots");
        PROST.utils.save_figure(fig_data, figure_path, file_type=file_type, append=append, prepare=prepare, prepare_options=prepare_options);
        if qqplot_flag
            PROST.utils.save_figure(fig_qq, figure_path, file_type=file_type, append=append, prepare=prepare, prepare_options=prepare_options);
        end
        fprintf("Saved figures...\n")
    end
end

% ------------ Helper functions for validation
function mustBeTextScalarOrEmpty(value)
%MUSTBETEXTSCALAROREMPTY Validate that value is single piece of text or an empty
% array.
    if isempty(value)
        return
    end   
    mustBeTextScalar(value);
end

function d = matlabContinuousDistributions()
%MATLABCONTINUOUSDISTRIBUTIONS returns the list of supported distribution names
% in the Statistics and Machine Learning Toolbox™.
    persistent list
    if isempty(list)
        pkg = meta.package.fromName('prob');
        cls = pkg.ClassList;
        names = string({cls.Name});
        names = names(endsWith(names, "Distribution"));
        names = erase(names, "Distribution");
        names = erase(names, "prob.");
        names = [names "Laplace"];
        list = sort(names);
    end
    d = list;
end

function mustBeValidDistributionOrEmpty(distnames)
%MUSTBEVALIDDISTRIBUTIONOREMPTY Validate that distnames are all members of the 
% specified set of distribution names from the Statistics and Machine Learning 
% Toolbox™ or an empty array.
    if isempty(distnames)
        return
    end

    allowed = lower(matlabContinuousDistributions());
    distnames = erase(lower(distnames), whitespacePattern);
    mustBeMember(distnames, allowed);
end

