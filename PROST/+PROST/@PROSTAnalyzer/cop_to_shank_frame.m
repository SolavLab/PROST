function shank_cop = cop_to_shank_frame(step, anatomical_side)
%COP_TO_SHANK_FRAME transforms the COP of the step to the shank
% coordinate frame. The frame has the ankle as its origin with the
% x direction pointing to the direction of walking, the z direction
% is from the ankle to the knee (up) and the y direction completes
% a right-handed system.
% Input :
%   step - the step data to transform. Includes COP and marker
%          trajectories.
%   anatomical_side - the anatomical side of the markers to use for
%                     the transformation. Either "lateral" (default),
%                     "medial" or "mean".
% Output :
%   shank_cop - the COP in the Shank coordinate frame.


    % The new z direction is the direction from the ankle to the knee
    new_z = [(step.Markers.Knee.(anatomical_side).x - step.Markers.Ankle.(anatomical_side).x);...
        (step.Markers.Knee.(anatomical_side).y - step.Markers.Ankle.(anatomical_side).y);...
        (step.Markers.Knee.(anatomical_side).z - step.Markers.Ankle.(anatomical_side).z)];
    new_z = new_z./vecnorm(new_z);

    % The new y direction is to the left (in the mediolateral direction)
    new_y = 0.*new_z + [0; 1; 0];

    % The new x is the cross product between them
    new_x = cross(new_y, new_z);

    % The origin of the new coordinate system is the location of the ankle
    new_origin = [step.Markers.Ankle.(anatomical_side).x; ...
        step.Markers.Ankle.(anatomical_side).y; ...
        step.Markers.Ankle.(anatomical_side).z];

    % Get the original COP data
    cop = [step.COP.x; step.COP.y; zeros(size(step.COP.z))];

    % Transform the COP into the new frame of reference in order to get the ROS
    cop = cop - new_origin;
    shank_cop.x = dot(cop, new_x);
    shank_cop.y = dot(cop, new_y);
    shank_cop.z = dot(cop, new_z);
end