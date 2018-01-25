function [labels] = genlabels(p, raw, twidth)
    datalen = size(raw,1);
    labels = zeros(1,datalen);
    for i = 1:p.reps
        start = p.timerest + (i-1)*(p.numlabels*p.timegest + p.timerest);
        for j = 1:p.numlabels
            labels((1:p.timegest) + (j-1)*p.timegest + start) = p.sequence(j);
        end
    end

    % find transitions
    trans = find(diff(labels) ~= 0);
    transwidth = twidth*p.timegest;
    if transwidth > 0
        for i = 1:length(trans)
            labels((-transwidth:transwidth)+trans(i)) = -1; % transition label = -1
        end
    end
    labels(1:transwidth) = -1;
    labels(end-3000+1:end) = -1;
    
%     d = 500;
%     labels = circshift(labels,d);
end