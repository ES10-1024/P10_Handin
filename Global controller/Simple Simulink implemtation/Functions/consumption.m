function [consumptionPred,consumptionActual] = consumption(currentTime)
% Here it is desired to make a model for the consumption for the entire controller horizion, given the current time and control horizion. 
%The input is: 
%currentTime: the currentTime
%% Define some values 
%Importing constant valus: 
c=scaled_standard_constants();
%The time between samples 
TimeBetweenSamples=600;


%% Defining the size of the output matrixes: 
consumptionPred=zeros(c.Nc,1); 
consumptionActual=zeros(c.Nc,1);



%% Loading in the data needed for the consumption model, prediction, and for the acutal consumption 
actual=load("average_scaled_consumption.mat");
pred=load("average_scaled_prediction.mat");

%% Picking out the correct values: 
%Determine the start position in terms of the hour:  
StartPosition=(currentTime*c.AccTime);

StartPosition=round(StartPosition)/3600+1;
 

consumptionPred=pred.average_scaled_prediction(StartPosition:StartPosition+c.Nc-1,1);

consumptionActual=actual.average_scaled_consumption(StartPosition:StartPosition+c.Nc-1,1);


end