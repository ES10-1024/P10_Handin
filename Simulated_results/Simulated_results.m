%% In this script simulated result from the global and consensus ADMM controller is compared 
%% Making a bit of cleaning 
clear 
clf 
clc
close all 
%% Adding paths and scaled standard constants
addpath("..\Global controller\Subsystem Reference\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Global controller\Simple Simulink implemtation\")
addpath("..\Consensus ADMM\Functions\")
addpath("..\Consensus ADMM\Simulink implementing\")
addpath("..\Consensus ADMM\Simulink implementing\Functions\")
addpath("..\Consensus ADMM\Simulink implementing\Subsystem Reference\")
addpath("..\Shamirs Secret Sharing\Functions\")
%c=scaled_standard_constants; 
%% Define simulation time 
simHour=250 ; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 
%% Simulating the global controller
globalCon.simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% Simulating the consensus controller 
consensusCon.simData=sim('ADMM_consensus.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% 
save('Simulated_results_fmincon240hr.mat')

%% Picking out a few things which is needed for the comparision: 
%Summing the mass flows at each time step  [m^3/h]
for index=2:size(globalCon.simData.logsout{1}.Values.Data,3)
    globalCon.summedMassflow(index-1,1)=globalCon.simData.logsout{1}.Values.Data(1,1,index)+globalCon.simData.logsout{1}.Values.Data(2,1,index);
    consensusCon.summedMassflow(index-1,1)=consensusCon.simData.logsout{15}.Values.Data(index,1)+consensusCon.simData.logsout{16}.Values.Data(index,1);
end 
%%
%Picking out the eletricity prices 
globalCon.ElPrices=squeeze(globalCon.simData.logsout{6}.Values.Data(1,1,2:end));
consensusCon.ElPrices=squeeze(consensusCon.simData.logsout{7}.Values.Data(1,1,2:end));

%Taking out the actual consumption 
consumptionActual=globalCon.simData.logsout{5}.Values.Data(2:end,1); 

%Taking out the predicted consumption  
globalCon.consumptionPred=squeeze(globalCon.simData.logsout{4}.Values.Data(1,1,2:end)); 
consensusCon.consumptionPred=squeeze(consensusCon.simData.logsout{6}.Values.Data(1,1,2:end));

%Getting the volume [m^3]
globalCon.Volume=globalCon.simData.logsout{3}.Values.Data/1000*c.At; 
consensusCon.Volume=consensusCon.simData.logsout{19}.Values.Data(2:end,1);
%% Determine the electricity bill

%Sarting with getting a vector of all the mass flows in the prediction horizion for the the given time stamp (only needs the two first, but might as well get all)  
for index1=2:size(globalCon.simData.logsout{1}.Values.Data,3)
    index=1; 
    for i=1:c.Nu*c.Nc
        consensusCon.uAll(i,index1)=consensusCon.simData.logsout{14}.Values.Data(i,index,index1);
        index=index+1; 
        if index==3 
            index=1; 
        end 
    end 
end 
%% 
%What water volume should be used? 
%Determinging the electricity bill   and cost function, 
for index=2:size(globalCon.simData.logsout{1}.Values.Data,3)-1
    c.d=globalCon.simData.logsout{4}.Values.Data(:,:,index);
    [ElPrices] = ElectrictyPrices(index*c.ts);
    %Eletricity bill 
    if index==2 
        [globalCon.Bill(index-1,1)]= eletrictyBillV2(globalCon.simData.logsout{2}.Values.Data(index,:)',ElPrices,c,globalCon.Volume(index-1,1));
        [consensusCon.Bill(index-1,1)]= eletrictyBillV2(consensusCon.uAll(:,index),ElPrices,c,consensusCon.Volume(index-1,1));
        procentEldiff(index-1,1)=(consensusCon.Bill(index-1,1)-globalCon.Bill(index-1,1))/globalCon.Bill(index-1,1)*100;

    else
       [globalCon.Bill(index-1,1)] = eletrictyBillV2(globalCon.simData.logsout{2}.Values.Data(index,:)',ElPrices,c,globalCon.Volume(index-1,1));
        globalCon.Bill(index-1,1)=globalCon.Bill(index-1,1)+globalCon.Bill(index-2,1);
       [consensusCon.Bill(index-1,1)]= eletrictyBillV2(consensusCon.uAll(:,index),ElPrices,c,consensusCon.Volume(index-1,1));
        consensusCon.Bill(index-1,1)=consensusCon.Bill(index-1,1)+consensusCon.Bill(index-2,1);
       procentEldiff(index-1,1)=(consensusCon.Bill(index-1,1)-globalCon.Bill(index-1,1))/globalCon.Bill(index-1,1)*100;

    end 
        c.Je=ElPrices; 
        scaledCost=true; 
        %Cost: 
        c.V=globalCon.Volume(index,1);
        globalCon.cost(index-1,1)=costFunction(globalCon.simData.logsout{2}.Values.Data(index,:)',c,scaledCost);
        c.V=consensusCon.Volume(index,1);
        consensusCon.cost(index-1,1)=costFunction(consensusCon.uAll(:,index),c,scaledCost); 
        costDifference(index-1,1)=consensusCon.cost(index-1,1)-globalCon.cost(index-1,1); 
        procentDifference(index-1)=costDifference(index-1,1).*inv(globalCon.cost(index-1,1)).*100;
        
end 
%% Making the plot 

%Mass flow  and electricty prices 
f=figure
subplot(5,1,1)
hold on
ylabel('Mass flow [m^{3}/h]' )
hold on 
stairs(globalCon.summedMassflow) 
stairs(consensusCon.summedMassflow)
hold off 
yyaxis right 
ylabel('El Prices [Euro/kWh]') 
stairs(globalCon.ElPrices)
xlabel('Hours scaled') 
grid 

legend('Global Summed pump mass flow','Consensus Summed pump mass flow','Eletricity prices','Location','bestoutside') 
%xlim([0 1000])
hold off 
set(gca,'fontname','times')

%Volume 
subplot(5,1,2) 
hold on 
plot(globalCon.Volume)
plot(consensusCon.Volume)
yline(c.Vmax)
yline(c.Vmin)
hold off 
legend('Global Volume','Consensus Volume','Constraints','Location','bestoutside')
ylabel('Volume [m^{3}]') 
%xlim([0 1000])
grid 
xlabel('Hours scaled') 
set(gca,'fontname','times')

%Prediction consumption and actual consumption 
subplot(5,1,3)
hold on 
stairs(globalCon.consumptionPred)
stairs(consumptionActual)
hold off 
grid 
legend('Predicted consumption','Actual consumption','Location','bestoutside')
%xlim([0 1000])
ylabel('Mass flow [m^{3}/h]' )
xlabel('Hours scaled') 
set(gca,'fontname','times')

%Electricty bill 
subplot(5,1,4) 
hold on 
plot(globalCon.Bill)
plot(consensusCon.Bill)
hold off 
legend('Global','Consensus','Location','bestoutside')
grid 
xlabel('Scaled hours') 
ylabel('El Bill [Euro]') 
set(gca,'fontname','times')

%Procent wise difference in electricty bill between the global and
%consensus ADMM 
subplot(5,1,5) 
hold on 
plot(procentEldiff)
yline(0)
hold off
grid 
xlabel('Scaled hours') 
ylabel('Pro diff el bill')

set(gca,'fontname','times')
%exportgraphics(f,'consensus_vs_global_simulated.pdf')

%ylim([-1.5 0.5])




%% 
disp("Electricity bill difference is") 
elProDiff=(consensusCon.Bill(end,1)-globalCon.Bill(end,1))/globalCon.Bill(end,1)*100
disp("Procent")

%% 
f = figure;

% Summed mass flows
subplot(3,1,1)
hold on
ylabel('Global $\sum q_i$ [m$^{3}$/h]', 'Interpreter', 'latex');
yyaxis left 
stairs(globalCon.summedMassflow) 
yyaxis right 
stairs(consensusCon.summedMassflow)
ylabel('ADMM $\sum q_i$ [m$^{3}$/h]', 'Interpreter', 'latex');
hold off 
grid  on 
set(gca,'fontname','times')
xlim([0 240])

% Volume 
subplot(3,1,2)
yyaxis left 
plot(globalCon.Volume)
ylabel('Global Volume [m$^{3}$]', 'Interpreter', 'latex');
yyaxis right 
plot(consensusCon.Volume)
ylabel('ADMM Volume [m$^{3}$]', 'Interpreter', 'latex');
yline(c.Vmax)
yline(c.Vmin)
xlim([0 240])
grid 
set(gca,'fontname','times')


% Eletricity price 
subplot(3,1,3)
stairs(globalCon.ElPrices)
xlabel('Time [h_a]') 
ylabel('Price [Euro/kWh]', 'Interpreter', 'latex');
grid
xlim([0 240])
set(gca,'fontname','times')

exportgraphics(f,'Sim_results.pdf','ContentType','vector') 




