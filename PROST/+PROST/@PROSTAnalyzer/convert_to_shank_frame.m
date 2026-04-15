function shank_data = convert_to_shank_frame(data, knee, ankle)
%CONVERT_TO_SHANK_FRAME transforms the data to the shank coordinate system. 
% The system has the ankle as its origin with u-v-w axes. The u direction 
% points to the direction of walking, the w direction is from the ankle to the 
% knee (up) and the v direction completes a right-handed system. Based on the
% shank-based coordinate system as described in Hansen 2010. 
% Input :
%   data - the data to transform. Includes the 3-dimensions in 3 separate
%          fields: x, y, z.
%   knee - the knee trajectories to use for the shank frame. Includes the 
%          3-dimensions in 3 separate fields: x, y, z.
%   ankle - the ankle trajectories to use for the shank frame. Includes the 
%           3-dimensions in 3 separate fields: x, y, z.
% Output :
%   shank_data - the data in the Shank coordinate frame with fields: u-v-w.

    % The w direction is the direction from the ankle to the knee
    w = [(knee.x - ankle.x);...
             (knee.y - ankle.y);...
             (knee.z - ankle.z)];
    w = w ./ vecnorm(w);

    % The temporary v direction is the lab y direction
    y = [0; 1; 0] + 0.*w;
    
    % The new u is the cross product between the temporary v and w to ensure
    % orthogonality
    u = cross(y, w);
    u = u ./ vecnorm(u);

    % The new v is the cross product between w and u to ensure orthogonality
    v = cross(w, u);
    v = v ./ vecnorm(v);

    % The origin of the new coordinate system is the location of the ankle
    new_origin = [ankle.x; ...
                  ankle.y; ...
                  ankle.z];

    % Get the original data
    data = [data.x; ...
            data.y; ... 
            data.z];

    % Transform the data into the new frame of reference in order to get the ROS
    data = data - new_origin;
    shank_data.u = dot(data, u);
    shank_data.v = dot(data, v);
    shank_data.w = dot(data, w);
end