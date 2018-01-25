% Function Name: genheat
%
% Description: Generates a set of heatmaps for each gesture from a session
%
% Arguments:
%   subject - reference number for subject
%   dirname - directory for the session
%
% Returns:
%   heatmaps - cell array of heatmaps
%   labels - cell array of label names for each heatmap
%

function [heatmaps, labels] = genheat(subject,dirname)
    % gather data from all trials
    rawtot = [];
    gesttot = [];
    twidth = 0.2; % percentage of data to classify as transition
    for trial = 1:10
        % load trial file
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f')];
        load([dirname fname]);
        % generate labels
        gestlabel = genlabels(p,raw,twidth);
        % append to overall record
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw = rawtot; % concatenated raw data
    gestlabel = gesttot; % gesture labels for data, with -1 being unused

    % load preprocessing filter
    load('prefilter');
    % convolve the first two filters as they are used in a single step
    % before taking the absolute value
    p.a1 = conv(a1, a2);
    p.b1 = conv(b1, b2);
    p.a2 = a3;
    p.b2 = b3;

    % remove unused channels from recording
    raw = raw(:,1:64).*p.lsbmV;
    datalen = size(raw,1);

    % use minimum window size for filtering
    windowsize = 300;

    % loop through and filter the training data window by window to
    % approximate online behavior
    filtdata = zeros(size(raw));
    for i = windowsize+1:windowsize:datalen-(2*windowsize)+1
        % select 3 times the window size to make sure edge effects of
        % filtering can be removed
        window = raw(i-windowsize:i+(2*windowsize)-1,:);
        % preprocess the data
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        % keep only the middle window to remove edge effects
        filtdata(i:i+windowsize-1,:) = window(windowsize+1:2*windowsize,:);
    end
    
    % find minima and maxima of each channel for normalization
    for k = 1:64
        lower = min(filtdata(find(gestlabel ~= -1),k));
        upper = max(filtdata(find(gestlabel ~= -1),k));
        filtdata(:,k) = (filtdata(:,k) - lower)./(upper - lower);
    end
    
    % generate vector of channel activity for each gesture
    heat = zeros(p.numlabels+1,64);
    for i = 0:p.numlabels
        for ch = 1:64
            % find datapoints corresponding to label
            idx = find(gestlabel == i);
            % average activity found at these datapoints
            heat(i+1,ch) = mean(filtdata(idx,ch));
        end
    end
    
    % remap each activity vector to array representing spatial distribution
    load('arraymap');
    heatmaps = cell(p.numlabels+1,1);
    for i = 1:p.numlabels+1
        temp = zeros(size(arraymap));
        for ch = 1:64
            [r,c] = find(arraymap == ch);
            temp(r,c) = heat(i,ch);
        end
        heatmaps{i} = temp;
    end
    labels = ['Rest' p.labelnames];
end