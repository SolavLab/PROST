function [index, xi] = find_index_from_value(X, val)
%FIND_INDEX_FROM_VALUE finds the index of the closest value of X to val
%   This is a helper function to find the index of a value in an array,
%   where X represents measured data and therefore the event does not
%   exactly match the values in X. Also returns the value in X that is 
%   closest to val.
%
% Inputs :
%   X - array of values to search through
%   val - the value to find the closest match for
%
% Outputs :
%   index - the index of the closest value in X to val
%   xi - the closest value in X to val
%
% Example usage : 
%       IC_index = find_index_from_value(time_vector, IC_time);
%       [IC_index, IC_time] = find_index_from_value(time_vector, IC_time);

    [xi, index] = min(abs(val - X));
end

