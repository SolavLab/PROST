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
%   shank_data - the data in the Shank coordinate frame.

    % The w direction is the direction from the ankle to the knee
    w = [(knee.x - ankle.x);...
             (knee.y - ankle.y);...
             (knee.z - ankle.z)];
    w = w ./ vecnorm(w);

    % The temporary v direction is the lab y direction
    temp_v = [0; 1; 0] + 0.*w;
    % new_y = proposed_y - new_w.*repmat(new_w' * proposed_y, 1, 3)'; % Gram-Schmidt process to ensure orthogonality with new z
    % if norm(new_y) < 1e-9
    %     % near-degenerate if shank vertical direction aligns with mediolateral axis
    %     PROST.PROSTWarning.warn('ShankFrame', 'DegenerateY', ...
    %         'The shank vertical direction is nearly aligned with the mediolateral axis. Using an alternative axis for the shank y direction.');
    %     new_y = [0; 0; 1] - new_w.*repmat(new_w' * [0; 0; 1], 1, 3)';
    % end
    % new_y = new_y / norm(new_y);
    
    % The new u is the cross product between the temporary v and w to ensure
    % orthogonality
    u = cross(temp_v, w);
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