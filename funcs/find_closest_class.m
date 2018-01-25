function [maxSim, label] = find_closest_class (q, AM)
    classes = AM.keys;
    maxSim = -1;
    label = -1;
    for i=1:1:size(classes,2)
        sim = cosine_similarity(AM(cell2mat(classes(i))), q);
        if sim > maxSim
            maxSim = sim;
            label = cell2mat(classes(i));
        end
    end
end