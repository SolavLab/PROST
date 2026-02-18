function fig = plot_histogram(obj, var_name, normalizer_name, categorizer_name, show, file_type, varargin)
%PLOT_HISTOGRAM plots a histogram of the given variable. The variable could be
% either itself or normalized by some other variable. If the histogram count is 
% normalized to 'pdf', a normal distribution is plotted for comparison.
% Input :
%   var_name - the name of the variable to plot the histogram.
%   normalizer_name - the name of the variable by which to normalize.
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.
%   varargin - histogram parameters as Name-Value pairs.

    if nargin < 6
        file_type = [];
    end
    if nargin < 5 || isempty(show)
        show = 'on';
    end

    % Get variable
    var = obj.get_samples(var_name);
    if ~strcmp(var.Properties.VariableTypes, "double")
        error(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen variable must be of numeric type but is of type %s", var.Properties.VariableTypes));
    end
    value = var.(var_name);
    value_name = replace(var_name, "_", " ");
    value_units = var.Properties.VariableUnits;


    % Get category variable
    if nargin < 4 || isempty(categorizer_name) || ismissing(categorizer_name)
        cat_options = {true};
        categorizer = true(size(value));
        cat_names = "";
    else
        cat_var = obj.get_samples(categorizer_name);
        if ~strcmp(cat_var.Properties.VariableTypes, "categorical")
            error(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen category variable must be of categorical type but is of type %s", cat_var.Properties.VariableTypes));
        end
        categorizer = cat_var.(categorizer_name);
        cat_options = categories(categorizer);
        % cat_units = cat_var.Properties.VariableUnits;
        cat_names = " " + replace(categorizer_name + " = " + string(cat_options), "_", " ");
    end

    % Get normalizer
    if nargin < 3 || isempty(normalizer_name) || ismissing(normalizer_name)
        % do nothing
    else
        normalizer = obj.get_samples(normalizer_name);
        if ~strcmp(normalizer.Properties.VariableTypes, "double")
            error(PROST.PROSTError("VariableType", "WrongVariableType", ...
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
    
    if strcmp(show, 'off')
        fprintf("Saving Histogram...\n");
    else
        fprintf("Plotting Histogram...\n");
    end
    fig_name = "Histogram:" + value_name;
    if any(strcmpi('pdf', varargin))
        fig_name = fig_name + " vs Distribution Comparison";
    end
    fig = figure(Name=fig_name, Visible=show);
    hold on
    for idx=1:numel(cat_options)
        sub_value = value(categorizer == cat_options{idx});
        h = histogram(sub_value, varargin{:}, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_SOLID);
        h.DisplayName = "Histogram" + cat_names(idx);

        % If normalization is pdf also plot normal distribution with same mean and
        % std.
        idx_norm = cellfun(@(x) (isstring(x) || ischar(x)) && strcmp(x, "Normalization"), varargin);
        idx_norm_type = find(idx_norm, 1);
        if ~isempty(idx_norm_type) && strcmpi(varargin{idx_norm_type + 1}, "pdf")
            z_limits = h.BinLimits;
            z = linspace(z_limits(1), z_limits(2), 100);
            [mu, sigma, muCI, sigmaCI] = normfit(sub_value);
            f_norm = normpdf(z, mu, sigma);
            [b, bCI] = raylfit(sub_value);
            f_rayl = raylpdf(z, b);
            if any(sub_value < 0)
                p = strings(2, 1);
                pCI = strings(2, 2);
                f_gamma = nan(size(z));
            else
                [p, pCI] = gamfit(sub_value);
                f_gamma = gampdf(z, p(1), p(2));
            end
            % Match distribution color to histogram color
            ax = ancestor(h,'axes');
            co = ax.ColorOrder; % Get axes color order
            i_color = ax.ColorOrderIndex - 1; % Get the color index used for this object
            i_color = mod(i_color - 1, size(co, 1)) + 1; % Wrap in case of cycling
            actualColor = co(i_color, :);
            
            plot(z, f_norm, LineStyle="-", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Normal Distribution" + cat_names(idx));
            plot(z, f_rayl, LineStyle="--", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Rayleigh Distribution" + cat_names(idx));
            plot(z, f_gamma, LineStyle="-.", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Gamma Distribution" + cat_names(idx));
            
            txt = sprintf("Normal: mu: [%s], sigma: [%s]\nRayleigh: b: [%s]\nGamma: a: [%s], b: [%s]", ...
                          join(string(muCI'), "-"), ...
                          join(string(sigmaCI'), "-"), ...
                          join(string(bCI'), "-"), ...
                          join(string(pCI(:, 1)'), "-"), ...
                          join(string(pCI(:, 2)'), "-"));
            text(0, 1 - (idx-1)*0.1, txt, "Units", "normalized", Color=actualColor, VerticalAlignment="top");

            h.FaceAlpha = 0.5;

        end
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