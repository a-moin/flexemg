function [heatmaps, labels] = genheat(subject,session,type)
    %% select training session and load data
    dirname1 = ['./SubjectData/' num2str(subject,'%03.f') '-Session' num2str(session) '/'];

    %% gather data from all trials
    rawtot = [];
    gesttot = [];
    twidth = 0.2;
    for trial = 1:10
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f') '-' type];
        load([dirname1 fname]);
        gestlabel = genlabels(p,raw,twidth);
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw = rawtot;
    gestlabel = gesttot;

    % load preprocessing filter
    load('prefilter');
    p.a1 = conv(a1, a2);
    p.b1 = conv(b1, b2);
    p.a2 = a3;
    p.b2 = b3;

    % determine normalization factors
    raw = raw(:,1:64).*p.lsbmV;
    datalen = size(raw,1);
    triallen = datalen/10;
    totallen = datalen;

    p.windowsize = 300;
    p.classifyperiod = 100;

    lower = 100.*ones(1,64);
    upper = zeros(1,64);

    filtdata = raw;
    for i = p.windowsize+1:p.windowsize:datalen-(2*p.windowsize)+1
        window = raw(i-p.windowsize:i+(2*p.windowsize)-1,:);
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        filtdata(i:i+p.windowsize-1,:) = window(p.windowsize+1:2*p.windowsize,:);
    end

    for k = 1:64
        lower(k) = min(filtdata(find(gestlabel ~= -1),k));
        upper(k) = max(filtdata(find(gestlabel ~= -1),k));
        filtdata(:,k) = (filtdata(:,k) - lower(k))./(upper(k) - lower(k));
    end

    heat = zeros(p.numlabels+1,64);
    for i = 0:p.numlabels
        for ch = 1:64
            idx = find(gestlabel == i);
            heat(i+1,ch) = mean(filtdata(idx,ch));
        end
    end

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