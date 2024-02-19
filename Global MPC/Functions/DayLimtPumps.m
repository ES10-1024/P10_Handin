function [q] = DayLimtPumps(currentTime)
%Code to determine q in the report 
%Code to make summation for the pump stations
%Determining the amount of time step left in the day,
% Input to the function is: 
% currentTime the current time 
%% Importing Defining some stoff
c=standardConstants();

SecondsPerDay=24*3600; 
AmountInFirst=(SecondsPerDay-currentTime)/(c.ts); 

%Determining the amount of time step per day 
AmountStepDay=SecondsPerDay/c.ts; 

%Making the first row the rest of the day 
q=zeros(1,c.Nc);

for index=1:AmountInFirst
    q(1,index)=1;
end 

%Moving to next columen 
StartPosition=AmountInFirst+1; 
%While Space enough for another day just fil in another day
while StartPosition+AmountStepDay < c.Nc 
    q=[q;zeros(1,c.Nc)]; 
    RowNumber=size(q,1); 
    for index=StartPosition:AmountStepDay+StartPosition-1
         q(RowNumber,index)=1;
    end 
    StartPosition=StartPosition+AmountStepDay;
end 

%Making the last day  

%Collecting the rest of the time steps left (hopefully) 
AmountLeft=c.Nc-StartPosition+1; 
 
    q=[q;zeros(1,c.Nc)]; 
    RowNumber=size(q,1); 
    
    %Making the last part! 
    for index= StartPosition:AmountLeft+StartPosition-1 
         q(RowNumber,index)=1;
    end
end