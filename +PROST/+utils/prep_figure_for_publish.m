function prep_figure_for_publish(fig, opts)
%PREP_FIGURE_FOR_PUBLISH prepares the figure for publishing.
%   1. Removes all titles from the figure.
%   2. Sets font to "Times New Roman", 12 pt.
%   3. Sets figure size and paper size.
%
% Input :
%   fig - handle of the figure to save.
%
%   Default values for optional Name-Value pairs:
%       FontUnits        = "points"
%       FontSize         = 12 (pt)
%       FontName         = "Times New Roman"
%       FigUnits         = "points"
%       FigWidth         = 468 (pt)
%       FigHeight        = [] (determined by the aspect ratio of the figure).
%       ShowTextbox      = "on"
%       ShowLegend       = "on"
%       ShowAxisTitle    = "off" (inner most titles).
%       PaperOrientation = "portrait"

    arguments
        fig
        opts.FontUnits        (1, 1) string = "points"
        opts.FontSize         (1, 1) double = 12
        opts.FontName         (1, 1) string = "Times New Roman"
        opts.FigUnits         (1, 1) string = "points"
        opts.FigWidth         {mustBeScalarOrEmpty} = []
        opts.FigHeight        {mustBeScalarOrEmpty} = []
        opts.ShowTextbox      (1, 1) matlab.lang.OnOffSwitchState = true
        opts.ShowLegend       (1, 1) matlab.lang.OnOffSwitchState = true
        opts.ShowAxisTitle    (1, 1) matlab.lang.OnOffSwitchState = false
        opts.PaperOrientation (1, 1) string = "portrait"
    end
    
    % Prep input arguments
    opts.FontUnits = normalize_string(opts.FontUnits);
    mustBeMember(opts.FontUnits, ["inches" "centimeters" "points" "pixels" "normalized"])
    opts.FigUnits = normalize_string(opts.FigUnits);
    mustBeMember(opts.FigUnits, ["inches" "centimeters" "points" "pixels"])
    opts.PaperOrientation = normalize_string(opts.PaperOrientation);
    mustBeMember(opts.PaperOrientation, ["portrait" "landscape"])

    % Default width and height
    % * \textwidth=468.0pt
    % * \textheight=622.0pt
    default_widths = dictionary(["points" "pixels" "inches" "centemeters"], ...
                                [468      624      6.5      16.51]);
    default_heights = dictionary(["points" "pixels" "inches" "centemeters"], ...
                                 [622      829.1260 8.6389   21.943]);
       
    % Undock figure
    fig.Units = "centimeters";
    fig_pos = fig.Position;
    fig.WindowStyle = 'normal';
    fig.Position = fig_pos;

    % Set figure width  height values
    fig.Units = opts.FigUnits;
    if isempty(opts.FigWidth)
        if opts.PaperOrientation == "portrait"
            opts.FigWidth = default_widths(opts.FigUnits);
        else
            opts.FigWidth = default_heights(opts.FigUnits);
        end
    end
    if isempty(opts.FigHeight)
        scale = opts.FigWidth / fig.Position(3);
        opts.FigHeight = scale*fig.Position(4);
    end

    % Set figure and paper size
    fig.Renderer = 'painters';
    fig.PaperUnits = opts.FigUnits;
    fig.Units = opts.FigUnits;
    fig.Position = [0 0 opts.FigWidth opts.FigHeight];
    fig.PaperSize = [opts.FigWidth opts.FigHeight];    
    % fig.PaperOrientation = opts.PaperOrientation;
    fig.PaperPositionMode = "manual";
    fig.PaperPosition = [0 0 opts.FigWidth opts.FigHeight];

    % Set axis params
    ax = findall(fig, 'Type', 'axes');
    for k = 1:numel(ax)
        % Set fonts
        ax(k).FontSizeMode = "manual";
        ax(k).LabelFontSizeMultiplier = 1;
        ax(k).TitleFontSizeMultiplier = 1;
        ax(k).FontUnits = opts.FontUnits;
        ax(k).FontSize = opts.FontSize;
        ax(k).FontName = opts.FontName;

        % Remove text boxes
        if ~opts.ShowTextbox
            textbox = findall(ax(k).Children, 'Type', 'text');
            for j=1:numel(textbox)
                textbox(j).Visible = "off";
            end
        end

        % Remove axis titles
        if ~opts.ShowAxisTitle
            ax(k).Title.Visible = "off";
            ax(k).Subtitle.Visible = "off";
        end
    end
    
    % Remove legend or set font size
    lgd = findall(fig, 'Type', 'legend');
    if ~opts.ShowLegend
        for k = 1:numel(lgd)
            lgd(k).Visible = "off";
        end
    else
        for k = 1:numel(lgd)
            lgd(k).FontSize = opts.FontSize;
        end
    end
    
    % Set colorbar font size
    cl = findall(fig, 'Type', 'colorbar');
    for k = 1:numel(cl)
        cl.FontSize = opts.FontSize;
    end

    % Remove tiledlayout titles
    tl = findall(fig, 'Type', 'tiledlayout');
    for k = 1:numel(tl)
        tl(k).Title.Visible = "off";
        tl(k).Subtitle.Visible = "off";
    end

    % Shorten y label
    if tl(1).GridSize(1) >= 2 && tl.GridSize(2) >= 3
        for k = 1:numel(ax)
            ax(k).YLabel.String = shorten_label(ax(k).YLabel.String, 10);
        end
    end
end


% --------- helper functions ------------
function s = normalize_string(s)
    if ~isempty(s), s = strip(lower(s)); end   
end

function x = if_else_empty(x)
    if isempty(x), x = 0; end 
end

function out = shorten_label(str, max_len)
    % Make sure str is char
    str = char(str);

    % Find delimiter positions
    i1 = strfind(str, ' [');
    i2 = strfind(str, ' / ');

    i1 = if_else_empty(i1);
    i2 = if_else_empty(i2);

    % Pick earliest valid delimiter
    cuts = [i1, i2];
    cuts = cuts(cuts > 0);

    if isempty(cuts)
        prefix = str;
        suffix = '';
    else
        cut = min(cuts);
        prefix = str(1:cut-1);
        suffix = str(cut:end);
    end

    % Shorten only prefix
    if length(prefix) > max_len
        prefix = prefix(1:max_len);
    end

    out = [prefix suffix];
end
