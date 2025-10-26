function d = diffp(x, pad)
% DIFFP wrapper function for diff that pads the result to bring it back to
% the original length
%   Input : 
%       x - Data to diff
%       pad - Value to pad. Must be of the same type as x's elements.
%             Default: 0.

% default value for pad
if nargin < 2
    pad = 0;
end

% check pad is of the same type as x elements
assert(class(pad) == class(x(1)));

% calculate diff and pad
d = diff(x);
sz = size(d);
sz = sz(2:end);
d = [d, repmat(pad, sz)];
end

