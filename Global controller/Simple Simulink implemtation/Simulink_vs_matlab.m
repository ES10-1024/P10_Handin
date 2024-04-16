clear 
clf 
close all 

addpath("Global control test on lab\")


load("controller.mat")

sum_flow_command_lab=squeeze(ctrl.actuation.Data(1,:,1:end)+ctrl.actuation.Data(2,:,1:end))

%Smider den først væk der vil Lau fylde vand på systemet: 
sum_flow_command_lab=sum_flow_command_lab(2:end,1); 
load("SimulinkController.mat") 



sum_flow_command_Simulink=squeeze(simData.logsout{1}.Values.Data(1,:,1:end)+simData.logsout{1}.Values.Data(2,:,1:end));

clf 
hold on 
stairs(sum_flow_command_lab)
stairs(sum_flow_command_Simulink)
hold off 
grid 
legend("Lab","Simulink")
xlabel('Time [hr]')
ylabel('Summed acutation signal [m^{3}/s]') 

%Plotting water volume difference 
WaterHeightmmSimulink=simData.logsout{3}.Values.Data; 
load('tower34.mat') 
%%
WaterHeightmmLabAll=tow34.tank_34_mm.Data;
TimesAll=tow34.tank_34_mm.Time; 
%Igen så bort fra den først måling 
index=1; 
TimelookingFor=600; 
for i=1:size(WaterHeightmmLabAll,3); 
if  round(TimesAll(i,1))==TimelookingFor
    WaterHeightmmLab(index,1)=WaterHeightmmLabAll(1,1,i); 
    TimelookingFor=TimelookingFor+600;
    index=index+1;
end

end 
%%
clf
hold on 
plot(WaterHeightmmLab)
plot(WaterHeightmmSimulink) 
hold off 
xlabel('Time [hr]') 
ylabel('Water height [mm]')
grid on 

legend("Lab","Simulink")



