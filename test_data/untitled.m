%% Doing a bit of spring 
clear 
clf 
close all 
clc 
%% adding a few paths, and loading in scaled standard constants  
addpath('C:\Users\is123\Downloads')
addpath('..\')
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Consensus ADMM\Functions\")
c=scaled_standard_constants; 
%% 

globalCon=load("global.mat");
distrubtedCon=load("distrubted_SMPC.mat"); 


simResult=load("Simulated_results_fmincon240hr.mat"); 


%% 
f=figure
hold on 
plot(globalCon.global_con.tower_tank_level) 
plot(distrubtedCon.tow.tank_tower_mm)
hold off 
xlim([0 119])
grid 
xlabel('Time [h_a]')
ylabel('Tank level [mm]')
%% 
f=figure
hold on 
plot(distrubtedCon.ADMM_1.rho(10:10:end))
plot(simResult.consensusCon.simData.logsout{17}.Values.data/500)
hold off 
grid 

%% Determining performance.
simTime=floor(size(distrubtedCon.ADMM_1.x_i,2)/125); 
scaledCostfunction=true;
time1=1;
for time=1:125:size(distrubtedCon.ADMM_1.x_i,2)
        % Solving the Global optimization problem
        %Setting up the data such it can be used by the function: 
        data.d(:,:,1) = distrubtedCon.pump1.electricity_price(:,time1); 
        data.Je(:,1) = distrubtedCon.pump1.demand_pred(:,time1); 
        data.V=distrubtedCon.tow.tank_tower_mm(1,time1)/1000*c.At;  
        %Solving the global optimization problem: 
        c.d = distrubtedCon.pump1.electricity_price(:,time1);
        c.Je = distrubtedCon.pump1.demand_pred(:,time1); 
        c.V = distrubtedCon.tow.tank_tower_mm(1,time1)/1000*c.At; 
        [globalUsed(:,time1),globalU(:,time1)] = mpcRunV2Casadi(data,zeros(c.Nu*c.Nc),scaledCostfunction); 
        
        %Determinging the cost of the global controller 
        costGlobal(:,time1) = costFunction(globalU(:,time1),c,scaledCostfunction);
       for k=1:125 
            % Determing cost consensus ADMM 
            for index=1:48 
                if mod(index,2)==0 
                    %even number
                    mathcalU(index,1) = distrubtedCon.ADMM_1.x_i(index,time+k-1); 
                else 
                    %odd number 
                    mathcalU(index,1) = distrubtedCon.ADMM_2.x_i(index,time+k-1);
                end 
            end
           
           costConsensus(k,time1)=costFunction(mathcalU,c,scaledCostfunction);
           costDifference(k,time1)=costConsensus(k,time1)-costGlobal(:,time1);
           procentDifference(k,time1)=costDifference(k,time1).*inv(costGlobal(:,time1)).*100;
       end 
    time1=time1+1
end

%% 
time1=1;
for time=1:125:size(distrubtedCon.ADMM_1.x_i,2)

        c.d = distrubtedCon.pump1.electricity_price(:,time1);
        c.Je = distrubtedCon.pump1.demand_pred(:,time1); 
        c.V = distrubtedCon.tow.tank_tower_mm(1,time1)/1000*c.At; 

        globalU(:,time1)=globalCon.global_con.Solution(:,time1);
        %Determinging the cost of the global controller 
        costGlobal(:,time1) = costFunction(globalU(:,time1),c,scaledCostfunction);
       for k=1:125 
            % Determing cost consensus ADMM 
            for index=1:48 
                if mod(index,2)==0 
                    %even number
                    mathcalU(index,1) = distrubtedCon.ADMM_1.x_i(index,time+k-1); 
                else 
                    %odd number 
                    mathcalU(index,1) = distrubtedCon.ADMM_2.x_i(index,time+k-1);
                end 
            end
           
           costConsensus(k,time1)=costFunction(mathcalU,c,scaledCostfunction);
           costDifference(k,time1)=costConsensus(k,time1)-costGlobal(:,time1);
           procentDifference(k,time1)=costDifference(k,time1).*inv(costGlobal(:,time1)).*100;
       end 
    time1=time1+1
end

%% 
plot(procentDifference)
grid


 