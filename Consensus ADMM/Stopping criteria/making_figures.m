%% A bit of spring cleaning 
clear 
clf 
close all 
clc 


%% Loading in the data:
addpath("C:\Users\is123\Documents\GitHub\P10_Handin\Consensus ADMM\Saved workspaces V4")
addpath('..\..\')
addpath('..\..\Global controller\Simple Simulink implemtation\Functions\')
c=scaled_standard_constants; 

fixed=load("Stopping_own_V2.mat");
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
xlim([200 400])


exportgraphics(f,'fixed_vs_varying_iterations_short.pdf','ContentType','vector')

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
xlim([200 400])
ylim([-0.01 0.25])

exportgraphics(f,'fixed_vs_varying_performance_short.pdf','ContentType','vector')
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

%%  Checking for consensus! 

c.V=fixed.c.V; 

for time=1:1000

    %Skal laves om til at anvende det noget fra simulering! 
        [consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
        %Moving the predicted consumption to a struct for each use to functions
        c.d=consumptionPred;
        
        %Determing the volume for each, of the 3 stakeholders 
        
        
        Vx1(:,time)=ModelPredicted(c.V,fixed.Xsave(:,1,varaible.lastNonZeroIndices(1,time),time),c.d);
        Vx2(:,time)=ModelPredicted(c.V,fixed.Xsave(:,2,varaible.lastNonZeroIndices(1,time),time),c.d);
        Vx3(:,time)=ModelPredicted(c.V,fixed.Xsave(:,3,varaible.lastNonZeroIndices(1,time),time),c.d);
        
        %Determing difference: 
        Diff1(:,time)=abs(Vx1(:,time) - Vx2(:,time)); 
        Diff2(:,time)=abs(Vx1(:,time) - Vx3(:,time));
        Diff3(:,time)=abs(Vx2(:,time) - Vx3(:,time)); 

        maxDiff(:,time)=max(max(Diff1(:,time),Diff2(:,time)),Diff3(:,time));

end 
maxDiff=maxDiff*1000;
%% Making the plot 
f=figure
plot(maxDiff(end,:))
set(gca,'fontname','times')
xlabel('Time [h_a]')
ylabel('Max abs diff from consensus [L]')
grid 
a = annotation('rectangle',[0 0 0 0],'Color','w');
exportgraphics(f,'max_diff_from_consensus.pdf','ContentType','vector')
delete(a)

%%  Plotting the predicted volume for a given hour
time=993;
hold on
    plot(Vx1(:,time))
    plot(Vx2(:,time))
    plot(Vx3(:,time))
    yline(c.Vmin)
    yline(c.Vmax)
hold off 
 



