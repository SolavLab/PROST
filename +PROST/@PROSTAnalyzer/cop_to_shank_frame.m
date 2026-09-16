function shank_cop = cop_to_shank_frame(step, anatomical_side)
%COP_TO_SHANK_FRAME wrapper function to convert_to_shank_frame that specifically 
% transforms the CoP of the step to the shank frame. The frame has the ankle as 
% its origin with the x direction pointing to the direction of walking, the z 
% direction is from the ankle to the knee (up) and the y direction completes a 
% right-handed system.
% Input :
%   step - the step data to transform. Includes CoP and marker
%          trajectories.
%   anatomical_side - the anatomical side of the markers to use for
%                     the transformation. Either "lateral" (default),
%                     "medial" or "mean".
% Output :
%   shank_cop - the CoP in the Shank coordinate frame.
    if nargin < 2 || isempty(anatomical_side)
        anatomical_side = "lateral";
    end

    cop = step.COP;
    knee = step.Markers.Knee.(anatomical_side);
    ankle = step.Markers.Ankle.(anatomical_side);
    if isempty(ankle) ||  isempty(knee)
        throw(PROST.PROSTError("DataRecords", "MissingAnatomicalSide", ...
            "The step has no ankle/knee marker trajectories with anatomical side %s.", anatomical_side));
    end
    shank_cop = PROST.PROSTAnalyzer.convert_to_shank_frame(cop, knee, ankle);
end