%% Script to determine the smallest value of kappa which ensure that the average procentwise difference between current water volume and water volume in 24 hours is approximatly the same 
%% Doing a bit of cleaning 
clear 
clc 
clf
close all 
%% 
%Selected if the cost function should be scaled

scaledCostfunction=true; 

%If the eletricity price should be scaled such that the 2-norm always equal
%the first hour! 
scaledEletricityPrice=true;

%Hours it is desired to simulate: 
simHour=500; 


%% Loading in standard Constants and adding a few paths 
addpath("..\..\")
addpath("Plots\")
addpath("..\Simple Simulink implemtation\Functions\")
addpath("..\..\Consensus ADMM\Functions\")


c=scaled_standard_constants;


%% Making A and v matrices for the optimization problem
%A_1 each row have 2 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix to add consumption and inflow (integral) 
 c.A_2 = tril(ones(c.Nc,c.Nc));

%Making vi vectors utilized to pick out 1 of the 2 pumps values, add them up
%and used to make extration limit. 
c.v1=ones(c.Nu*c.Nc,1);
c.v1(2:c.Nu:end) =0; 

c.v2=ones(c.Nu*c.Nc,1);
c.v2(1:c.Nu:end) =0;

%Making matrix which picks out 1 of the pumps for the enitre control
%horizion
c.A_31=[];
for i=1:c.Nc
    c.A_31 = blkdiag(c.A_31,[1 0]);
end

c.A_32=[];
for i=1:c.Nc
    c.A_32 = blkdiag(c.A_32,[0 1]);
end
clear i


%% Setting water volume for the two optimization problems 
Vglobal=c.V; 

%% Going though x hours of simulation 
tic


for time=1:simHour 
 %Getting new electricity prices and demand 
    %Current time in accelerted secondes! 
    currentTime=time*c.ts;
    [c.Je] = ElectrictyPrices(currentTime);
    %Scaling the electricity such its 2-norm is one if it is desired
    if scaledEletricityPrice==true 
    %Scaling the eletricity price to be the same: 
    c.Je=c.Je/norm(c.Je); 
    end 
    %Getting the predicted and actual consumption: 
    [consumptionPred,consumptionAcutal] = consumption(currentTime);
    %Moving the predicted consumption to a struct so it is easier to work
    %with 
    c.d=consumptionPred; 
%% Global problem

%Setting the current water volume for the global optimization problem : 
c.V=Vglobal(time,1);

%Setting up the data such it can be used by the function: 
data.d(:,:,1)=c.d; 
data.Je(:,1)=c.Je; 
data.V=c.V; 

%Solving the global optimization problem: 
[globalUsed(:,time),globalU(:,time)] = mpcRunV2(data,zeros(c.Nu*c.Nc),scaledCostfunction); 

%Determine the next water volume 
Vglobal(time+1,1)=Model(c.V,globalU(:,time),consumptionAcutal);

%Determine all the predicted volume which the solution would give 
VglobalPredictedGlobal(:,time)=ModelPredicted(c.V,globalU(:,time),c.d); 

%Determining the procent wise difference between the current volume and at
%the end of the control horzion. 
VDifferenceGlobal(time)=(Vglobal(time,1)-VglobalPredictedGlobal(end,time))/Vglobal(time,1)*100; 



end

%% Plotting the procentwise difference between the current volume and the volume at the end of the prediction horzion: 
FrontSize=16;

f= figure

stairs(VDifferenceGlobal)
xlabel('Time [hr]','FontSize',FrontSize)
ylabel('Procent Wise difference now and in 24 hours','FontSize',FrontSize) 
fontname(f,"Times")
grid

%% Plotting the current volume and the voulme in 24 hours 
f=figure
hold on 
stairs(Vglobal(1:end-1))
stairs(VglobalPredictedGlobal(end,:))
hold off 
xlabel('Time [hr]','FontSize',FrontSize)
ylabel('Water Volume [m^{3}]','FontSize',FrontSize)
grid on
legend('Now','24 hours')

%exportgraphics(f,'Plots/two_plots_scaled_k=700.pdf')
 


