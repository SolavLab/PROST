function data = build_analysis_table(analyzer)
% DATA = BUILD_ANALYSIS_TABLE(ANALYZER)
% Builds the table for statistical analysis from the IPD table of the analyzer:
% one row per leg with its IDs, predictors, fitted ROS parameters (absolute and
% normalized by height) and the number of included steps.
%
% Input :
%   analyzer - the PROSTAnalyzer object.
%
% Example usage :
%   data = PROST.lme.build_analysis_table(PROSTAnalyzer)

    % Read from IPDTable
    radius = table2array(analyzer.get_IPD_samples("Radius"));
    residual = table2array(analyzer.get_IPD_samples("Residual_rms"));
    predictors = analyzer.get_predictors();
    body_height = PROST.utils.convert_units(predictors.Height, "m", "mm");
    angle_start = table2array(analyzer.get_IPD_samples("Ang_start"));
    angle_end = table2array(analyzer.get_IPD_samples("Ang_end"));
    arc_span = table2array(analyzer.get_IPD_samples("Arc_length"));

    % Create table for statistical analysis
    data = table;

    % Random and Fixed Effects Parameters
    data.DatasetID = table2array(analyzer.get_IPD_samples("Dataset_id"));
    data.ParticipantID = table2array(analyzer.get_IPD_samples("Participant_id"));
    data.ParticipantIDGlobal = data.DatasetID.*1000 + data.ParticipantID;
    data.Leg = categorical(table2array(analyzer.get_IPD_samples("Side")));
    data.DatasetID = categorical(data.DatasetID);
    data.ParticipantID = categorical(data.ParticipantID);
    data.ParticipantIDGlobal = categorical(data.ParticipantIDGlobal);

    % Predictors
    data = [data predictors];

    % Parameters to analyze
    data.R = radius;
    data.R_H = radius ./ body_height;
    data.log_R_H = log(data.R_H);
    data.log_R = log(radius); % with log_H, the scaling model of r on H
    data.log_H = log(body_height);
    data.log_M = log(data.Mass); % with log_H, mass enters the log_R models as an elasticity
    data.log_L = log(data.Leg_length);
    data.AngleStartDeg = angle_start;
    data.AngleStartRad = deg2rad(angle_start);
    data.AngleEndDeg = angle_end;
    data.AngleEndRad = deg2rad(angle_end);
    data.ArcSpanDeg = arc_span;
    data.ArcSpanRad = deg2rad(arc_span);
    data.u_c = table2array(analyzer.get_IPD_samples("Center_horizontal")); % [mm], fore-aft centre position

    % Parameters for weights from RMS and Number of Steps
    data.RMS = residual; % RMS radial residual

    % Compute number of steps for each leg
    for dataset_id=1:4
        dataset = analyzer.get_dataset(dataset_id);
        dataset_idx = find(dataset_id == double(string(data.DatasetID)));
        for idx = dataset_idx'
            participant_id = double(string(data.ParticipantID(idx)));
            side = data.Leg(idx);
            steps = dataset.Data(participant_id == [dataset.Data.Participant_id]).Uniform_data.(string(side)).step;
            if isempty(steps) || ~dataset.Data(participant_id == [dataset.Data.Participant_id]).Uniform_data.(string(side)).Is_included
                error("Side not included even though it is in table")
            end
            data.n_steps(idx) = sum([steps.Is_included]);
        end
    end

    % Mean measured speed of the valid steps of each leg, and its dimensionless
    % (Froude) form v* = v / sqrt(g * leg length), comparable across body sizes
    speeds = analyzer.get_step_speeds();
    speeds.Side = categorical(speeds.Side);
    leg_speed = groupsummary(speeds, ["Dataset_id" "Participant_id" "Side"], @(v) mean(v, "omitnan"), "Speed");
    leg_speed = renamevars(leg_speed, "fun1_Speed", "Speed");
    keys = table(double(string(data.DatasetID)), double(string(data.ParticipantID)), data.Leg, ...
                 'VariableNames', {'Dataset_id', 'Participant_id', 'Side'});
    [found, loc] = ismember(keys, leg_speed(:, ["Dataset_id" "Participant_id" "Side"]));
    assert(all(found), "Some legs of the analysis table have no valid steps in get_step_speeds.")
    data.Speed = leg_speed.Speed(loc); % [km/hour]
    speed_mps = PROST.utils.convert_units(data.Speed, "km", "m") ./ PROST.utils.convert_units(1, "hour", "second");
    data.v_star = speed_mps ./ sqrt(9.81 * data.Leg_length); % Leg_length [m]
end
