%% Script to run the reference contorller implemented in Matlab, and work on the data gotten 

%% Making a bit of cleaning 
clear 
clf 
clc
close all 
%% Adding paths and scaled standard constants
addpath("..\Global controller\Subsystem Reference\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Global controller\Simple Simulink implemtation\")
addpath("..\")
addpath("Simulink implementation\")
addpath("Simulink implementation\Subsystem reference\")
addpath("..\Consensus ADMM\Functions\")
c=scaled_standard_constants; 
%% Define simulation time 
simHour=24*10+1; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 
%% Simulating the global controller
RefCon.simData=sim('Reference_controller.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','30');

%% Finding index to remove the first hour (set to 0 to allow the physical system to start up
timeToFind=600;
startIndex = find(RefCon.simData.logsout{11}.Values.Time >= timeToFind, 1);

%% Plottng volume in the tower
waterHeightmin=c.Vmin/c.At*1000;

waterHeightmax=c.Vmax/c.At*1000; 
% Extract the data you want to plot
data = RefCon.simData.logsout{4}.Values.Data(1, 1, :);

% Reshape the data to a 1D array
data = reshape(data, 1, []);
f=figure
hold on 
plot(RefCon.simData.logsout{11}.Values.Time(startIndex:end)*6/3600,RefCon.simData.logsout{11}.Values.Data(startIndex:end))
yline(waterHeightmin)
yline(waterHeightmax)
hold off 
xlim([0 240])
grid 
ylabel('Water level [mm]')
xlabel('Time [h_a]')
set(gca,'fontname','times')
exportgraphics(f,'refConWaterLevel.pdf')

%% Determing the eletricity bill 
bill=0;
index=1; 
indexHour=2; 

%Determining the amount of samples, between changes in eletricity prices
%and consumption 
samplesToNew=600/RefCon.simData.logsout{10}.Values.Data(2,1); 
NextHour=0;
pumped=0; 

%Looping tough to determine the electricity price 
for time=startIndex:size(RefCon.simData.logsout{11}.Values.Time,1)
        %Picking out predicted consumption and eletricity prices 
        Je=RefCon.simData.logsout{4}.Values.Data(:,1,indexHour);
        c.d=RefCon.simData.logsout{6}.Values.Data(:,1,indexHour);
        NextHour=NextHour+1; 
        if NextHour==20 
            NextHour=0; 
            indexHour=indexHour+1; 
        end 
        
        %Sample time, pump mass flow right now, and current water volume. 
        c.ts=RefCon.simData.logsout{10}.Values.Data(time,1);  
        uAll=[RefCon.simData.logsout{1}.Values.Data(time,1);RefCon.simData.logsout{2}.Values.Data(time,1)]; 
        V=RefCon.simData.logsout{11}.Values.Data(time,1)/1000*c.At; 


        %Determinging the electricity bill: 
        temp = eletrictyBillV2(uAll,Je,c,V);
        bill(index+1,1) = bill(index,1)+temp; 
        index=index+1; 
end 


