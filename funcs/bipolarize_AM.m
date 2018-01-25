function [maxSim, label] = bipolarize_AM (AM)
    classes = AM.keys;
    for i=1:1:size(classes,2)
        temp = AM(cell2mat(classes(i)));
        temp(temp > 0) = 1;
        temp(temp < 0) = -1;
        AM(cell2mat(classes(i))) = temp;
    end
end