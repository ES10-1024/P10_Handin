%% A bit of spring cleaning 
clear 
clf 
close all 
clc 


%% Loading in the data:
addpath("C:\Users\is123\Downloads\")

fixed=load("Stopping_own.mat");
varaible=load("stopping_criteria_boyd.mat");

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
ylabel('Iterations number')
set(gca,'fontname','times')
hold off 
grid 
legend('Fixed','Varying')



exportgraphics(f,'fixed_vs_varying_iterations.pdf','ContentType','vector')

%% Plotting performance: 
f=figure
ax=axes; 
hold on 
stairs(fixed.performanceEnd)
stairs(varaible.performanceEnd)
xlabel('Hours [h_a]')
ylabel("Performance")
set(gca,'fontname','times')
hold off 
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'
legend('Fixed','Varying')

exportgraphics(f,'fixed_vs_varying_performance.pdf','ContentType','vector')


