% Function Name: compute_ngram
%
% Description: Generates the spatiotemporal encoded ngram for a window of
% EMG data (Fig. 3 in the paper)
%
% Arguments:
%   buffer - window of data to be encoded
%   eM - electrode memory, i.e. random hypervectors for each electrode
%   model - struct containing model parameters such as hypervectors
%   dimension, ngram size, and number of channels
% 
% Returns:
%   ngram - spatiotemporal encoded hypervector
%

function [ngram] = compute_ngram(buffer, eM, model)
    ngram = ones(1, model.D);
    s = zeros(1, model.D);
    for t = 1:model.N
        for e = 1:model.noCh
            s = s + eM(e) .* buffer(e, t);
        end
        
        s(s >= 0) = 1;
        s(s < 0) = -1;
        
        ngram = ngram .* (circshift(s, [0, model.N - t]));
    end
end