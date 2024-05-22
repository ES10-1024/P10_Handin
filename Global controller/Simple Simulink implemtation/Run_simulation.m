%% Describtion
% Use this script to run the global controller in Simulink  
%% Making alot of clears 
clf 
clc 
clear
close all
%% Adding path and standard values
addpath("Functions\")
addpath("..\Subsystem Reference\")
addpath("..\..\")
c=scaled_standard_constants; 
%% Define the amount of scaled hours it is desired to simulate for: 
simHour=80; 

%Making calculatation to get it to fit with the sacled time and make it
%such matlab likes it 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 

c.V=465/1000*c.At; 

%% Running the simulation 
simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%save('global_controller_465_mm.mat')
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

%% Loading in reference controller water volume 
addpath("..\..\Reference controller\")
refCon=load('Reference_controller.mat') 

%% Making the plot 
x=0:size(summedMassflow,1)-1;
f = figure('Position', [100, 100, 800, 400]);  % Adjust position and size as needed
% Electricity prices and summed mass flow for each time stamp 
subplot(3,1,1)
hold on
yyaxis left
ylabel('$\sum q_i$ [m$^{3}$/h]', 'Interpreter', 'latex');
stairs(x,summedMassflow) 
yyaxis right 
ylabel('Price [Euro/kWh]', 'Interpreter', 'latex');
stairs(x,ElPrices)
xlabel('Time [h_a]') 
grid 
xlim([0 72])
hold off 
set(gca,'fontname','times')

% Volume in the water tower: 
subplot(3,1,2) 
hold on 
x=0:size(Volume,1)-1;
plot(x,Volume)
plot(refCon.RefCon.simData.logsout{11}.Values.Time(refCon.startIndex:end)*6/3600-1,refCon.RefCon.simData.logsout{11}.Values.Data(refCon.startIndex:end)/1000*c.At,'color','#EDB120')
yline(c.Vmax)
yline(c.Vmin)
hold off 
legend('Global','Reference','Constraints')
ylabel('Volume [m^{3}]') 
xlim([0 72])
grid 
xlabel('Time [h_a]') 
set(gca,'fontname','times')

%Predicted consumption and presented consumption
subplot(3,1,3)
hold on 
x=0:size(consumptionPred,1)-1;
stairs(x,consumptionPred)
stairs(x,consumptionNoise,'color',"#77AC30")
hold off 
grid 
%legend('Predicted consumption','Actual consumption')
legend('Predicted flow','Actual flow')
xlim([0 72])
ylabel('Mass flow [m^{3}/h]' )
xlabel('Time [h_a]') 
set(gca,'fontname','times')
% Adjust position to make it wider

%a = annotation('rectangle',[0 0 0 0],'Color','w');

exportgraphics(f,'global_controller_scaled_with_disturbance_with_Kappa.pdf','ContentType','vector')

%delete(a)
 




