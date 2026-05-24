function A_new = winsorize(A, p)
%WINSORIZE takes the data and winsorizes it according to the lower and upper
% percentiles of p. Winsorizing is moving data below the lower bound and above
% the upper bound percentiles to those percentiles. This allows for statistical
% analysis while mitigating outliers where the number of samples is not changed.
% This function exists since there is no native Matlab Winsorizing function/
% Input :
%   A -  the data to winsorize.
%           - If A is a matrix, then winsorize operates on each column of A 
%             separately.
%           - If A is a multidimensional array, then winsorize operates along 
%             the first dimension of A whose size does not equal 1.
%           - If A is a table, then winsorize operates on each variable of A 
%             separately.
%   p - a two-element row vector whose elements are in the interval [0, 100]. 
%       The first element indicates the lower percentile threshold, and the 
%       second element indicates the upper percentile threshold. The first 
%       element of p must be less than the second element.
% Output :
%   A_new - the Winsorized data in the same size and format as A.
    
    arguments
        A (1, :) double
        p (1, 2) double {mustBeGreaterThanOrEqual(p, 0), mustBeLessThanOrEqual(p, 100)}
    end

    % Check p is legal
    if p(1) >= p(2)
        error("The first element of p must be less than the second element.")
    end
    
    % prepare new data
    A_new = A;

    if istable(A)
        A = table2array(A);
    end

    % Calculate bounds
    low = prctile(A, p(1));
    low_idx = A < low;
    high = prctile(A, p(2));
    high_idx = A > high;

    % Winsorize
    A_new = A_new .* ~low_idx + low .* low_idx;
    A_new = A_new .* ~high_idx + high .* high_idx;
end

