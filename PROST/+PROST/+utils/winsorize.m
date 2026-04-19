function data_new = winsorize(data, p)
%WINSORIZE takes the data and winsorizes it according to the lower and upper
% percentiles of p. Winsorizing is moving data below the lower bound and above
% the upper bound percentiles to those percentiles. This allows for statistical
% analysis while mitigating outliers where the number of samples is not changed.
% This function exists since there is no native Matlab Winsorizing function/
% Input :
%   data - the data to winsorize
%   p - a two-element row vector whose elements are in the interval [0, 100]. 
%       The first element indicates the lower percentile threshold, and the 
%       second element indicates the upper percentile threshold. The first 
%       element of p must be less than the second element.
% Ourpur :
%   data_new - the winsorized data.
    
    % Check p is legal
    if p(1) >= p(2)
        error("The first element of p must be less than the second element.")
    end

    % Calculate bounds
    low = prctile(data, p(1));
    high = prctile(data, p(2));

    % Winsorize
    data_new = data;
    data_new(data_new < low) = low;
    data_new(data_new > high) = high;
end

