% Function Name: find_closest_class
%
% Description: Looks through the AM and finds the closest class to ngram
%
% Arguments:
%   ngram - input ngram to be compared with each class in AM
%   AM - associative memory containing gesture classes
% 
% Returns:
%   maxSim - maximum cosine similarity found for ngram
%   label - closest gesture class found for ngram
%

function [maxSim, label] = find_closest_class(ngram, AM)
    classes = AM.keys;
    maxSim = -1;
    label = -1;
    
    for i = 1:1:size(classes, 2)
        sim = cosine_similarity(AM(cell2mat(classes(i))), ngram);
        if sim > maxSim
            maxSim = sim;
            label = cell2mat(classes(i));
        end
    end
end