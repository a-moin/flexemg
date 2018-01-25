close all
clear
clc

sub = 1;

maps1 = cell(1,5);
for k = 1:5
    maps1{k} = zeros(16,4);
end

for sess = 1:3
    [m,l] = genheat(sub,sess,'Hard');
    for k = 1:5
        maps1{k} = maps1{k} + m{k}./3;
    end
end

maxval1 = 0;
for k = 1:5
    maxval1 = max([maxval1 max(maps1{k}(:))]);
end

maps2 = cell(1,5);
for k = 1:5
    maps2{k} = zeros(16,4);
end

for sess = 4:5
    [m,l] = genheat(sub,sess,'Hard');
    for k = 1:5
        maps2{k} = maps2{k} + m{k}./2;
    end
end

maxval2 = 0;
for k = 1:5
    maxval2 = max([maxval2 max(maps2{k}(:))]);
end
%%
cmap = 'jet';
for k = 1:5
    figure(k)
    set(gcf, 'Position', [150*k 500 150 600])
    imagesc(maps1{sub,k},[0 maxval1])
    colormap(cmap)
    axis off
end

for k = 1:5
    figure(k+5)
    set(gcf, 'Position', [150+150*(k+5) 500 150 600])
    imagesc(maps2{sub,k},[0 maxval2])
    colormap(cmap)
    axis off
end

for f = 1:10
    figure(f)
    print(['Map' num2str(f)], '-dpng');
end
