function [capitalized] = capitalize(str)
%CAPITALIZE Capitalizes the first letter of each word in the string array
% str.
%   str - the string array to capitalize
capitalized = split(str);
capitalized = upper(extractBefore(capitalized,2)) + extractAfter(capitalized,1);
capitalized = join(capitalized);
end

