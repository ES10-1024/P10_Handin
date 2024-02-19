function [ElPrices] = ElectrictyPrices(currentTime,CurrentDay)
%% In this script it is desired to return a vector of the eletricty prices which are neccesary for the MPC to run

%% First define some variables
% Input
% currentTime The current Time in seconds! 
% CurrentDay THe current day 

%% Making a few definitions
%Current time with respect to hours. 
CurrentTimeHours=floor(currentTime/3600);  
c=standardConstants();

%% Loading in the eletricty prices
load("ElectrictyPrices.mat")
%Going from MWh to kWh: 
Data.NewPrice=Data.NewPrice/1000; 


%% Making vector of eletricty prices 
% Determine the row to be entered based on how many days has gone by,
% and the time of day. 
TimeHours=(CurrentTimeHours)+24*CurrentDay+1;
%Determing time to next hour 
TimeNextHour=3600*(currentTime/3600-CurrentTimeHours); 

%Maing a for loop to make the vector of eletricty prices

for index=1:c.Nc 
    %Load the eletricty into the vector
    ElPrices(index,1)=Data.NewPrice(TimeHours,1); 
    %adding the sample time to the present time 
    TimeNextHour=TimeNextHour+c.ts; 
    %If the TimeNextHour is above 3600s (one hour), TimeHours is move 
    %one step forward (next eletricty price)
    if TimeNextHour>= 3600 
        TimeNextHour=TimeNextHour-3600; 
        TimeHours=TimeHours+1; 
    end 
end 




end