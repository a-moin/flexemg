% Function Name: genlabels
%
% Description: Parses recording files to create data labels
%
% Arguments:
%   p - struct containing trial information
%   raw - raw data from the trial recording
%   twidth - percentage of the gesture length to cut out from each side of
%   the gesture
%
% Returns:
%   labels - vector or data gesture labels
%

function [labels] = genlabels(p, raw, twidth)
    datalen = size(raw,1);
    labels = zeros(1,datalen);
    
    % loop through each repetition of gesture set in the file
    for i = 1:p.reps
        start = p.timerest + (i-1)*(p.numlabels*p.timegest + p.timerest);
        % label each section of the data with the sequence number
        for j = 1:p.numlabels
            labels((1:p.timegest) + (j-1)*p.timegest + start) = p.sequence(j);
        end
    end

    % find transitions
    trans = find(diff(labels) ~= 0);
    transwidth = twidth*p.timegest;
    if transwidth > 0
        for i = 1:length(trans)
            % label a window of data around transition as unused data
            labels((-transwidth:transwidth)+trans(i)) = -1; % transition label = -1
        end
    end
    % don't use very beginning and last rest of the data
    labels(1:transwidth) = -1;
    labels(end-3000+1:end) = -1;
end