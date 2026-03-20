function [fig_dist, fig_qq, stats] = plot_stats(obj, var_name, normalizer_name, categorizer_name, distnames, opts, hist_opts)
%PLOT_STATS analyzes the statistics of the given variable from the sample data, 
% estimating its distribution and plotting it compared to a histogram, the KDE 
% and a set of predetermined distributions. Also can create a QQ-plot compared 
% to each given distribution. The variable can be normalized relative to another
% variable and divided into subgroups based on categorizaion of a matching
% categorical variable.
% Note: Requires the Statistics and Machine Learning Toolbox™.
% Input :
%   var_name - the name of the variable to plot the histogram.
%   normalizer_name - the name of the variable by which to normalize.
%   categorizer_name - the name of the categorical variable to subdivide by for
%                      better analysis.
%   distnames - list of distribution names to compare to histogram. 
%               Leave empty (default) for no distribution function to compare to. 
%               Options are "normal", "halfnormal", "lognormal", "gamma",
%               "rayleigh", "exponential", "laplace". This uses the Statistics 
%               and Machine Learning Toolbox™.
%   opts - Name-Value pairs of options for statistical analysis and plotting.
%       function_type - the type of function to use for the histogram, KDE and 
%                       distribution plots. Not all function types apply to all 
%                       plots. This overrides the histogram Normalization 
%                       setting when applicable.
%                       For histogram: "pdf", "cdf", "count", "probability", 
%                                      "countdensity", "cumcount", "percentage".
%                       For KDEs: "pdf", "cdf", "icdf", "survivor", "cumhazard".
%                       For distribution functions: "pdf", "cdf", "icdf".                   
%                       Default: "count" (only plots histogram with bin counts).
%       qq_plot - whether to plot QQ-plots compared to each distribution. Either 
%                 logical 1 (true) to plot the QQ or logical 0 (false) otherwise.
%                 Default: false.
%       show - whether to show the figures or save them. Either "on" 
%                   (default) for showing the figures or "off" for saving them.
%       file_type - the type to save the figure if saved. Default: "fig".
%   hist_opts - histogram parameters as Name-Value pairs. Equivalent to options
%               in the Matlab histogram function.
% Output :
%   fig_dist figure handle for the plot of the distribution estimations. 
%   fig_qq - the figure handle for the QQ-plots.
%   stats - the results of the statistical analysis including Chi2 stats and
%           AIC and BIC rankings.

    arguments
        obj
        var_name                {mustBeTextScalar}
        normalizer_name         {mustBeTextScalarOrEmpty} = []
        categorizer_name        {mustBeTextScalarOrEmpty} = []
        distnames               (1, :) {mustBeValidDistributionOrEmpty(distnames)} = []
        opts.function_type      {mustBeTextScalar, mustBeMember(opts.function_type, ["pdf" "cdf" "icdf" "survivor" "cumhazard" "count" "probability" "countdensity" "cumcount" "percentage"])} = "count"
        opts.show               {mustBeTextScalar, mustBeMember(opts.show, ["on" "off"])} = "on"
        opts.file_type          {mustBeTextScalar, mustBeMember(opts.file_type, ["fig" "pdf" "png" "gif" "jpg" "jpeg" "tif" "tiff" "emf" "eps"])} = "fig"
        opts.qq_plot            (1,1) logical = false
        hist_opts.?matlab.graphics.chart.primitive.Histogram
        hist_opts.DisplayName   {mustBeTextScalar} = "Histogram"
    end

    fig_qq = gobjects(0);
    fig_dist = gobjects(0);

    % Get variable
    var = obj.get_samples(var_name);
    if ~strcmp(var.Properties.VariableTypes, "double")
        throw(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen variable must be of numeric type but is of type %s", var.Properties.VariableTypes));
    end
    value = var.(var_name);
    value_name = replace(var_name, "_", " ");
    value_units = var.Properties.VariableUnits;
    value_type = var.Properties.VariableDescriptions;

    % Get category variable
    if isempty(categorizer_name)
        cat_options = {true};
        categorizer = true(size(value));
        cat_names = "";
    else
        cat_var = obj.get_samples(categorizer_name);
        if ~strcmp(cat_var.Properties.VariableTypes, "categorical")
            throw(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen category variable must be of categorical type but is of type %s", cat_var.Properties.VariableTypes));
        end
        categorizer = cat_var.(categorizer_name);
        cat_options = categories(categorizer);
        cat_names = " " + replace(categorizer_name + " = " + string(cat_options), "_", " ");
    end
    n_categories = numel(cat_options);

    % Get normalizer
    if ~isempty(normalizer_name)
        normalizer = obj.get_samples(normalizer_name);
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
    hist_flag = ismember(opts.function_type, histogram_types);
    kde_flag = ismember(opts.function_type, kde_types) && ~isempty(distnames) && ismember("kernel", distnames);
    dist_flag = ismember(opts.function_type, dist_types) && ~isempty(distnames);
    distplot_flag = hist_flag || kde_flag || dist_flag;
    qqplot_flag = opts.qq_plot && dist_flag;

    % Override Histogram Normalization with Function Type
    if hist_flag
        hist_opts.Normalization = opts.function_type;
    end

    % Define Statistics options
    analyze_stats_opts.TargetExp = 10;
    analyze_stats_opts.MinExpected  (1, 1) = 5;
    if kde_flag
        analyze_stats_opts.KDEFunction = opts.function_type;
        analyze_stats_opts.KDENumPoints = 400;
        if strcmpi(value_name, "Radius") || strcmpi(value_type, "feature")
            analyze_stats_opts.KDESupport = "positive";
        else
            analyze_stats_opts.KDESupport = "unbounded";
        end
        analyze_stats_opts.KDEKernel = "normal";
    end 

    % Normalize distnames
    if ~isempty(distnames)
        if iscell(distnames)
            distnames = string(distnames); 
        end
        distnames = erase(lower(distnames), whitespacePattern);
    end

    % Check whether to save or plot
    if strcmp(opts.show, 'off')
        fprintf("Saving Statistics...\n");
    else
        fprintf("Plotting Statistics...\n");
    end

    % Plot settings
    function_type_map = dictionary("count", "Count of Observations", ...
                             "probability", "Relative Probability", ...
                             "percentage", "Relative Percentage", ...
                             "countdensity", "Density of Observations", ...
                             "cumcount", "Cummulative Count", ...
                             "pdf", "Probability Distribution Function", ...
                             "cdf", "Cummulative Distribution Function", ...
                             "icdf", "Inverse Cummulative Distribution Function", ...
                             "survivor", "Survivor Function", ...
                             "cumhazard", "Cumulative Hazard Function");
    
    if distplot_flag
        fig_dist = figure(Name="Statistics: " + value_name + " Distribution Estimation", Visible=opts.show);
        tl_hist = tiledlayout(TileSpacing="compact", Padding="compact");
        sgtitle(fig_dist, replace(fig_dist.Name, "_", " "))
        colororder(fig_dist, "gem12");
    end
    if qqplot_flag
        fig_qq = figure(Name="Statistics: " + value_name + " QQ Plot", Visible=opts.show);
        tl_qq = tiledlayout(TileSpacing="compact", Padding="compact");
        sgtitle(fig_qq, replace(fig_qq.Name, "_", " "))
        colororder(fig_qq, "gem12");
    end

    % Plot for each category
    stats(n_categories) = struct("summary", [], "rankingAIC", [], "rankingBIC", [], "fits", []);
    for cat_idx=1:n_categories
        value_i = value(categorizer == cat_options{cat_idx});
        x = linspace(min(value_i), max(value_i), 1000);
        
        if distplot_flag
            ax_dist = nexttile(tl_hist);
            title(ax_dist, cat_names(cat_idx))
            hold(ax_dist, "on");
            if opts.function_type == "icdf"
                xlabel(ax_dist, "probability")
            else
                xlabel(ax_dist, value_name + " [" + value_units + "]")
            end
            ylabel(ax_dist, function_type_map(opts.function_type))
            legend(ax_dist, FontSize=obj.FONT_SIZE, FontWeight="bold");
        end

        if qqplot_flag
            num_axes = numel(distnames);
            if kde_flag
                num_axes = num_axes - 1;
            end
            n_cols = ceil(sqrt(num_axes));
            n_rows = ceil(num_axes / n_cols);
            tl_qq_inner = tiledlayout(tl_qq, n_rows, n_cols, 'Padding', 'tight', 'TileSpacing','tight');
            tl_qq_inner.Layout.Tile = cat_idx;
            title(tl_qq_inner, cat_names(cat_idx))
        end

        if hist_flag
            hist_property_cell = namedargs2cell(hist_opts);
            h = histogram(ax_dist, value_i, hist_property_cell{:});
            x_limits = h.BinLimits;
            x = linspace(x_limits(1), x_limits(2), 1000);
            h.DisplayName = h.DisplayName + " Bin Method: " + h.BinMethod;
        end
        
        if dist_flag || kde_flag
            property_cell = namedargs2cell(analyze_stats_opts);
            stats_i = PROST.PROSTAnalyzer.analyze_stats(value_i, distnames, property_cell{:});
            stats(cat_idx) = stats_i;
            txt = sprintf(PROST.utils.pretty_print(stats_i.summary));
            % clean summary text
            txt = strip(splitlines(txt));
            txt = join(txt(txt~="" & ~startsWith(txt, "-")), newline);
            text(ax_dist, 0, 1, txt, ...
                 Units="normalized", ...
                 FontSize=obj.FONT_SIZE, ...
                 FontName="FixedWidth", ...
                 FontWeight="bold", ...
                 HorizontalAlignment="left", ...
                 VerticalAlignment="top");
            
            for dist_idx=1:numel(distnames)
                distname = distnames(dist_idx);
                key = matlab.lang.makeValidName(distname);

                if ~ismember(key, string(fieldnames(stats_i.fits)))
                    continue;
                end
                if distname == "kernel" && kde_flag
                    kde = stats_i.fits.kernel.kde;
                    plot(ax_dist, kde.xi, kde.f, ...
                                      LineStyle=obj.LINE_STYLE_SOLID, ...
                                      LineWidth=obj.LINE_WIDTH, ...
                                      DisplayName=sprintf("KDE bw=%.2f", kde.bw));
                    plot(ax_dist, kde.xi, kde.f_alt{1}, ...
                                      LineStyle=obj.LINE_STYLE_SOLID, ...
                                      LineWidth=obj.LINE_WIDTH, ...
                                      DisplayName=sprintf("KDE bw=%.2f", kde.bw_alt(1)));
                    plot(ax_dist, kde.xi, kde.f_alt{2}, ...
                                      LineStyle=obj.LINE_STYLE_SOLID, ...
                                      LineWidth=obj.LINE_WIDTH, ...
                                      DisplayName=sprintf("KDE bw=%.2f", kde.bw_alt(2)));
                elseif dist_flag
                    params = sprintf(PROST.utils.pretty_print(stats_i.fits.(key).params));
                    % clean text
                    params = strip(splitlines(params));
                    params = join(params(params~="" & ~startsWith(params, "-")), ", ");

                    txt = sprintf("%s Distribution: %s", stats_i.fits.(key).name, params);
                    plot(ax_dist, x, stats_i.fits.(key).(opts.function_type)(x), ...
                                     LineWidth=obj.LINE_WIDTH, ...
                                     LineStyle=obj.LINE_STYLE_SOLID, ...
                                     DisplayName=txt);
                
                    if qqplot_flag
                        ax_qq = nexttile(tl_qq_inner, dist_idx);
                        hold(ax_qq, "on");
                        if stats_i.fits.(key).type == "toolbox"
                            qqplot(ax_qq, value_i, stats_i.fits.(key).pd)
                        else
                            p = rand(size(x));
                            y = stats_i.fits.(key).icdf(p);
                            qqplot(ax_qq, value_i, y);
                        end
                        grid(ax_qq, "on")
                        title(ax_qq, sprintf("QQ Plot: Data vs %s Distribution", stats_i.fits.(key).name));
                        legend(ax_qq)
                    end % if qq_flag
                end % if name == "kernel" && kde_flag
            end % for distname=distnames
        end % if dist_flag || kde_flag
    end % for cat_idx=1:n_categories

    % Save figures
    if strcmp(opts.show, 'off')
        figure_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/Stat Plots");
        PROST.PROSTAnalyzer.save_figure(fig_dist, figure_path, opts.file_type);
        PROST.PROSTAnalyzer.save_figure(fig_qq, figure_path, opts.file_type);
        fprintf("All figures saved.\n");
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

