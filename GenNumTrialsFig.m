close all
clear
clc

load('NumTrialsFinal_1_2.mat')

accs1_2 = mean(accs2{1},3);
accs1_2 = accs1_2(:,[1 6]);

accs1_3 = mean(accs3{1},3);
accs1_3 = accs1_3(:,[1 6]);

accs2_2 = mean(accs2{2},3);
accs2_2 = accs2_2(:,[1 6]);

accs2_3 = mean(accs3{2},3);
accs2_3 = accs2_3(:,[1 6]);

load('NumTrialsFinal_3.mat')

accs3_2 = mean(accs2{1},3);
accs3_2 = accs3_2(:,[1 6]);

accs3_3 = mean(accs3{1},3);
accs3_3 = accs3_3(:,[1 6]);

accs2 = (accs1_2 + accs2_2 + accs3_2)./3;
accs3 = (accs1_3 + accs2_3 + accs3_3)./3;


figure(1)
set(gcf, 'Position', [100 100 1500 500])
subplot(1,2,1)
plot(accs1_2(:,1),'--','LineWidth',2)
hold on
plot(accs2_2(:,1),'--','LineWidth',2)
plot(accs3_2(:,1),'--','LineWidth',2)
plot(accs2(:,1),'k','LineWidth',4)
xlim([1 10])
ylim([0.5 1])
leg = legend('Subject 1', 'Subject 2', 'Subject 3', 'Average');
set(leg, 'Location','southeast')
grid on

subplot(1,2,2)
plot(accs1_3(:,1),'--','LineWidth',2)
hold on
plot(accs2_3(:,1),'--','LineWidth',2)
plot(accs3_3(:,1),'--','LineWidth',2)
plot(accs3(:,1),'k','LineWidth',4)
xlim([1 10])
ylim([0.5 1])
grid on

% figure(3)
% plot(accs3(:,1))
% hold on
% plot(accs3(:,2))
% xlim([1 10])
% ylim([0.8 1])
% 
% figure(4)
% plot(accs3(:,1))
% hold on
% plot(accs3(:,2))
% xlim([1 10])
% ylim([0.8 1])