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

    disp("Plotting Histogram...")
    if nargin < 5
        file_type = [];
    end
    if nargin < 4
        show = 'on';
    end
    if nargin < 3 || isempty(normalizer_name) || ismissing(normalizer_name)
        value = var.(var_name);
        value_name = replace(var_name, "_", " ");
        value_units = replace(var.Properties.VariableUnits, "_", " ");
    else
        normalizer = obj.get_samples(normalizer_name);
        var = obj.get_samples(var_name);
        value = var.(var_name) ./ PROST.utils.convert_units(normalizer.(normalizer_name), normalizer.Properties.VariableUnits, var.Properties.VariableUnits);
        value_units = "N.U.";
        value_name = replace(var_name + " normalized (by " + normalizer_name + ")", "_", " ");
    end

    if strcmp(show, 'off')
        disp("Saving figures...")
    end
    fig_name = "Histogram:" + value_name;
    if ismember("pdf", varargin)
        fig_name = fig_name + " vs Normal Distribution Comparison";
    end
    figure(Name=fig_name, Visible=show);
    h = histogram(value, varargin{:});
    h.DisplayName = "Histogram";
    hold on
    y_limits = h.YLim;
    z = linspace(y_limits(1), y_limits(2), 100);
    mu = mean(value);
    sigma = std(value);
    f = normpdf(z, mu, sigma);
    plot(z, f, LineWidth = obj.LINE_WIDTH, Color=h.FaceColor, DisplayName="Normal Distribution")

    title(replace(f.Name, "_", " "))
    xlabel(h, value_name + " [" + value_units + "]")
    ylabel(h, h.Normalization)
    legend(FontSize=obj.FONT_SIZE)
    hold off
    if strcmp(show, 'off')
        PROST.PROSTAnalyzer.save_figure(fig, [], "Histogram", file_type);
        disp("All figures saved.")
    end
end