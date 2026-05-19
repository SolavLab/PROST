function prep_figure_for_publish(fig, opts)
%PREP_FIGURE_FOR_PUBLISH prepares the figure for publishing.
%   1. Removes all titles from the figure.
%   2. Sets font to "Times New Roman", 12 pt.
%   3. Sets figure size and paper size.
%   Default values for optional Name-Value pairs:
%       FontUnits   = "points"
%       FontSize    = 12 (pt)
%       FontName    = "Times New Roman"
%       Units       = "points"
%       Width       = 480 (pt)
%       Height      = 622 (pt)
% Input:
%   fig - handle of the figure to save.

    arguments
        fig
        opts.FontUnits  (1, 1) string = "points"
        opts.FontSize   (1, 1) double = 12
        opts.FontName   (1, 1) string = "Times New Roman"
        opts.Width      (1, 1) double = 480
        opts.Height     (1, 1) double = 622
    end

    % Set figure size
    fig.WindowStyle = 'normal';
    fig.Units="points";
    fig.Position = [0 0 opts.Width opts.Height];
    fig.PaperUnits="points";
    fig.PaperSize = [opts.Width opts.Height];
    fig.PaperPosition = [0 0 opts.Width opts.Height];

    % Set fonts
    ax = findall(fig, 'Type', 'axes');
    for k = 1:numel(ax)
        ax(k).FontUnits = opts.FontUnits;
        ax(k).FontSize = opts.FontSize;
        ax(k).FontName = opts.FontName;
        % title(ax(k), '');
    end

    % Remove titles
    ax = findall(fig, 'Type', 'tiledlayout');
    title(ax(1), '');
end