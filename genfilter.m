close all
clear
clc

% notch 60 Hz
f_0 = 60; 
Q = 50;
fs = 1000;
wo = f_0/(fs/2);  
bw = wo/Q;
[b1,a1] = iirnotch (wo,bw);

% bandpass filter
[b2,a2]=butter(4,[1 200]./500); 

% moving average filter
% y[n] = (x[n] + x[n-1] + ... x[n-K+1])/K; K is the window size
K = 100; % the window for moving average
b3 = 1/K * ones(1,K);
a3 = 1;

% Exponential averaging (slight smoothing)
% y[n] = alpha x[n] + (1 - alpha) y[n-1]
alpha = 0.95;	
b4 = alpha;
a4 = [1, -(1 - alpha)];

save('prefilter','a1','a2','a3','a4','b1','b2','b3','b4');