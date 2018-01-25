%buffer data: ExT, e.g., 4x100 
function [ngram] = compute_ngram (buffer, eM, model)
    ngram = ones(1, model.D);
    s = zeros(1, model.D);
    for t = 1:model.N
        for e = 1:model.noCh
            s = s + eM(e).*buffer(e,t);
        end
        
        s(s>0) = 1;
        s(s<0) = -1;
        
        ngram = ngram.*(circshift(s,[0,model.N-t]));
    end

end