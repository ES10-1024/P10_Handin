function [ElPrices] = ElectrictyPrices(currentTime)
%% In this script it is desired to return a vector of the eletricty prices
%% Input and output
% Input
% currentTime The current Time in seconds! 


%% Loading in scaled standard constants 
c=scaled_standard_constants();

%Defining the size of the output vector: 
ElPrices=zeros(c.Nc,1);


%% Determine the start entire for electricity price: 
CurrentTimeHours=floor(currentTime*c.AccTime/3600)+1;   



%% Loading in the eletricty prices
ElpriceAlot=load("ElPrice.mat");

% Going from MWh to kWh:  
Data.NewPrice=ElpriceAlot.A/1000;

%% Picking out the eletricity price based on the current location and forward 
% to the end of control horizon. 
for index=1:c.Nc
    ElPrices(index,1)=Data.NewPrice(CurrentTimeHours+index-1);
end 


end