% Function Name: 
%
% Description: 
%
% Arguments: 
% 
% Returns:
% 

function randomHV = gen_random_HV(D)

    if mod(D, 2)
        disp('Dimension is odd!!');
    else
        randomIndex = randperm(D);
        randomHV(randomIndex(1:D/2)) = 1;
        randomHV(randomIndex(D/2+1:D)) = -1;
    end
end
