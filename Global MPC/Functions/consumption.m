function [consumption,consumptionNoise] = consumption(currentTime,d,firstTime,dNoise)
% Here it is desired to make a model for the consumption for the entire controller horizion, given the current time and control horizion. 
%The input is: 
%currentTime: the currentTime
%d current consumption such that only 1 value is changed ;D 

%% Define some values 
%Importing constant valus: 
c=standardConstants();
%The time between samples 
TimeBetweenSamples=3600/4;

% Definig the amount of seconds per day 
SecondsPerDay=24*3600;

%% Checking if the given sample time is dividable with the sample time for the measurements of demand!

if floor(c.ts/TimeBetweenSamples)==c.ts/TimeBetweenSamples 
else
    disp("CAN NOT WORK WITH THE GIVEN SAMPLE TIME PLZ CHANGE IT");
    consumption=[];
    return
end 

%% Loading in the data needed for the consumption model
load('dBar.mat'); 

load("SigmaE.mat"); 
SigmaE=SigmaE';

%% Making a new average given the sample time
%First the changes in sample is added for instance going 
% from 15 mins sample to one hour and the average is taken 

%Determine the changes in samples
samplesChanges=c.ts/TimeBetweenSamples; 

%adding those sample together
index=1;  

for i=1:samplesChanges:size(dBar) 
    NewdBar(index,1)=sum(dBar(i:samplesChanges+i-1,1)); 
    index=index+1; 
end 
%Determine the average: 
NewdBar=NewdBar/samplesChanges;

%% Next the same thing is done for the variance 

%Adding the varaince together 
index=1; 
for i=1:samplesChanges:size(dBar) 
    NewSigmaE(index,1)=sum(SigmaE(i:samplesChanges+i-1,1)); 
    index=index+1; 
end 
%Taking a average of the varaince 
NewSigmaE=NewSigmaE/samplesChanges;

%% Determining consumption model
%First it is determine the time of day which it is
StartPosition=(currentTime)/(c.ts)+1;

%Next the consumption model of the rest of that day is determined 
eNormal=normrnd(0,sqrt(NewSigmaE(StartPosition:end,1))); 

consumption=NewdBar(StartPosition:end,1).*(1+eNormal); 

%Checking for values lower than 5 m^3/h 
index=1;
for i=StartPosition:size(consumption,1) 
    if consumption(index,1) <=5 
        consumption(index,1)=NewdBar(i,1);
    end 
    index=index+1;
end
clear index; 
%Next making the noise model: 
 for index= 1:size(consumption,1)
        consumptionNoise(index,1)=consumption(index,1)+normrnd(c.NoiseMean,sqrt(c.NoiseVariance));
        if consumptionNoise(index,1)<=5; 
            consumptionNoise(index,1)=consumption(index,1); 
        end 
 end 



%Checking if the consumption size is larger than the control horizion
%horizion, if this is the case the function stops. 
if size(consumption,1) >=c.Nc 
    %Going from m^3/h to m^3/s
    if firstTime==0
        % addning noise and ending the script 
        for i=1:size(consumption,1)
            consumptionNoise(i,1)=consumption(i,1)+normrnd(c.NoiseMean,sqrt(c.NoiseVariance)); 
            if consumptionNoise(i,1) <= 5 
                consumptionNoise(i,1)=Consumption(i,1);
            end 
            consumptionNoise(i,1)=consumptionNoise(i,1);
        end 
        consumption=consumption/3600; 
        consumptionNoise=consumptionNoise/3600
    return;
    else 
        consumption=[d(2:end,1);consumption(end,end)/3600];
        %adding noise 
        consumptionNoiseTemp=consumption(end,end)+normrnd(c.NoiseMean,sqrt(c.NoiseVariance)); 
        if consumptionNoiseTemp<=5 
            consumptionNoiseTemp=consumption(end,end); 
        end 
        consumptionNoise=[dNoise(2:end,1);consumptionNoiseTemp/3600]; 
    return;
    end 
end 
SamplesPerDay=SecondsPerDay/c.ts;

while size(consumption,1)+SamplesPerDay<=c.Nc 
    eNormal=normrnd(0,sqrt(NewSigmaE)); 
    consumptionTemp=NewdBar.*(1+eNormal);
    %Checking for values below 5m^3/s
    for index=1:size(consumptionTemp,1)
        if consumptionTemp(index,1)<=5 
            consumptionTemp(index,1)=NewdBar(index,1); 
        end 
    end 
    consumption=[consumption;consumptionTemp]; 
    %adding some noise 
    for index= 1:size(consumptionTemp,1)
        consumptionNoiseTemp(index,1)=consumptionTemp(index,1)+normrnd(c.NoiseMean,sqrt(c.NoiseVariance));
        if consumptionNoiseTemp(index,1)<=5; 
            consumptionNoiseTemp(index,1)=consumptionTemp(index,1); 
        end 
        consumptionNoise=[consumptionNoise;consumptionNoiseTemp]; 
    end 

end 

if  size(consumption,1) == c.Nc 
    %Going from m^3/h to m^3/s
    consumption=consumption/3600; 
    consumptionNoise=consumptionNoise/3600; 
    if firstTime==0 
    return;
    else 
        consumption=[d(2:end,1);consumption(end,end)];
        consumptionNoise=[dNoise(2:end,1),consumptionNoise(end,end)/3600];    
        return;
    end  
else 
    Amount=c.Nc-size(consumption,1); 
    eNormal=normrnd(0,sqrt(NewSigmaE(1:Amount,1))); 
    consumptionTemp=NewdBar(1:Amount,1).*(1+eNormal); 
    %Checking for values below 5 m^3/h 
    for index=1:size(consumptionTemp)
        if consumptionTemp(index,1)<=5 
            consumptionTemp(index,1)=NewdBar(index,1); 
        end 
    end
    consumption=[consumption;consumptionTemp]; 
    %addning noise 
    for index= 1:size(consumptionTemp,1)
        consumptionNoiseTemp(index,1)=consumptionTemp(index,1)+normrnd(c.NoiseMean,sqrt(c.NoiseVariance));
        if consumptionNoiseTemp(index,1)<=5; 
            consumptionNoiseTemp(index,1)=consumptionTemp(index,1); 
        end 
        consumptionNoise=[consumptionNoise;consumptionNoiseTemp]; 
    end 

    %Going from m^3/h to m^3/s
    consumption=consumption/3600; 
    consumptionNoise=consumptionNoise/3600; 
end 

    if firstTime==0
    return;
    else 
        consumption=[d(2:end,1);consumption(end,end)];
        consumptionNoise=[dNoise(2:end,1);consumptionNoise(end,end)];
    return;
    end 
end