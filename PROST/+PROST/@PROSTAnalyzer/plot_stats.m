function fig = plot_stats(obj, var_name, normalizer_name, categorizer_name, model_pdfs, show, file_type, varargin)
%PLOT_STATS plots a histogram of the given variable. The variable could be
% either itself or normalized by some other variable. If the histogram count is 
% normalized to 'pdf', a normal distribution is plotted for comparison.
% Input :
%   var_name - the name of the variable to plot the histogram.
%   normalizer_name - the name of the variable by which to normalize.
%   categorizer_name - the name of the categorical variable to subdivide by for
%                      better analysis.
%   model_pdfs - list of model pdfs to compare to if Normalization was chosen as
%                'pdf'.  Leave empty (default) for no density function to 
%                compare to. 
%                Options are: "normal", "rayleigh", "gamma".
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.
%   varargin - histogram parameters as Name-Value pairs.

    if nargin < 7
        file_type = [];
    end
    if nargin < 6 || isempty(show)
        show = 'on';
    end
    if nargin < 5
        model_pdfs = [];
    end

    % Get variable
    var = obj.get_samples(var_name);
    if ~strcmp(var.Properties.VariableTypes, "double")
        throw(PROST.PROSTError("VariableType", "WrongVariableType", ...
                "The chosen variable must be of numeric type but is of type %s", var.Properties.VariableTypes));
    end
    value = var.(var_name);
    value_name = replace(var_name, "_", " ");
    value_units = var.Properties.VariableUnits;

    % Get category variable
    if nargin < 4 || isempty(categorizer_name)
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
        % cat_units = cat_var.Properties.VariableUnits;
        cat_names = " " + replace(categorizer_name + " = " + string(cat_options), "_", " ");
    end

    % Get normalizer
    if nargin < 3 || isempty(normalizer_name)
        % do nothing
    else
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
    
    if strcmp(show, 'off')
        fprintf("Saving Stats...\n");
    else
        fprintf("Plotting Stats...\n");
    end
    fig_name = "Stats:" + value_name;
    if any(strcmpi('pdf', varargin))
        fig_name = fig_name + " vs Distribution Comparison";
    end
    fig = figure(Name=fig_name, Visible=show);
    hold on
    for idx=1:numel(cat_options)
        sub_value = value(categorizer == cat_options{idx});
        h = histogram(sub_value, varargin{:}, LineWidth=obj.LINE_WIDTH, LineStyle=obj.LINE_STYLE_SOLID, DisplayName="Histogram" + cat_names(idx));

        % If normalization is pdf also plot normal distribution with same mean 
        % and std.
        idx_norm = cellfun(@(x) (isstring(x) || ischar(x)) && strcmp(x, "Normalization"), varargin);
        idx_norm_type = find(idx_norm, 1);
        if ~isempty(idx_norm_type) && strcmpi(varargin{idx_norm_type + 1}, "pdf")         
            % Match distribution color to histogram color
            ax = ancestor(h,'axes');
            co = ax.ColorOrder; % Get axes color order
            i_color = ax.ColorOrderIndex - 1; % Get the color index used for this object
            i_color = mod(i_color - 1, size(co, 1)) + 1; % Wrap in case of cycling
            actualColor = co(i_color, :);
            
            txt = "";
            h.FaceAlpha = 0.5;

            if isempty(model_pdfs)
                [~, ~, bw] = ksdensity(sub_value);
                [f1, xi] = ksdensity(sub_value, bw);
                [f2, ~ ] = ksdensity(sub_value, xi, 'Bandwidth', 1.5*bw);
                [f3, ~ ] = ksdensity(sub_value, xi, 'Bandwidth', 0.7*bw);
                plot(xi, f1, "-", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="KDE default" + cat_names(idx));
                plot(xi, f2, "--", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="KDE smoother" + cat_names(idx));
                plot(xi, f3, ":", LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="KDE sharper" + cat_names(idx));
                % txt = txt +  sprintf("KDE");
            end

            z_limits = h.BinLimits;
            z = linspace(z_limits(1), z_limits(2), 100);
            
            if any(strcmp("normal", model_pdfs))
                [mu, sigma, muCI, sigmaCI] = normfit(sub_value);
                f_norm = normpdf(z, mu, sigma);
                plot(z, f_norm, LineStyle="-" + obj.MARKERS(1), LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Normal Distribution" + cat_names(idx));
                txt = txt + ...
                      sprintf("Normal: mu=%.2f(%.2f-%.2f), sigma=%.2f(%.2f-%.2f)\n", ...
                              mu, muCI(1), muCI(2), sigma, sigmaCI(1), sigmaCI(2));
            end

            if any(strcmp("lognormal", model_pdfs))
                [mu, sigma, muCI, sigmaCI] = normfit(log(sub_value));
                f_norm = normpdf(z, mu, sigma);
                f_lognorm = exp(f_norm);
                plot(z, f_lognorm, LineStyle="-" + obj.MARKERS(2), LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Log Normal Distribution" + cat_names(idx));
                txt = txt + ...
                      sprintf("LogNormal: mu*=%.2f(%.2f-%.2f), sigma*=%.2f(%.2f-%.2f)\n", ...
                              exp(mu), exp(muCI(1)), exp(muCI(2)), exp(sigma), exp(sigmaCI(1)), exp(sigmaCI(2)));
            end

            if any(strcmp("rayleigh", model_pdfs))
                [b, bCI] = raylfit(sub_value);
                f_rayl = raylpdf(z, b);
                plot(z, f_rayl, LineStyle="-" + obj.MARKERS(3), LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Rayleigh Distribution" + cat_names(idx));
                txt = txt + ...
                      sprintf("Rayleigh: b=%.2f(%.2f-%.2f)\n", ...
                              b, bCI(1), bCI(2));
            end

            if any(strcmp("gamma", model_pdfs))
                if any(sub_value < 0)
                    error(PROST.PROSTError("SamplesVariable", "NegativeValue", ...
                        "To compare to a Gamma distribution the data must be positive."));
                end
                [p, pCI] = gamfit(sub_value);
                f_gamma = gampdf(z, p(1), p(2));
                plot(z, f_gamma, LineStyle="-" + obj.MARKERS(4), LineWidth=obj.LINE_WIDTH, Color=actualColor, DisplayName="Gamma Distribution" + cat_names(idx));
                txt = txt + ...
                      sprintf("Gamma: a=%.2f(%.2f-%.2f),  b=%.2f(%.2f-%.2f)\n", ...
                              p(1), pCI(1, 1), pCI(2, 1), p(2), pCI(1, 2), pCI(2, 2));
            end

            text(0, 1 - (idx-1)*0.1, txt, "Units", "normalized", Color=actualColor, VerticalAlignment="top");
        end
    end
    title(replace(fig.Name, "_", " "), "Bin Method: " + h.BinMethod)
    xlabel(value_name + " [" + value_units + "]")
    ylabel(h.Normalization)
    legend(FontSize=obj.FONT_SIZE)
    hold off
    if strcmp(show, 'off')
        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/Stats");
        PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
        fprintf("All figures saved.\n");
    end
end