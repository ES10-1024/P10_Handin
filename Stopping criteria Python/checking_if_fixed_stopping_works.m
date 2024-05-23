%% A bit of spring cleaning! 
clear 
clf 
close all 
clc 

%% 
addpath("New data\") 
load("short_new_sim_data_global.mat") 
load("short_new_sim_data_ADMM.mat")
%% adding a few paths, and loading in scaled standard constants  
addpath('C:\Users\is123\Downloads')
addpath('..\')
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Consensus ADMM\Functions\")
c=scaled_standard_constants; 


%% Picking out the use mass flows to check for consensus 
%Find the columen which a new one starts
indicesOri = find(ADMM_1.k== 1); 
%Subcstat one such we get the end, and removing the unused columen: 
indices=indicesOri(2:end)-1;

for index=2:size(indices,2) 
    x1used(:,index-1)=ADMM_1.x_i(:,indices(index));
    x2used(:,index-1)=ADMM_2.x_i(:,indices(index));
    x3used(:,index-1)=ADMM_3.x_i(:,indices(index));
end 


%     x1used=ADMM_1.x_i(:,end);
%     x2used=ADMM_2.x_i(:,end);
%     x3used=ADMM_3.x_i(:,end);

%%  Checking for consensus! 

for time=1:1
        [consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
        %Moving the predicted consumption to a struct for each use to functions
        c.d=consumptionPred;
        
        %Determing the volume for each, of the 3 stakeholders 
        c.V=470/1000*c.At; 
        
        Vx1(:,time)=ModelPredicted(c.V,x1used(:,time),c.d);
        Vx2(:,time)=ModelPredicted(c.V,x2used(:,time),c.d);
        Vx3(:,time)=ModelPredicted(c.V,x3used(:,time),c.d);
        
        %Determing difference: 
        Diff1(:,time)=abs(Vx1(:,time)-Vx2(:,time)); 
        Diff2(:,time)=abs(Vx1(:,time)- Vx3(:,time));
        Diff3(:,time)=abs(Vx2(:,time)-Vx3(:,time)); 

        maxDiff(:,time)=max(max(Diff1(:,time),Diff2(:,time)),Diff3(:,time));

end 
maxDiff=maxDiff*1000;
%% 
hold on 
plot(Vx1(:,time))
plot(Vx2(:,time))
plot(Vx3(:,time))
yline(0.028)
hold off 
%%
plot(maxDiff(end,:))
ylabel('Difference from consensus water [L]')
xlabel('Time [h_a]')
grid
%% Checking performance 
scaledCostfunction=true;
hold on 
for time=1:37 %size(indicesOri,2)-1 

        c.d = pump1.electricity_price(:,time);
        c.Je = pump1.demand_pred(:,time); 
        c.V = 200/1000*c.At; 
    i=1;    
    for k=indicesOri(time):indicesOri(time+1)-1
        for j=1:48 
            if mod(j,2)==0 
                %even number 
                xused(j,i,time)=ADMM_3.x_i(j,k);
            else 
                %odd number
                xused(j,i,time)=ADMM_2.x_i(j,k);
            end 
        end
        costGlobal(:,time) = costFunction(globalCon.Solution(:,time),c,scaledCostfunction);
           
        costConsensus(i,time)=costFunction(xused(:,i,time),c,scaledCostfunction);
        costDifference(i,time)=costConsensus(i,time)-costGlobal(:,time);
        procentDifference(i,1,time)=costDifference(i,time).*inv(costGlobal(:,time)).*100;
        i=i+1;
         
    end 
    plot(procentDifference(:,1,time))
    time
end 

hold off 
procentDifference=squeeze(procentDifference); 
%% 
plot(procentDifference)

