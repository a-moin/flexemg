function [label2, label3, correct, accs2, accs3] = getacc23(subject, type, N, numtrain, HDscale, pchan)
    dirname1 = ['./SubjectData/' num2str(subject,'%03.f') '-Session1/']; % directory for session 1 training data
    dirname2 = ['./SubjectData/' num2str(subject,'%03.f') '-Session2/']; % directory for session 2 testing data
    dirname3 = ['./SubjectData/' num2str(subject,'%03.f') '-Session3/']; % directory for session 3 testing data

    %% gather data from all trials in separate sessions
    % gather data for training, select only numtrain trials for subset
    traintrial = randperm(10);
    traintrial = traintrial(1:numtrain);
    rawtot = [];
    gesttot = [];
    twidth = 0.2; % percentage of data to throw out from each end of gesture segment
    for trial = traintrial
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f') '-' type];
        load([dirname1 fname]);
        gestlabel = genlabels(p,raw,twidth);
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw1 = rawtot; % concatenated raw data from all trials
    gestlabel1 = gesttot; % labels for raw data, with -1 being unused
    
    % gather data for testing session 2
    rawtot = [];
    gesttot = [];
    for trial = 1:10
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f') '-' type];
        load([dirname2 fname]);
        gestlabel = genlabels(p,raw,twidth);
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw2 = rawtot; % concatenated raw data from all trials
    gestlabel2 = gesttot; % labels for raw data, with -1 being unused
    
    % gather data for testing session 3
    rawtot = [];
    gesttot = [];
    for trial = 1:10
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f') '-' type];
        load([dirname3 fname]);
        gestlabel = genlabels(p,raw,twidth);
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw3 = rawtot; % concatenated raw data from all trials
    gestlabel3 = gesttot; % labels for raw data, with -1 being unused
    
    % load preprocessing filter (generated using genfilter.m)
    load('prefilter');
    p.a1 = conv(a1, a2);
    p.b1 = conv(b1, b2);
    p.a2 = a3;
    p.b2 = b3;
    
    % changing variable names here, since that's what was used in previous
    % iterations of script
    raw = raw1;
    gestlabel = gestlabel1;
    
    % determine normalization factors
    raw = raw(:,1:64);
    datalen = size(raw,1);

    p.classifyperiod = 100;
    p.windowsize = N*p.classifyperiod;
    
    lower = 100.*ones(1,64);
    upper = zeros(1,64);
    
    % loop through and filter the training data window by window
    filtdata = raw;
    for i = p.windowsize+1:p.windowsize:datalen-(2*p.windowsize)+1
        window = raw(i-p.windowsize:i+(2*p.windowsize)-1,:);
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        filtdata(i:i+p.windowsize-1,:) = window(p.windowsize+1:2*p.windowsize,:);
    end
    
    % find minima and maxima
    for k = 1:64
        lower(k) = min(filtdata(find(gestlabel ~= -1),k));
        upper(k) = max(filtdata(find(gestlabel ~= -1),k));
    end
    
    % detect and remove bad channels
%     p.chan = find(upper < mean(upper) + std(upper));
    p.chan = pchan;
    
    % scale the raw data to improve HD accuracy, and select subset of data
    data = raw(:,p.chan).*HDscale;
    data2 = raw2(:,p.chan).*HDscale;
    data3 = raw3(:,p.chan).*HDscale;
    lower = lower(p.chan);
    upper = upper(p.chan);

