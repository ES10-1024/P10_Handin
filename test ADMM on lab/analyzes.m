%% Doing a bit of cleaning 
clf 
clear 
clc 
close all 
%% Adding a "few" path:
addpath("..\Global controller\Subsystem Reference\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Global controller\Simple Simulink implemtation\")
addpath("..\Consensus ADMM\Functions\")
addpath("..\Consensus ADMM\Simulink implementing\")
addpath("..\Consensus ADMM\Simulink implementing\Functions\")
addpath("..\Consensus ADMM\Simulink implementing\Subsystem Reference\")
addpath("..\Shamirs Secret Sharing\Functions\")
addpath("..\")
addpath("..\log")
c=scaled_standard_constants; 
%%  Loading in the data: 
load("05-02_11-32-14.mat")
%% Updating the water tower start volume 
c.V=tow.tank_tower_mm(1,1)/1000*c.At; 

simHour=floor(tow.tank_tower_mmTime(end,end)/3600*c.AccTime)+1;
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 

%% Simulation time 
globalCon.simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200'); 

%% 
consensusCon.simData=sim('ADMM_consensus.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%%
save('test.mat')
%%
hold on 
plot(tow.tank_tower_mm)
plot(consensusCon.simData.logsout{12}.Values.Data(end-1,1))
hold off 
grid 
xlabel('Time [h_a]')
ylabel('Water level [mm]')

legend('Lab','Sim')
%% Summing massflows 
for time=1:size(tow.tank_tower_mm,2)
    for j=1:24
        summedFlowsSim(j,time)=x1(j,time)
    end 
end 

%% Picking out the end result
index=1; 
for i=125:125:size(ADMM_1.x_i,2)
    x1(:,index)=ADMM_1.x_i(:,i);
    x2(:,index)=ADMM_2.x_i(:,i);
    x3(:,index)=ADMM_3.x_i(:,i);
    %Difference form simulation:
    for j=1:2:24
        x1Diff(floor(j/2)+1,index)=(x1(j,index)+x1(j+1,index))-(consensusCon.simData.logsout{14}.Values.Data(j,1,index+1)+consensusCon.simData.logsout{14}.Values.Data(j+1,1,index+1));
        x2Diff(floor(j/2)+1,index)=(x2(j,index)+x2(j+1,index))-(consensusCon.simData.logsout{14}.Values.Data(j,2,index+1)+consensusCon.simData.logsout{14}.Values.Data(j+1,2,index+1));
        x3Diff(floor(j/2)+1,index)=(x3(j,index)+x3(j+1,index))-(consensusCon.simData.logsout{14}.Values.Data(j,3,index+1)+consensusCon.simData.logsout{14}.Values.Data(j+1,3,index+1));
    end 
    index=index+1;
end 


