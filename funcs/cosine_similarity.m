% Function Name: cosine_similarity
%
% Description: Calculates the cosine similarity between two hypervectors
%
% Arguments:
%   u - first hypervector
%   v - second hypervector
% 
% Returns:
%   sim - the cosine similarity between u and v (between -1 and 1)
%

function sim = cosine_similarity(u, v)
    sim = dot(u, v) / (norm(u) * norm(v));
end
