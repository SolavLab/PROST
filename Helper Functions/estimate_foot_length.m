function foot_length = estimate_foot_length(steps)
%ESTIMATE_FOOT_LENGTH estimates the foor length from the COP.
%   Based o:n Lugade & Kaufman, 2019; Han, Paik & Im, 2019:
%   COP excursion in the anterior-posterior direction covers approximately 
%   83% of the foot length.
%   Input :
%       steps - the steps measurements for all trials of the given foot. 
%               A N x 1 struct array containing the step info of the N 
%               trials. This is the processed and interpolated data so x is 
%               the walking direction.
%   Output :
%       foot_length - the estimated foot length in [m]
    
    % Calculate mean COP length in walking direction
    cop = [steps(:).COP];
    cop_x = cell2mat({cop(:).x}');
    % cop_y = cell2mat({cop(:).y}');
    % cop_v = [max(cop_x, [], 2) - min(cop_x, [], 2) max(cop_y, [], 2) - min(cop_y, [], 2)];
    % d = vecnorm(cop_v, 2, 2);
    d = max(cop_x, [], 2) - min(cop_x, [], 2);
    mead_d = mean(d);
    
    % Estimate foot length from COP
    foot_length = mead_d / 0.83;

    % Convert to [m]
    foot_length = convert_units(foot_length, cop(1).unit, "m");
end

