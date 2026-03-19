function make_point_cloud(obj, dataset_id, participant_id, side, good_step_nums, row_number, anatomical_side)
%MAKE_POINT_CLOUD receives an array of good "steps" (structures)
% and extracts all the ROS points in the sagital (XZ) plane into a
% "point_cloud" - a 2 x length(good_steps)*101 matrix. The data is
% saved into the point_clouds property.
%   Input :
%       good_steps - a structure array of the good steps from
%                    multiple measurements for a given participant.
%       entry_number - the row in the samples table that the point
%                      cloud corresponds to.
%       anatomical_side - the anatomical side to use for fitting. Either
%                         "lateral" (default), "medial" or "mean".

    % Cut leading and trailing data points of each step since they
    % contain artifacts from beginning and end of the step
    n_temporal = 101;
    cut_length = 15;
    trial_size = (n_temporal - 2*cut_length);

    if nargin < 4
        anatomical_side = "lateral";
    end
    
    % Get step
    dataset = obj.get_dataset(dataset_id);

    % for each of the good steps we want to save the x and z values
    point_cloud = zeros(length(good_step_nums)*trial_size, 3);
    for step_idx=1:length(good_step_nums)
        step_num = good_step_nums(step_idx);

        step = dataset.Data(participant_id).Uniform_data.(side).step(step_num);

        % add this step to the point cloud.
        idx = (1+cut_length:numel(step.Shank_cop.(anatomical_side).u)-cut_length);
        point_cloud((1 + (step_idx - 1)*trial_size):(step_idx*trial_size), :) = [step.Shank_cop.(anatomical_side).u(idx)', step.Shank_cop.(anatomical_side).w(idx)', step.source.original_trial_number_in_database + 0.*idx'];
    end

    % Check for NaN or Inf values in the point cloud
    num_NaNs = sum(isnan(point_cloud(:)));
    num_Inf = sum(isinf(point_cloud(:)));
    total_points = numel(point_cloud);
    if ((num_NaNs > 0) || (num_Inf > 0))
        if ((num_NaNs > 0.1*total_points) || (num_Inf > 0.1*total_points))
            throw(PROST.PROSTError("PointCloud", "TooManyNaNInfs",...
                "Too many NaNs or Infs in point cloud. More than 10\%.\n" +...
                "Number of NaN values: %d out of %d\n" + ...
                "Number of Inf values: %d out of %d\n", num_NaNs, total_points, num_Inf, total_points));
        end

        % Remove rows with NaN or Inf values
        point_cloud(any(isnan(point_cloud) | isinf(point_cloud), 2), :) = [];
    end

    % Add to point_clouds cell array. Each entry corresponds to the
    % entry number in the samples table and the
    if isempty(point_cloud)
        throw(PROST.PROSTError("PointCloud", "EmptyPointCloud", ...
            "Something went wrong with the point cloud calculation. It is empty."));
    end
    obj.PointClouds(row_number) = {point_cloud};
end