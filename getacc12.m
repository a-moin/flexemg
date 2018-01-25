% Function Name: getacc12
%
% Description: Trains and tests HD classifier. Trains using session 1
% training data and tests on both session 1 testing data and session 2
% testing data. 
%
% Arguments:
%   subject - reference number for subject
%   N - length of ngram
%   numtrain - number of training trials to use
%   HDscale - scale factor for HD vector values
%   chan - subset of channels used for training and testing
% 
% Returns:
%   label1 - unvoted classifier output for session 1 testing
%   label2 - unvoted classifier output for session 2 testing
%   correct - correct label command used during recording
%   accs1 - vector of classification accuracies for range of voting windows
%           for session 1 testing
%   accs2 - vector of classification accuracies for range of voting windows
%           for session 2 testing
%

function [label1, label2, correct, accs1, accs2] = getacc12(subject, N, numtrain, HDscale, chan)
    % replace './SubjectData/' with appropriate data directory path
    dir1train = ['./SubjectData/' num2str(subject,'%03.f') '-Session1/']; % directory for session 1 training data
    dir1test = ['./SubjectData/' num2str(subject,'%03.f') '-Session2/']; % directory for session 1 testing data
    dir2test = ['./SubjectData/' num2str(subject,'%03.f') '-Session3/']; % directory for session 2 testing data

    % classify at the same rate as downsampling, i.e. every 100 ms
    classifyperiod = 100;
    downsampleperiod = 100;
    % window the data to get N samples after downsampling for an ngram
    windowsize = N*classifyperiod;
    
    % set maximum vote window to the length of each gesture
    votewin = round((1 - 2*twidth)*p.timegest/downsampleperiod/2); 
    % randomly select the number of trials used for training
    traintrial = randperm(10);
    traintrial = traintrial(1:numtrain);
    
    % gather session 1 training data
    rawtot = [];
    gesttot = [];
    twidth = 0.2; % percentage of data to throw out from each end of gesture segment
    for trial = traintrial
        % load the trial file
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f')]; 
        load([dir1train fname]);
        % generate labels for the data based on commands during recording
        gestlabel = genlabels(p,raw,twidth);
        % append to overall record
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    rawtrain = rawtot; % concatenated raw data from selected session 1 training trials
    gestlabeltrain = gesttot; % gesture labels for data, with -1 being unused
    
    % gather session 1 testing data
    rawtot = [];
    gesttot = [];
    for trial = 1:10
        % load the trial file
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f')];
        load([dir1test fname]);
        % generate labels for the data based on commands during recording
        gestlabel = genlabels(p,raw,twidth);
        % append to overall record
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw1test = rawtot; % concatenated raw data from session 1 testing trials
    gestlabel1test = gesttot; % gesture labels for data, with -1 being unused
    
    % gather session 2 testing data
    rawtot = [];
    gesttot = [];
    for trial = 1:10
        % load the trial file
        fname = [num2str(subject,'%03.f') '-' num2str(trial,'%03.f')];
        load([dir2test fname]);
        % generate labels for the data based on commands during recording
        gestlabel = genlabels(p,raw,twidth);
        % append to overall record
        rawtot = [rawtot; raw];
        gesttot = [gesttot gestlabel];
    end
    raw2test = rawtot; % concatenated raw data from session 2 testing trials
    gestlabel2test = gesttot; % gesture labels for data, with -1 being unused
    
    % load preprocessing filter (generated using genfilter.m)
    load('prefilter');
    % convolve the first two filters as they are used in a single step
    % before taking the absolute value
    a1 = conv(a1, a2);
    b1 = conv(b1, b2);
    a2 = a3;
    b2 = b3;
    
    % remove unused channels from recording
    rawtrain = rawtrain(:,1:64);
    datalen = size(rawtrain,1);
    
    % loop through and filter the training data window by window to
    % approximate online behavior
    filtdata = zeros(size(rawtrain));
    for i = windowsize+1:windowsize:datalen-(2*windowsize)+1
        % select 3 times the window size to make sure edge effects of
        % filtering can be removed
        window = rawtrain(i-windowsize:i+(2*windowsize)-1,:);
        % preprocess the data
        window = filtfilt(b1,a1,window);
        window = abs(window);
        window = filtfilt(b2,a2,window);
        % keep only the middle window to remove edge effects
        filtdata(i:i+windowsize-1,:) = window(windowsize+1:2*windowsize,:);
    end
    
    % find minima and maxima of each channel for normalization
    lower = 100.*ones(1,64);
    upper = zeros(1,64);
    for k = 1:64
        lower(k) = min(filtdata(find(gestlabeltrain ~= -1),k));
        upper(k) = max(filtdata(find(gestlabeltrain ~= -1),k));
    end
    
    % scale the raw data to improve HD accuracy, and select subset of data
    datatrain = rawtrain(:,chan).*HDscale;
    data1test = raw1test(:,chan).*HDscale;
    data2test = raw2test(:,chan).*HDscale;
    lower = lower(chan);
    upper = upper(chan);

    % build model for HD processing
    model = struct;
    model.D = 10000; % dimension of hypervectors
    model.N = N; % size of ngram
    model.noCh = length(chan); % number of input channels

    % generate random hypervector for each channel
    eM = containers.Map ('KeyType','int32','ValueType','any');
    for e = 1:1:model.noCh
        eM(e) = gen_random_HV(model.D);
    end

    % generate associative memory for gesture labels
    % -1 = no label (unused data)
    % 0 = rest
    AM = containers.Map('KeyType','int32','ValueType','any'); 
    for i = -1:p.numlabels
        AM(i) = zeros(1,model.D);
    end
        
    % train AM with training data from session 1
    d = datatrain;
    g = gestlabeltrain;
    datalen = length(g);
        
    % loop through and filter each window, then train by updating AM
    for i = windowsize+1:classifyperiod:datalen-(2*windowsize)+1
        % filter the window
        window = d(i-windowsize:i+(2*windowsize)-1,:);
        window = filtfilt(b1,a1,window);
        window = abs(window);
        window = filtfilt(b2,a2,window);
        % normalize the window
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
        end
        % remove edge effects
        window = window(windowsize+1:2*windowsize,:);
        
        % downsample the window (and associated gesture label)
        window = downsample(window,downsampleperiod);
        gestwindow = downsample(g(i:i+windowsize-1),downsampleperiod);
        
        % compute Ngrams and add into the AM
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

    % test classifier on session 1 testing data
    accs1 = zeros(votewin+1,1);
    
    d = data1test;
    g = gestlabel1test;
    datalen = length(g);
    testlabel = zeros(size(g)); % vector of classifier output labels
    
    % loop though, window data, classify gesture
    for i = windowsize+1:classifyperiod:datalen-(2*windowsize)+1
        % filter the window
        window = d(i-windowsize:i+(2*windowsize)-1,:);
        window = filtfilt(b1,a1,window);
        window = abs(window);
        window = filtfilt(b2,a2,window);
        % normalize the window
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
        end
        % remove edge effects
        window = window(windowsize+1:2*windowsize,:);
        
        % downsample the window (and associated gesture label)
        window = downsample(window,downsampleperiod);
        gestwindow = downsample(g(i:i+windowsize-1),downsampleperiod);
        
        % calculate and accumulate ngrams for the window
        ngram = zeros(1,model.D);
        for t = 1:length(gestwindow)-model.N+1
            ngram = ngram + compute_ngram(window(t:t+model.N-1,:)', eM, model);
        end
        
        % calculate closest gesture within AM
        [maxSim, l] = find_closest_class (ngram, AM);
        
        % update the output label
        testlabel(i:i+windowsize-1) = l;
    end

    % vote on the labels with range of voting windows
    l1 = downsample(g,downsampleperiod); % correct labels
    l2 = downsample(testlabel,downsampleperiod); % voted labels
    
    % unused data shouldn't be included in accuracy measure
    testpoints = find(l1 ~= -1);
    
    % set return values
    label1 = l2;
    correct = l1;
    
    % loop through voting windows
    for i = 0:votewin
        % create vector of voted labels
        vote = zeros(size(l2));
        % account for edges where full vote windows aren't possible
        vote(1:i) = mode(l2(1:2*i+1));
        vote(end-i+1:end) = mode(l2(end-2*i:end));
        % vote over the rest of the full voting windows
        for k = i+1:length(vote)-i
            vote(k) = mode(l2(k-i:k+i));
        end
        % calculate accuracy as the percentage of matches over all the used
        % testpoints
        accs1(i+1) = sum(l1(testpoints) == vote(testpoints))/length(testpoints);
    end
    
    %% test on session 3
    accs2 = zeros(votewin+1,1);
    
    d = data2test;
    g = gestlabel2test;
    datalen = length(g);
    testlabel = zeros(size(g));

    % loop though, window data, classify gesture
    for i = windowsize+1:classifyperiod:datalen-(2*windowsize)+1
        % filter the window
        window = d(i-windowsize:i+(2*windowsize)-1,:);
        window = filtfilt(b1,a1,window);
        window = abs(window);
        window = filtfilt(b2,a2,window);
        % normalize the window
        for k = 1:model.noCh
            window(:,k) = (window(:,k)-lower(k))./(upper(k)-lower(k));
        end
        % remove edge effects
        window = window(windowsize+1:2*windowsize,:);
        
        % downsample the window (and associated gesture label)
        window = downsample(window,downsampleperiod);
        gestwindow = downsample(g(i:i+windowsize-1),downsampleperiod);
        
        % calculate and accumulate ngrams for the window
        ngram = zeros(1,model.D);
        for t = 1:length(gestwindow)-model.N+1
            ngram = ngram + compute_ngram(window(t:t+model.N-1,:)', eM, model);
        end
        
        % calculate closest gesture within AM
        [maxSim, l] = find_closest_class (ngram, AM);
        
        % update the output label
        testlabel(i:i+windowsize-1) = l;
    end

    % vote on the labels with range of voting windows
    l1 = downsample(g,downsampleperiod); % correct labels
    l2 = downsample(testlabel,downsampleperiod); % voted labels
    
    % unused data shouldn't be included in accuracy measure
    testpoints = find(l1 ~= -1);
    
    % set return values
    label2 = l2;
    
    % loop through voting windows
    for i = 0:votewin
        % create vector of voted labels
        vote = zeros(size(l2));
        % account for edges where full vote windows aren't possible
        vote(1:i) = mode(l2(1:2*i+1));
        vote(end-i+1:end) = mode(l2(end-2*i:end));
        % vote over the rest of the full voting windows
        for k = i+1:length(vote)-i
            vote(k) = mode(l2(k-i:k+i));
        end
        % calculate accuracy as the percentage of matches over all the used
        % testpoints
        accs2(i+1) = sum(l1(testpoints) == vote(testpoints))/length(testpoints);
    end
end