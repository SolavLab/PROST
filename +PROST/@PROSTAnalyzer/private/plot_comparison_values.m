function [h, h_literature, literature] = plot_comparison_values(obj, ax, m, range, normalizer_name, response_name, plot_unit, opts)
%PLOT_COMPARISON_VALUES draws reference values on ax for a ROS response: the
% zero line, the sample median and IQR, and literature values where published
% ones exist for that response and normalization. Shared by
% plot_predictors_vs_responses (response on the y-axis) and
% plot_summary_histogram (response on the x-axis).
%
% Input :
%   m - the sample median.
%   range - [Q1 Q3] of the sample.
%   normalizer_name - name of the IPD variable the response is normalized by,
%                     or empty when it is not normalized. Selects, with
%                     response_name, which literature values apply.
%   response_name - name of the IPD response variable.
%   plot_unit - unit of the plotted (normalized) response. Literature values
%               stored in another unit are converted with convert_units; a
%               value that cannot be converted is skipped with a warning.
%
% Name-Value pair options :
%   orientation - axis that carries the response: "horizontal" draws
%                 horizontal lines (response on y), "vertical" draws vertical
%                 lines (response on x). Default: "horizontal".
%   show_zero - whether to draw the zero line. Default: true.
%   show_literature - whether to draw the literature values. Default: true.
%   iqr_color - face colour of the IQR band. Default: obj.COLOR_IQR.
%   iqr_alpha - face alpha of the IQR band. Default: 0.3.
%
% Output :
%   h - handles meant for a legend: zero, median, IQR and each literature line
%       (named by its source).
%   h_literature - handles of the drawn literature lines. Dark grey: comparable
%                  to PROST; light grey: not directly comparable. Dashed or
%                  dotted (odd or even Tag of literature_values) tells the two
%                  sources of a pair apart.
%   literature - the rows of literature_values that were drawn, in the plotted
%                unit.
    arguments
        obj
        ax
        m                   (1, 1) double
        range               (1, 2) double
        normalizer_name     = []
        response_name       (1, 1) string = "Radius"
        plot_unit           (1, 1) string = "mm"
        opts.orientation    (1, 1) string {mustBeMember(opts.orientation, ["horizontal" "vertical"])} = "horizontal"
        opts.show_zero      (1, 1) logical = true
        opts.show_literature (1, 1) logical = true
        opts.iqr_color      (1, 3) double = obj.COLOR_IQR
        opts.iqr_alpha      (1, 1) double = 0.3
    end

    if opts.orientation == "horizontal"
        const_line = @(varargin) yline(ax, varargin{:});
        const_region = @(varargin) yregion(ax, varargin{:});
    else
        const_line = @(varargin) xline(ax, varargin{:});
        const_region = @(varargin) xregion(ax, varargin{:});
    end

    h = gobjects(0);
    if opts.show_zero
        h = [h const_line(0, Color=obj.LINE_COLOR, LineWidth=obj.LINE_WIDTH, DisplayName="Zero")];
    end

    % Sample median and IQR
    h = [h const_line(m, Color=obj.COLOR_MEDIAN, LineWidth=obj.LINE_WIDTH, DisplayName="Median")];
    h = [h const_region(range(1), range(2), FaceAlpha=opts.iqr_alpha, FaceColor=opts.iqr_color, EdgeColor="none", DisplayName="IQR")];

    % Literature values that apply to this response and normalization
    h_literature = gobjects(0);
    literature = literature_values();
    if isempty(normalizer_name)
        normalizer_name = "";
    end
    literature = literature(literature.Response == response_name & literature.Normalizer == normalizer_name, :);
    if ~opts.show_literature
        literature = literature([], :);
    end
    literature = to_plot_unit(literature, plot_unit);

    % Colour marks comparability with PROST, line style tells the sources of a
    % pair apart; no solid style, which marks the median and zero
    for k = 1:height(literature)
        if literature.Comparable(k)
            color = obj.COLOR_DEFAULT_DARKGREY;
        else
            color = obj.COLOR_DEFAULT_GREY;
        end
        if mod(literature.Tag(k), 2) == 1
            style = obj.LINE_STYLE_DASHED;
        else
            style = obj.LINE_STYLE_DOTTED;
        end
        h_literature(k) = const_line(literature.Value(k), ...
            Color=color, ...
            LineWidth=obj.LINE_WIDTH, ...
            LineStyle=style, ...
            DisplayName=literature.Source(k));
    end
    h = [h h_literature];