%% train on session 1, test on 2 and 3
    % hypervector model parameters
    model = struct;
    model.D = 10000; % dimension of hypervectors
    model.N = N; % size of ngram data buffer
    model.noCh = length(p.chan); % number of input channels
    model.binf = true; % ???
    model.lower = lower;
    model.upper = upper;

    p.downsample = 100;
    votewin = round((1 - 2*twidth)*p.timegest/p.downsample/2); % set maximum vote window to the length of each gesture
    
    accs2 = zeros(votewin+1,1);
    accs3 = zeros(votewin+1,1);
    
    % generate random hypervector for each channel
    eM = containers.Map ('KeyType','int32','ValueType','any');
    for e = 1:1:model.noCh
        eM(e) = gen_random_HV(model.D);
    end

    % generate associative memory for each label
    AM = containers.Map('KeyType','int32','ValueType','any'); 
    for i = -1:p.numlabels
        AM(i) = zeros(1,model.D);
    end
        
    % set training data and label (once again just a rename)
    d = data;
    g = gestlabel;
    datalen = length(g);
        
    % loop through and filter each window, then train by updating AM
    for i = p.windowsize+1:p.classifyperiod:datalen-(2*p.windowsize)+1
        % filter the window
        window = d(i-p.windowsize:i+(2*p.windowsize)-1,:);
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        % normalize the window
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
%             window(:,k) = (window(:,k)-lower(k))./upper(k);
        end
        window = window(p.windowsize+1:2*p.windowsize,:);
        % downsample the window and gesture, selecting the voted correct
        % label
        window = downsample(window,p.downsample);
        gestwindow = downsample(g(i:i+p.windowsize-1),p.downsample);
        % compute Ngram and add it into the AM
        for t = 1:length(gestwindow)-model.N+1
            ngram = compute_ngram(window(t:t+model.N-1,:)', eM, model);
            label = mode(gestwindow(t:t+model.N-1));
            AM(label) = AM(label) + ngram;
        end
    end
    
    % remove the unused label from AM
    remove(AM,-1);
    % bipolarize the AM
    bipolarizeAM(AM);

    % compute confusion matrix for the labels
    dist = distances_AM(AM);

    %% test on session 2
    
    d = data2;
    g = gestlabel2;
    datalen = length(g);
    testlabel = zeros(size(g));

    for i = p.windowsize+1:p.classifyperiod:datalen-(2*p.windowsize)+1
        window = d(i-p.windowsize:i+(2*p.windowsize)-1,:);
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
%             window(:,k) = (window(:,k)-lower(k))./upper(k);
        end
        window = window(p.windowsize+1:2*p.windowsize,:);
        window = downsample(window,p.downsample);
        gestwindow = downsample(g(i:i+p.windowsize-1),p.downsample);
    %     templabel = zeros(1,length(gestwindow)-model.N+1);        
    %     for t = 1:length(gestwindow)-model.N+1
    %         ngram = compute_ngram(window(t:t+model.N-1,:)', eM, model);
    %         [maxSim, l] = find_closest_class (ngram, AM);
    %         templabel(t) = l;
    %     end
    %     testlabel(i:i+p.windowsize-1) = mode(templabel);
        ngram = zeros(1,model.D);
        for t = 1:length(gestwindow)-model.N+1
            ngram = ngram + compute_ngram(window(t:t+model.N-1,:)', eM, model);
        end
        [maxSim, l] = find_closest_class (ngram, AM);
        testlabel(i:i+p.windowsize-1) = l;
    end

    % vote on the labels with different voting windows
    l1 = downsample(g,p.downsample);
    l2 = downsample(testlabel,p.downsample);
%     l1 = g;
%     l2 = testlabel;
    testpoints = find(l1 ~= -1);

    label2 = l2;
    correct = l1;
    
    for i = 0:votewin
        vote = zeros(size(l2));
        vote(1:i) = mode(l2(1:2*i+1));
        vote(end-i+1:end) = mode(l2(end-2*i:end));
        for k = i+1:length(vote)-i
            vote(k) = mode(l2(k-i:k+i));
        end
        accs2(i+1) = sum(l1(testpoints) == vote(testpoints))/length(testpoints);
    end
    
    %% test on session 3
    d = data3;
    g = gestlabel3;
    datalen = length(g);
    testlabel = zeros(size(g));

    for i = p.windowsize+1:p.classifyperiod:datalen-(2*p.windowsize)+1
        window = d(i-p.windowsize:i+(2*p.windowsize)-1,:);
        window = filtfilt(p.b1,p.a1,window);
        window = abs(window);
        window = filtfilt(p.b2,p.a2,window);
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
%             window(:,k) = (window(:,k)-lower(k))./upper(k);
        end
        window = window(p.windowsize+1:2*p.windowsize,:);
        window = downsample(window,p.downsample);
        gestwindow = downsample(g(i:i+p.windowsize-1),p.downsample);
    %     templabel = zeros(1,length(gestwindow)-model.N+1);        
    %     for t = 1:length(gestwindow)-model.N+1
    %         ngram = compute_ngram(window(t:t+model.N-1,:)', eM, model);
    %         [maxSim, l] = find_closest_class (ngram, AM);
    %         templabel(t) = l;
    %     end
    %     testlabel(i:i+p.windowsize-1) = mode(templabel);
        ngram = zeros(1,model.D);
        for t = 1:length(gestwindow)-model.N+1
            ngram = ngram + compute_ngram(window(t:t+model.N-1,:)', eM, model);
        end
        [maxSim, l] = find_closest_class (ngram, AM);
        testlabel(i:i+p.windowsize-1) = l;
    end

    % vote on the labels with different voting windows
    l1 = downsample(g,p.downsample);
    l2 = downsample(testlabel,p.downsample);
%     l1 = g;
%     l2 = testlabel;
    testpoints = find(l1 ~= -1);

    for i = 0:votewin
        vote = zeros(size(l2));
        vote(1:i) = mode(l2(1:2*i+1));
        vote(end-i+1:end) = mode(l2(end-2*i:end));
        for k = i+1:length(vote)-i
            vote(k) = mode(l2(k-i:k+i));
        end
        accs3(i+1) = sum(l1(testpoints) == vote(testpoints))/length(testpoints);
    end
    
    label3 = l2;
end