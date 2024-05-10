%% Making alot of clears 
clf 
clc 
clear
close all
%% Adding path 
addpath('C:\Users\is123\Downloads')
addpath('..\')
addpath("..\Global controller\Simple Simulink implemtation\Functions\") 
addpath("..\Consensus ADMM\Functions\")
c=scaled_standard_constants;
%% Loading in the data: 
globalCon=load("global_controller.mat"); 
consensus=load("05-03_13-34.mat"); 
scaledCostfunction=true;
for index=2:size(globalCon.simData.logsout{2}.Values.Data,1)
    mathcalU=globalCon.simData.logsout{2}.Values.Data(index,:)';
    c.d=globalCon.simData.logsout{4}.Values.Data(:,1,index);
    c.V=globalCon.simData.logsout{3}.Values.Data(index,1)/1000*c.At; 
    c.Je=globalCon.simData.logsout{6}.Values.Data(:,1,index);
    costGlobal(:,index-1)=costFunction(mathcalU,c,scaledCostfunction);
end 
%% 
time1=1; 
for time=1:125:size(consensus.ADMM_1.x_i,2)
     c.d=consensus.pump2.demand_pred(:,time1);
     c.V=consensus.tow.tank_tower_mm(:,time1)/1000*c.At; 
 %    c.Je=consensus.pump2.electricity_price(:,time1);
     c.Je=globalCon.simData.logsout{6}.Values.Data(:,1,time1);
    for k=1:125 
        %Picking out mathcalU
        for index=1:48 
            if mod(index,2)==0 
                %even number
                mathcalU(index,1)=consensus.ADMM_1.x_i(index,time+k-1); 
            else 
                %odd number 
                mathcalU(index,1)=consensus.ADMM_2.x_i(index,time+k-1);
            end 
        end
       costConsensus(k,time1)=costFunction(mathcalU,c,scaledCostfunction);
       costDifference(k,time1)=costConsensus(k,time1)-costGlobal(:,time1);
       procentDifference(k,time1)=costDifference(k,time1).*inv(costGlobal(:,time1)).*100;
    end 
    time1=time1+1
end 
  
%% 
f=figure 
ax=axes; 
plot(procentDifference)
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'

xlabel("Iterations")
ylabel("Performance")
fontname(f,'Times')
set(gca,'fontname','times')
xlim([0 125])
ylim([-100 100])
exportgraphics(f,'Performance_ADMM_test.pdf','ContentType','image')
%% zoomed in version 

f=figure 
ax=axes; 
plot(procentDifference)
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'

xlabel("Iterations")
ylabel("Performance")
fontname(f,'Times')
set(gca,'fontname','times')
xlim([0 125])
ylim([-30 30])
exportgraphics(f,'Performance_ADMM_test_zoomed.pdf','ContentType','image')

%% 
% Extract the specified row
row_values = procentDifference(end,:);

% Define the range
lower_bound = -5;
upper_bound = 5;

% Count the number of elements within the range
count_within_range = sum(row_values >= lower_bound & row_values <= upper_bound);

disp('Number of elements within the range [-1, 1] at the end is: ');
disp(count_within_range)
%% 
hold on 
plot(globalCon.simData.logsout{3}.Values.Data(:,1)/1000*c.At)
plot(consensus.tow.tank_tower_mm(1,:)/1000*c.At)
hold off 