end

function literature = to_plot_unit(literature, plot_unit)
%TO_PLOT_UNIT converts each literature value to plot_unit. Values already in
% plot_unit are kept as they are (this covers dimensionless "-"); values whose
% unit convert_units cannot convert are dropped with a warning, never drawn at
% a wrong scale.
    keep = true(height(literature), 1);
    for k = 1:height(literature)
        if literature.Unit(k) == plot_unit
            continue
        end
        try
            literature.Value(k) = PROST.utils.convert_units(literature.Value(k), literature.Unit(k), plot_unit);
            literature.Unit(k) = plot_unit;
        catch
            keep(k) = false;
            PROST.PROSTWarning.warn("LiteratureValue", "UnitMismatch", ...
                "Literature value '%s' is in %s and cannot be converted to the plotted unit %s; it is not drawn.", ...
                literature.Source(k), literature.Unit(k), plot_unit);
        end
    end
    literature = literature(keep, :);
end

function literature = literature_values()
%LITERATURE_VALUES returns the published comparison values, one row each:
% the response they compare to, the normalizer ("" when not normalized), the
% value in the source's unit ("-" for a ratio of like units), the source, and a
% fixed numeric tag that sets the line style (odd dashed, even dotted), and
% whether the value is directly comparable to PROST (dark vs light grey).
%
% Radius / Height: median height-normalised radii of measured ROS of able-bodied
% walking. Ankle-foot ROS (CoP in the shank, knee-ankle, CS, as in PROST):
% Hansen & Childress, 2004 (A) "Effects of shoe heel height..." and Hansen &
% Meier, 2010 "Roll-over shapes of the ankle-foot and knee-ankle-foot systems of
% able-bodied children". Knee-ankle-foot ROS (CoP in a hip-ankle CS, not
% directly comparable to PROST): Hansen et al., 2004 (B) "Roll-over shapes of
% human locomotor systems: effects of walking speed" and Hansen & Childress,
% 2005 "Effects of adding weight to the torso...".
%
% Center_horizontal / Height: median height-normalised centre horizontal
% coordinates of measured knee-ankle-foot ROS of able-bodied walking (CoP in a
% hip-ankle CS, not directly comparable to the shank-based PROST ankle-foot
% ROS): Hansen et al., 2004 (B) and Hansen & Childress, 2005, as above.
%
% Center_horizontal: arc-centre offsets anterior to the tibial axis imposed on
% rigid arc feet (design values, not measured ROS): Adamczyk et al., 2006,
% p. 3957 and Adamczyk & Kuo, 2013, p. 2725.
    rows = {
        "Radius",            "Height", 0.19,  "-", "Hansen, 2004 (A)", 1, true
        "Radius",            "Height", 0.22,  "-", "Hansen, 2010",     2, true
        "Radius",            "Height", 0.15,  "-", "Hansen, 2004 (B)", 3, false
        "Radius",            "Height", 0.16,  "-", "Hansen, 2005",     4, false
        "Center_horizontal", "Height", 0.006, "-", "Hansen, 2004 (B)", 3, false
        "Center_horizontal", "Height", 0.011, "-", "Hansen, 2005",     4, false
        "Center_horizontal", "",       0.076, "m", "Adamczyk, 2006",   5, true
        "Center_horizontal", "",       0.058, "m", "Adamczyk, 2013",   6, true
        };
    literature = cell2table(rows, VariableNames=["Response" "Normalizer" "Value" "Unit" "Source" "Tag" "Comparable"]);
    literature = convertvars(literature, ["Response" "Normalizer" "Unit" "Source"], "string");
end
