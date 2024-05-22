%% A bit of spring cleaning 
clear 
clf 
close all 
clc 


%% Loading in the data:
addpath("C:\Users\is123\Documents\GitHub\P10_Handin\Consensus ADMM\Saved workspaces V4")

fixed=load("Stopping_own.mat");
varaible=load("stopping_criteria_boyd.mat");

fixed125=load("1000hr_mu5_tau1d5_rho_V32"); 

%% 
% Loop through each column
for col = 1:size(fixed.procentDifference, 2)
    % Find indices of non-zero elements in the column for the fixed
    temp = find(fixed.procentDifference(:, col) ~= 0);
    fixed.lastNonZeroIndices(col)=temp(end);  
    %Picking out performance values
    fixed.performanceEnd=fixed.procentDifference(fixed.lastNonZeroIndices,col); 

    % Find indices of non-zero elements in the column for the fixed
    temp = find(varaible.epsilonDual(:, col) ~= 0);
    varaible.lastNonZeroIndices(col)=temp(end);  
    %Picking out performance values
    varaible.performanceEnd=varaible.procentDifference(varaible.lastNonZeroIndices,col); 
end
%% Plotting number of iterations:
f=figure
hold on 
stairs(fixed.lastNonZeroIndices)
stairs(varaible.lastNonZeroIndices)
xlabel('Hours [h_a]')
ylabel('Iterations')
set(gca,'fontname','times')
hold off 
grid 
legend('Constant','Varying','Location','northwest')
%xlim([200 400])


exportgraphics(f,'fixed_vs_varying_iterations.pdf','ContentType','vector')

%% Plotting performance: 
f=figure
ax=axes; 
hold on 
stairs(fixed.performanceEnd)
stairs(varaible.performanceEnd)
stairs(fixed125.procentDifference(125,:))
xlabel('Hours [h_a]')
ylabel("Performance")
set(gca,'fontname','times')
hold off 
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'
legend('Constant','Varying','125','Location','northwest')
%xlim([200 400])
ylim([-0.01 0.25])

exportgraphics(f,'fixed_vs_varying_performance.pdf','ContentType','vector')
%% Determine the number of iterations 
for time=1:1000 
    %First addning those need for varying rho in the start these are always
    %constant:
    communicationNumber(time,1)=20; 
    %Afterwards adding those for each iteration for consensus ADMM: 
    communicationNumber(time,1)=communicationNumber(time,1)+fixed.lastNonZeroIndices(time); 
    %Next it is neccesary to determine for the stopping criteria,
    communicationNumber(time,1)=communicationNumber(time,1)+floor((fixed.lastNonZeroIndices(time)-35)/5)*2+2;
end 


