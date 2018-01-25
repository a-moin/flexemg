% Function Name: randomHV
%
% Description: Generates a random hypervector of 1's and -1's
%
% Arguments:
%   D - hypervector dimension
% 
% Returns:
%   randomHV - generated random hypervector
% 

function randomHV = gen_random_HV(D)

    if mod(D, 2)
        disp('Dimension is odd!!');
    else
        % generate a random vector of indices
        randomIndex = randperm(D);
        % make half the elements 1 and the other half -1
        randomHV(randomIndex(1:D/2)) = 1;
        randomHV(randomIndex(D/2+1:D)) = -1;
    end
end
