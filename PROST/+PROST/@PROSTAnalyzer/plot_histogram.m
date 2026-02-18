function plot_histogram(obj, var_name, normalizer_name, show, file_type, varargin)
%PLOT_HISTOGRAM plots a histogram of the given variable. The variable could be
% either itself or normalized by some other variable. If the histogram count is 
% normalized to 'pdf', a normal distribution is plotted for comparison.
% Input :
%   var_name - the name of the variable to plot the histogram.
%   normalizer_name - the name of the variable by which to normalize.
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.
%   varargin - histogram parameters.

    if nargin < 5
        file_type = [];
    end
    if nargin < 4 || isempty(show)
        show = 'on';
    end
    
    % Get variable
    var = obj.get_samples(var_name);
    value = var.(var_name);
    value_name = replace(var_name, "_", " ");

    if nargin < 3 || isempty(normalizer_name) || ismissing(normalizer_name)
        value_units = replace(var.Properties.VariableUnits, "_", " ");
    else
        normalizer = obj.get_samples(normalizer_name);
        value = value ./ PROST.utils.convert_units(normalizer.(normalizer_name), normalizer.Properties.VariableUnits, var.Properties.VariableUnits);
        value_units = "N.U.";
        value_name = value_name + replace(" normalized (by " + normalizer_name + ")", "_", " ");
    end
    
    if strcmp(show, 'off')
        fprintf("Saving Histogram...\n");
    else
        fprintf("Plotting Histogram...\n");
    end
    fig_name = "Histogram:" + value_name;
    if any(strcmpi('pdf', varargin))
        fig_name = fig_name + " vs Normal Distribution Comparison";
    end
    fig = figure(Name=fig_name, Visible=show);
    h = histogram(value, varargin{:}, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_SOLID);
    h.DisplayName = "Histogram";
    hold on
    if any(strcmpi('pdf', varargin))
        z_limits = h.BinLimits;
        z = linspace(z_limits(1), z_limits(2), 100);
        mu = mean(value);
        sigma = std(value);
        f = normpdf(z, mu, sigma);
        plot(z, f, LineWidth=obj.LINE_WIDTH, DisplayName="Normal Distribution")
    end
    title(replace(fig.Name, "_", " "))
    xlabel(value_name + " [" + value_units + "]")
    ylabel(h.Normalization)
    legend(FontSize=obj.FONT_SIZE)
    hold off
    if strcmp(show, 'off')
        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/Histogram");
        PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
        fprintf("All figures saved.\n");
    end
end