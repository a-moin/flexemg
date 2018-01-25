% Function Name: bipolarize_AM
%
% Description: Bipolarizes all hypervectors in the AM, i.e. any positive
% element is replaced by 1 and any negative by -1
%
% Arguments:
%   AM - The associative memory to be bipolarized
% 
% Returns:
%   None
%

function [] = bipolarize_AM(AM)
    classes = AM.keys;
    for i = 1:1:size(classes, 2)
        temp = AM(cell2mat(classes(i)));
        temp(temp >= 0) = 1;
        temp(temp < 0) = -1;
        AM(cell2mat(classes(i))) = temp;
    end
end