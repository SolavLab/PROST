function style_axes(obj, ax)
%STYLE_AXES applies the toolbox font constants to ax, holds it and turns the
% grid on.
    ax.FontUnits = "points";
    ax.FontSize = obj.FONT_SIZE;
    ax.FontName = obj.FONT_NAME;
    ax.TitleFontWeight = obj.FONT_WEIGHT;
    ax.FontWeight = obj.FONT_WEIGHT;
    hold(ax, "on");
    grid(ax, "on");
end
