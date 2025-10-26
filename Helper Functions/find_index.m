function [xi, index] = find_index(X, val)
%FIND_INDEX finds the index of the closest value of X to val
%   This is a helper function to find the index of a value in an array,
%   where X represents measured data and therefore the event does not
%   exactly match the values in X.
%   Example usage: [~, IC_index] = find_index(IC_time, time_vector)
    [xi, index] = min(abs(val - X));
end

