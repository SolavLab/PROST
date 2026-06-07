function prep_figure_for_publish(fig, opts)
%PREP_FIGURE_FOR_PUBLISH prepares the figure for publishing.
%   1. Removes all titles from the figure.
%   2. Sets font to "Times New Roman", 12 pt.
%   3. Sets figure size and paper size.
% Input:
%   fig - handle of the figure to save.
%   Default values for optional Name-Value pairs:
%       FontUnits   = "points"
%       FontSize    = 12 (pt)
%       FontName    = "Times New Roman"
%       FigUnits    = "points"
%       FigWidth    = 468 (pt)
%       FigHeight   = [] (determined by the aspect ratio of the figure).
%       ShowTextbox = "on" (whether to show text boxes in the figure: "on" =
%                           show textbox, "off" = don't show).

    arguments
        fig
        opts.FontUnits     (1, 1) string = "points"
        opts.FontSize      (1, 1) double = 12
        opts.FontName      (1, 1) string = "Times New Roman"
        opts.FigUnits      (1, 1) string = "points"
        opts.FigWidth      {mustBeScalarOrEmpty} = []
        opts.FigHeight     {mustBeScalarOrEmpty} = []
        opts.ShowTextbox   (1, 1) matlab.lang.OnOffSwitchState = true
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
    switch opts.PaperOrientation
        case "portrait"
            if isempty(opts.FigWidth)
                opts.FigWidth = default_widths(opts.FigUnits);
            end
        case "landscape"
            if isempty(opts.FigWidth)
                opts.FigWidth = default_heights(opts.FigUnits);
            end
    end
    if isempty(opts.FigHeight)
        scale = opts.FigWidth / fig.Position(3);
        opts.FigHeight = scale*fig.Position(4);
    end

    % Set figure size
    fig.Units = "centimeters";
    fig_pos = fig.Position;
    fig.WindowStyle = 'normal';
    fig.Position = fig_pos;
    fig.Units = opts.FigUnits;
    fig.Position = [0 0 opts.FigWidth opts.FigHeight];
    fig.PaperType = "a4";
    fig.PaperPositionMode = "auto";
    fig.PaperOrientation = opts.PaperOrientation;

    % Set fonts
    ax = findall(fig, 'Type', 'axes');
    for k = 1:numel(ax)
        ax(k).FontUnits = opts.FontUnits;
        ax(k).FontSize = opts.FontSize;
        ax(k).FontName = opts.FontName;
        textbox = findall(ax(k).Children, 'Type', 'text');
        if ~opts.ShowTextbox
            for j=1:numel(textbox)
                textbox(j).Visible = "off";
            end
        end
        ax(k).Title.Visible = "off";
        ax(k).Subtitle.Visible = "off";
    end

    % Remove titles
    tl = findall(fig, 'Type', 'tiledlayout');
    for k = 1:numel(tl)
        tl(k).Title.Visible = "off";
        tl(k).Subtitle.Visible = "off";
    end

    if tl.GridSize(1) >= 2 && tl.GridSize(2) >= 3
        for k = 1:numel(ax)
            % Shorten Y label
            ax(k).YLabel.String = shortenLabel(ax(k).YLabel.String, 10);
        end
    end
end


% --------- helper functions ------------
function s_new = normalize_string(s)
    if isempty(s)
        s_new = s;
        return
    end

    s_new = strip(lower(s));
end

function out = shortenLabel(str, maxLen)

    % make sure str is char
    str = char(str);

    % find delimiter positions
    i1 = strfind(str, ' [');
    i2 = strfind(str, ' / ');

    i1 = ifelseEmpty(i1);
    i2 = ifelseEmpty(i2);

    % pick earliest valid delimiter
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

    % shorten only prefix
    if length(prefix) > maxLen
        prefix = prefix(1:maxLen);   % or smarter truncation if needed
    end

    out = [prefix suffix];
end

function x = ifelseEmpty(x)
    if isempty(x), x = 0; end
end