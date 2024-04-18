function [yOut,sum,a] = pump1(how_far,otherPumps,otherSums)
%% Making the shamirs secret sharing for each of the pumps. 

%% First defining the values for the secret: 
secret=60; 
%% Making a switch case to determine how far the code is along 
switch how_far 
    case 1 
        %% Next at polynium is made  which makes the output for x={1,2,3} 
        yOut=generatedOutFromFunction(secret) 
        save('Pump1Output','yOutSum(1,1)')
        yOut=yOut(2:end,1); 
        return; 
    case 2 
        %% Next a sum is made for all x=1 here. 
        own=load('Pump1Output'); 
        % making the sum
        sum=own+otherPumps(2,1)+otherPumps(3,1); 
        save('OwnSum1','sum'); 
        return; 
    case 3 
        %Getting all the other sums and determining the 
        ownSum=load(OwnSum1); 
        yOutsum=[ownSum;otherSums(2:end,1)]; 
        a=GetFunctionParameter(yOutsum);
        return; 
end 


end 