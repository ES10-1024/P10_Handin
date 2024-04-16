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


%% Checking if the given sample time is dividable with the sample time for the measurements of demand!
if floor((c.ts)/TimeBetweenSamples)==(c.ts)/TimeBetweenSamples 
else
    disp("CAN NOT WORK WITH THE GIVEN SAMPLE TIME PLZ CHANGE IT");
   
    return;
end 


%% Loading in the data needed for the consumption model, prediction, and for the acutal consumption 
std_week=load('prediction_scaled2.mat'); 
std_week=std_week.scaled_prediction';

demand_data=load('consumption_scaled2.mat'); 

demand_data=demand_data.scaled_consumption;

%% Making a new average given the sample time
%First the changes in sample is added for instance going 
% from 15 mins sample to one hour and the average is taken 

%Determining the amount of samples needs for one sample time for the MPC
samplesChanges=3600/TimeBetweenSamples; 


%% Adding those sample together for the actual demand, and the std_week  and determine the average
%Standard week: 

index=1;  
NewStd_week=zeros(size(std_week,1)/samplesChanges,1);
for i=1:samplesChanges:size(std_week,1) 
    NewStd_week(index,1)=sum(std_week(i:samplesChanges+i-1,1)); 
    index=index+1; 
end 

%Determine the average: 
NewStd_week=NewStd_week/samplesChanges;

%Actual demand  
index=1; 
NewDemand_data=zeros(ceil(size(demand_data,1)/samplesChanges),1);
for i=1:samplesChanges:size(demand_data,1)-samplesChanges 
    NewDemand_data(index,1)=sum(demand_data(i:samplesChanges+i-1,1)); 
    index=index+1; 
end 
%Taking a average of the varaince 
NewDemand_data=NewDemand_data/samplesChanges;

%% Picking out the correct values: 
%Determine the start position in terms of the hour:  
StartPosition=(currentTime*c.AccTime);

StartPosition=round(StartPosition)/3600+1;
 

%Checking if enough data is avable els wrap around is needed. 
if StartPosition+c.Nc<=size(NewStd_week,1) 
    %Taking out the data for the entire control horizon
    consumptionPred=NewStd_week(StartPosition:StartPosition+c.Nc-1,1);
    consumptionActual=NewDemand_data(StartPosition:StartPosition+c.Nc-1,1);
    return; 
else 
    %Starting be taking out the data left in the matrix 
    consumptionPred=NewStd_week(StartPosition:end);
    consumptionActual=NewDemand_data(StartPosition:end); 
    %Determine how much is still missing
    Left=c.Nc-size(consumptionPred,1);

    %The left is taken from the start resulting in: 
    consumptionPred=[consumptionPred;NewStd_week(1:Left,1)]; 
    consumptionActual=[consumptionActual;NewDemand_data(1:Left,1)];

    return; 
end 

end