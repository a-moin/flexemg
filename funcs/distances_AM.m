function [distances] = distances_AM (AM)
    classes = AM.keys;
    for i = 1:1:size(classes, 2)
        for j = 1:1:size(classes, 2)
            distances(i,j) = cosine_similarity (AM(cell2mat(classes(i))), AM(cell2mat(classes(j))));
        end
    end
%     imagesc(distances);
%     colorbar;
end