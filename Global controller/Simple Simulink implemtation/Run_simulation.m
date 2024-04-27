%% Describtion
% Use this script to run the global controller in Simulink  
%% Making alot of clears 
clf 
clc 
clear
close all
%% Adding path and standard values
addpath("Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Subsystem Reference\")
addpath("..\..\")
c=scaled_standard_constants; 
%% Define the amount of scaled hours it is desired to simulate for: 
simHour=1; 

%Making calculatation to get it to fit with the sacled time and make it
%such matlab likes it 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 

%c.tsSim=num2str(c.ts*3600); 

%% Running the simulation 
simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');

%% Making a plot of the result  
clf 
% adding the mass flows for the given time stamp  
for index=2:size(simData.logsout{1}.Values.Data,3) 
summedMassflow(index-1,1)=simData.logsout{1}.Values.Data(1,1,index)+simData.logsout{1}.Values.Data(2,1,index);
end 

% Getting the electricity prices, actual consumption, prediction horizion
% and the volume in the water tower 
for index=2:size(simData.logsout{5}.Values.Data,1)
    [temp]=ElectrictyPrices(index*c.ts); 
    ElPrices(index-1)=temp(1,1);
end 


consumptionNoise=simData.logsout{5}.Values.Data(2:end,1); 

consumptionPred=squeeze(simData.logsout{4}.Values.Data(1,1,2:end)); 

Volume=simData.logsout{3}.Values.Data/1000*c.At; 

%% Making the plot 
f=figure
% Electricity prices and summed mass flow for each time stamp 
subplot(3,1,1)
hold on
yyaxis left
ylabel('Mass flow [m^{3}/h]' )
stairs(summedMassflow) 
yyaxis right 
ylabel('El Prices [Euro/kWh]') 
stairs(ElPrices)
xlabel('Hours scaled') 
grid 
xlim([0 500])
hold off 
set(gca,'fontname','times')

% Volume in the water tower: 
subplot(3,1,2) 
hold on 
plot(Volume)
yline(c.Vmax)
yline(c.Vmin)
hold off 
legend('Volume','Constraints')
ylabel('Volume [m^{3}]') 
xlim([0 500])
grid 
xlabel('Hours scaled') 
set(gca,'fontname','times')

%Predicted consumption and presented consumption
subplot(3,1,3)
hold on 
stairs(consumptionPred)
stairs(consumptionNoise)
hold off 
grid 
legend('Predicted consumption','Actual consumption')
xlim([0 500])
ylabel('Mass flow [m^{3}/h]' )
xlabel('Hours scaled') 
set(gca,'fontname','times')




%exportgraphics(f,'global_controller_scaled_with_disturbance_with_Kappa.pdf')

