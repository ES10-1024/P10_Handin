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
%Determining predicted sum: 
index=1; 
for i=1:2:48 
    predSummedMassFlows(index,1)=simData.logsout{2}.Values.Data(end,i)+simData.logsout{2}.Values.Data(end,i+1);
    index=index+1; 
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
%% 
%Getting predicted volumes: 
VolumePred = ModelPredicted(Volume(end-1),simData.logsout{2}.Values.Data(end,:)',simData.logsout{4}.Values.Data(:,:,end));

%% Loading in reference controller water volume 
addpath("..\..\Reference controller\")
refCon=load('Reference_controller.mat') 
%% Adding flows up 
refCon.summedFlows=refCon.RefCon.simData.logsout{1}.Values.Data+refCon.RefCon.simData.logsout{2}.Values.Data;

%% Making the plot 
x=0:size(summedMassflow,1);
f = figure('Position',[10 10 900 600])
% Adjust position and size as needed
% Electricity prices and summed mass flow for each time stamp 
tiledlayout(4,1, "TileSpacing","compact")

nexttile
hold on
    ylabel('Electricity price [EUR/kWh]')
    xlabel('Time [h_a]')
p1=stairs(x,[ElPrices,ElPrices(end)],'color','#77AC30')
x=80:80+24-1;
p2=stairs(x,simData.logsout{6}.Values.Data(:,1,end),'color','#EDB120')
grid 
xlim([0 104])
hold off 
set(gca,'fontname','times')

%Mass flows
x=0:size(summedMassflow,1);
nexttile
hold on 
%ON/OFF controller: 
plot(refCon.RefCon.simData.logsout{11}.Values.Time(refCon.startIndex:end)*6/3600-1,refCon.summedFlows(refCon.startIndex:end),'color','#A2142F')
%global controller:

%ylabel('$\sum q_i$ [m$^{3}$/h]', 'Interpreter', 'latex');
stairs(x,[summedMassflow;summedMassflow(end)],'color','#7E2F8E') 
x=80:80+24-1;
stairs(x,predSummedMassFlows,'color','#EDB120')



    ylabel('Sum of flows [m^3/h]')
    xlabel('Time [h_a]')
    grid on
xlim([0 104])
hold off 
set(gca,'fontname','times')

% Volume in the water tower: 
nexttile
hold on 
x=0:size(Volume,1)-1;
p3=plot(x,Volume*1000,'color','#7E2F8E')
p4=plot(refCon.RefCon.simData.logsout{11}.Values.Time(refCon.startIndex:end)*6/3600-1,refCon.RefCon.simData.logsout{11}.Values.Data(refCon.startIndex:end)/1000*c.At*1000,'color','#A2142F')

x=80:80+24-1;
plot(x,VolumePred*1000)
yline(c.Vmax*1000)
yline(c.Vmin*1000)
hold off 
%legend('Global','Reference','Constraints')
    ylabel("Volume in tower [L]")
    xlabel('Time [h_a]')
    xlim([0 104])
grid 
set(gca,'fontname','times')

%Predicted consumption and presented consumption
nexttile


hold on 
x=0:size(consumptionPred,1);
%Plotting colors in the orden it is desired 

% stairs(x,[consumptionPred;consumptionPred(end)],'Color','#EDB120','LineWidth',0.05)
% stairs(x,[consumptionPred;consumptionPred(end)],'Color','#7E2F8E','LineWidth',0.05)
% stairs(x,[consumptionPred;consumptionPred(end)],'Color','#77AC30','LineWidth',0.05)
% stairs(x,[consumptionPred;consumptionPred(end)],'Color','#A2142F','LineWidth',0.05)


x=0:size(consumptionPred,1);
stairs(x,[consumptionPred;consumptionPred(end)],'color',"#EDB120") %#EDB120
x=80:80+24-1;
stairs(x,simData.logsout{4}.Values.Data(:,end),'color','#EDB120')
x=0:size(consumptionPred,1);


x=0:size(consumptionPred,1);
stairs(x,[consumptionNoise;consumptionNoise(end)],'color','#77AC30')
hold off 
grid 
%legend('Predicted consumption','Actual consumption')
%legend('Predicted flow','Actual flow')
xlim([0 104])
    ylabel('Consumption [m^3/h]')
    xlabel('Time [h_a]')
set(gca,'fontname','times')
h = [p1(1),p2(1),p3(1),p4(1)]; 
lgd = legend(h," Commanded", "Predictionn", "Global controller measured/commanded"," ON/OFF controller measured", 'Orientation','Horizontal')
 
lgd.Layout.Tile = 'south';


% Adjust position to make it wider

%a = annotation('rectangle',[0 0 0 0],'Color','w');

exportgraphics(f,'global_controller_scaled_with_disturbance_with_Kappa.pdf','ContentType','vector')


%delete(a)
 




