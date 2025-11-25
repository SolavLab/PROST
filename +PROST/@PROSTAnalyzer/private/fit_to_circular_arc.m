function fit_to_circular_arc(obj, entry_number)
%FIT_TO_CIRCULAR_ARC circle fitting from BAPAT 2022
% First approximate solution based on linear least squares approach
% - Coope 1993 paper.
% I got this code from a file named "main_ROS_curve.m" that I got
% from Dana.
% This function receives the 2D point cloud and fits this to a
% circular arc, saves the parameters of the fitted circular arc and fills the 
% samples table with them.
% Input :
%   entry_number - the row number in the samples table where the
%                  fitted data is entered.
%  Output :
%   circular arc parameters:
%       radius [m]
%       center_x [m]
%       center_z [m]
%       ang_start [deg]
%       ang_end [deg]
%       arc_length [deg]

    % Check if participant exists
    if entry_number > obj.SamplesTableSize
        error(PROST.PROSTError("SamplesTable", "OutOfBounds", ...
            "Entry number %d is too large.\nSamples table has %d entries.", entry_number, obj.SamplesTableSize));
    end

    % Check for NaN or Inf values in the point cloud
    % get point cloud of corresponding entry in samples table.
    point_cloud = obj.PointClouds{entry_number};
    point_cloud = point_cloud(:, 1:2);
    if any(isnan(point_cloud(:))) || any(isinf(point_cloud(:)))
        error(PROST.PROSTError("PointCloud", "ContainsNaNInfs", ...
            "Point cloud contains NaN or Inf values"));
    end
    x = point_cloud(:, 1);
    z = point_cloud(:, 2);

    % 1) Find first approximate solution based on LLS approach
    % Coope 1993 paper:
    n_points = size(point_cloud, 1);
    B = [[x z]'; ones(1, n_points)]';
    d = x.^2 + z.^2;
    y = (B'*B)\(B'*d); % B is rectangular matrix hence multiplied by B'
    center_x = y(1)/2;
    center_y = y(2)/2;
    y(3) = 0; % Actual residual = y(3), but set to zero after first approximation
    ros_rad = sqrt(y(3) + center_x^2 + center_y^2);

    % 2) Optimize the solution:
    % Initial guess from linear least squares approach
    initial_guess = [center_x; center_y; ros_rad];
    % options = optimoptions(options,'TolFun',1e-10,'TolX',1e-10,'MaxFunEvals',100000,'MaxIter',40000);
    % Ensure initial guess does not contain NaN or Inf values
    if any(isnan(initial_guess)) || any(isinf(initial_guess))
        error(PROST.PROSTError("CircleFit", "ContainsNaNInfs", ...
            "Initial guess contains NaN or Inf values"));
    end

    % Function that calculates non-linear LSQ residual.
    % (this function is also copied from Dana's code)
    % objective_func = @(params)(params(3) - sqrt((point_cloud(:, 1) - params(1)).^2 + (point_cloud(:, 2) - params(2)).^2));
    objective_func = @(params)sum((params(3) - sqrt((x - params(1)).^2 + (z - params(2)).^2)).^2);

    % Unconstrained Least squares nonlinear fit algorithm
    % options = optimoptions('lsqnonlin', 'Display', 'off');
    % [params, residual] = lsqnonlin(objective_func, initial_guess,[],[], options);
    options = optimoptions('fminunc', 'Display', 'off');
    [params, residual] = fminunc(objective_func, initial_guess, options);
    % obj.PointClouds{entry_number}(:, 3) = residual;

    % Normalize residual by number of data points
    residual_norm = sqrt(residual / n_points);

    % 3) Get ROS parameters: angles, arc length:
    % find ROS start point and end point
    [~, ind] = min(x);
    ros_start = point_cloud(ind, :);
    [~, ind] = max(x);
    ros_end = point_cloud(ind, :);

    % circle fitting parameters
    radius = params(3);
    center_x = params(1);
    center_z = params(2);
    center = [center_x center_z];

    % calculate vectors from center to start and end points
    vec_start = ros_start - center;
    vec_end = ros_end - center;

    % calculate the arc angles (relative to the vector from the center straight down) and arc length
    cross_vec = [0, -1, 0];
    cross_product = cross(cross_vec, [vec_start/norm(vec_start), 0]);
    ang_start = asind(cross_product(3));
    cross_product = cross(cross_vec, [vec_end/norm(vec_end), 0]);
    ang_end = asind(cross_product(3));
    arc_length = ang_end - ang_start;

    % 4) Fill samples table
    obj.SamplesTable.Radius(entry_number) = radius;
    obj.SamplesTable.Center_x(entry_number) = center_x;
    obj.SamplesTable.Center_z(entry_number) = center_z;
    obj.SamplesTable.Ang_start(entry_number) = ang_start;
    obj.SamplesTable.Ang_end(entry_number) = ang_end;
    obj.SamplesTable.Arc_length(entry_number) = arc_length;
    obj.SamplesTable.Residual(entry_number) = residual_norm;
end