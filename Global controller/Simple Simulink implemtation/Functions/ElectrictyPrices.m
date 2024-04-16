function [ElPrices] = ElectrictyPrices(currentTime)
%% In this script it is desired to return a vector of the eletricty prices which are neccesary for the MPC to run
%% Input and output
% Input
% currentTime The current Time in seconds! 

%  Elprices a vector of eletricity prices for the entire control horzion 
%Setting the output to zero, beacuse Simulink needs it: 
ElPrices=zeros(c.Nc,1);

%Loading in scaled standard constants 
c=scaled_standard_constants();

%% Determine the start entire for electricity price: 
CurrentTimeHours=floor(currentTime*c.AccTime/3600)+1;   



%% Loading in the eletricty prices
ElpriceAlot=load("ElPrice.mat");

% %Going from MWh to kWh:  
Data.NewPrice=ElpriceAlot.A/1000;

%% Picking out eletricity price based on the current location and forward 
% to the end of control horizon. 
for index=1:c.Nc
    ElPrices(index,1)=Data.NewPrice(CurrentTimeHours+index-1);
end 




end