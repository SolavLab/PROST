function shank_data = convert_to_shank_frame(data, knee, ankle)
%CONVEWRT_TO_SHANK_FRAME transforms the data to the shank
% coordinate frame. The frame has the ankle as its origin with the
% x direction pointing to the direction of walking, the z direction
% is from the ankle to the knee (up) and the y direction completes
% a right-handed system.
% Input :
%   data - the data to transform. Includes the 3-dimensional data in 3 separate
%          fields: x, y, z.
%   knee - the knee trajectories to use for the shank frame.Includes the 
%          3-dimensional data in 3 separate fields: x, y, z.
%   ankle - the ankle trajectories to use for the shank frame. Includes the 
%           3-dimensional data in 3 separate fields: x, y, z.
% Output :
%   shank_cop - the COP in the Shank coordinate frame.


    % The new z direction is the direction from the ankle to the knee
    new_z = [(knee.x - ankle.x);...
             (knee.y - ankle.y);...
             (knee.z - ankle.z)];
    new_z = new_z./vecnorm(new_z);

    % The new y direction is to the left (in the mediolateral direction)
    new_y = 0.*new_z + [0; 1; 0];

    % The new x is the cross product between them
    new_x = cross(new_y, new_z);

    % The origin of the new coordinate system is the location of the ankle
    new_origin = [ankle.x; ...
                  ankle.y; ...
                  ankle.z];

    % Get the original COP data
    data = [data.x; data.y; data.z];

    % Transform the COP into the new frame of reference in order to get the ROS
    data = data - new_origin;
    shank_data.x = dot(data, new_x);
    shank_data.y = dot(data, new_y);
    shank_data.z = dot(data, new_z);
end