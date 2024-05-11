% Determine the procentwise difference between the global solution 
% and the consensus problem for the x hours
%%  Making a bit of cleaning 
clear 
clc 
clf
close all
%% Loading in standard Constants and adding a few paths.  
addpath("..\..\Global controller\Simple Simulink implemtation\Functions\") 
addpath("..\Functions\")
addpath("..\..\")

addpath("Plots\")

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

%% Initialization
%Amount of hour that should be simulated: 
hoursToSim=10; 
%Number of iterations that the consensus ADMM should go though: 
maxIterations=200; 
stopCriterionStart=35;
betweenStop=5;

%Defining the value of the penalty parameter 
c.rho=1;% 

%if a varying rho should be utilized: 
varying_rho=true; 

%Values for varying rho 
mu=5;  
tauIncr=1.5; 
tauDecr=1.5; 

%If the eletricity price should be scaled such that the 2-norm always equal
%one 
scaledEletricityPrice=true;

%Defining if underrelaxation should be utilized 
underrelaxation=false; 

%Setting if the scaled costFunction should be used
scaledCostfunction=true; 

% If there should be a difference between pred and actual consumption 
disturbanceConsumption=true; 

% If the same volume in the tower should be used for the global and
% consensus controller or if they should use the water volume which the
% last input would result in
useSameVolume=true; 

%Picking initial values for the consensus problems
z=zeros(c.Nc*c.Nu,1); 
lambda = zeros(c.Nc*c.Nu,c.Nu+1); 
x = zeros(c.Nc*c.Nu,c.Nu+1);
inputUsed=zeros(c.Nc*c.Nu,24); 



%% Setting water volume for the two optimization problems 
Vglobal(1,1)=c.V; 
Vconsensus(1,1)=c.V;


%% Going though x hours of simulation 
tic


for time=1:hoursToSim
 %Getting new electricy price and consumption new values with regard to demand and eletricity prices  
[c.Je] = ElectrictyPrices(time*c.ts); 
[consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
%Moving the predicted consumption to a struct for each use to functions
c.d=consumptionPred;
%Saving the electricity price for debugging 
ElSave(:,time)=c.Je;

%Scaling the electricity price such its 2-norm is 1 if desired 
if scaledEletricityPrice==true 
    c.Je=c.Je/norm(c.Je); 
end 

%If no disturbance is desired predicted consumption is set equal to actual consumption 
if disturbanceConsumption==false  
    consumptionActual(time,:)=consumptionPred(1,1); 
end 

%% Solving the Global optimization problem
%Setting up the data such it can be used by the function: 
data.d(:,:,1)=c.d; 
data.Je(:,1)=c.Je; 

%Setting the water volume based on if it should be the same 
if useSameVolume==false 
    c.V=Vglobal(time,1);
    data.V=Vglobal(time,1); 
else 
    c.V=c.V; 
    data.V=c.V; 
end 
%Solving the global optimization problem: 
[globalUsed(:,time),globalU(:,time)] = mpcRunV2(data,zeros(c.Nu*c.Nc),scaledCostfunction); 


%Determingng the cost of the global controller 
costGlobal(:,time)=costFunction(globalU(:,time),c,scaledCostfunction);


%Determine the next volume for the global controller and the eletricity
%bill for utilizing the given input
Vglobal(time+1,1)=Model(c.V,globalU(:,time),consumptionActual(time,1));

%% Consensus problem

% Updating inital geuss for consensus ADMM based on the solution from the
% previous, first time it is set to zero. Lambda is set to zero each time 

x(:,1)=[x(c.Nu+1:end,1);x(end-c.Nu+1:end,1)]; 
x(:,2)=[x(c.Nu+1:end,2);x(end-c.Nu+1:end,2)]; 
x(:,3)=[x(c.Nu+1:end,3);x(end-c.Nu+1:end,3)];
z=[z(c.Nu+1:end,1);z(end-c.Nu+1:end,1)];

lambda = zeros(c.Nc*c.Nu,c.Nu+1); 

%Setting the water volume for the consensus optimization problem  based on
%if they should 
if useSameVolume == false 
    c.V=Vconsensus(time,1);
else
    c.V=c.V; 
end 




%% Running the for loop for the iteration of the consensus ADMM  
%setting iterations count to one: 
k=1; 
%Setting stopping criteria to false 
stopCriterion = false; 

startXnorm=stopCriterionStart-1; 
while ~stopCriterion && k < maxIterations
    if time > 1 && k==1 
        c.rho=saveRho(end,time-1); 
    end 
    %Each agent solver their own optimization problem: 
    parfor(i=1:c.Nu+1)
        x(:,i) = u_consensus_fmincon(lambda(:,i),z(:,k),c,i,x(:,i),scaledCostfunction);
    end

    %Updating z/updating consensus parameter 
    z_tilde(:,k) = sum(x,2)/(c.Nu+1) + 1/(c.rho*(c.Nu+1))*sum(lambda,2);
    if underrelaxation==true 
        z(:,k+1) = z(:,k) - 1/(c.Nu+1+1)*(z(:,k)-z_tilde(:,k));
    else
        z(:,k+1) =  z_tilde(:,k); 
    end 
    zTildeSave(:,:,k,time)=z(:,k+1); 
    %Updating lambda
    for i=1:c.Nu+1
        lambda_tilde(:,i) = lambda(:,i) + c.rho*(x(:,i)-z(:,k+1));
    end
    lambdaTildeSave(:,:,k,time)=lambda_tilde;

    %Making underrelaxation if it is desired (only walking a little bit and not all the
    %way!) 
    if underrelaxation==true 
        lambda = lambda - 1/(c.Nu+1+1)*(lambda - lambda_tilde);
    else
        lambda= lambda_tilde;
    end 
    lambdaSave(:,:,k,time)=lambda; 
    zSave(:,:,k,time)=z(:,k+1);
    
    % Picking out the values from the solution which will be used, at each 
    % pump station. These values are used to determine cost and comparing:
    index=1;
     for i=1:c.Nu*c.Nc
         inputUsed(i,time)=x(i,index);
         index=index+1;
         if index==c.Nu+1  
             index=1; 
         end 
     end 


    %Determine cost of the cost function for the consensus controller 
    costConsensus(k,time)=costFunction(inputUsed(:,time),c,scaledCostfunction);


    %Determing the cost difference between consensus and global 
    costDifference(k,time)=costConsensus(k,time)-costGlobal(:,time); 

    %Varying rho if desired: 
    if varying_rho==true && k< c.varying_rho_iterations_numbers
        r=0;
        s=0; 
        %Determine the mean value of x/mass flos 
        xBar(:,k)=sum(x,2)/(c.Nu+1); 

        %determine the primal residual 
        for index=1:c.Nu+1 
            r=norm(x(:,index)-xBar(:,k))^2+r; 
        end 
        
        r=sqrt(r);
        %determine the dual residual 
        if k==1
            s=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k))^2);
        else
            s=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k)-xBar(:,k-1))^2);
        end 
        %Updating rho if neccesary
         if r >mu*s 
            c.rho=tauIncr*c.rho; 
         elseif s>mu*r 
             c.rho=c.rho/tauDecr; 
         end 
         %Saving the used penalty paramter
         saveRho(k,time)=c.rho;
    end 
        
    %% Stopping criterion: 
    if k== startXnorm 
        %Determine the mean value of x/mass flos 
        xBar(:,k)=sum(x,2)/(c.Nu+1);
        startXnorm=startXnorm+betweenStop;
    end 

    if k >= stopCriterionStart && mod(k - stopCriterionStart, betweenStop) == 0
        r=0; 
        s=0;
        xBar(:,k)=sum(x,2)/(c.Nu+1);
        s(k,time)=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k)-xBar(:,k-1))^2);
        r(k,time)=norm(x(:,1)-xBar(:,k))^2+norm(x(:,2)-xBar(:,k))^2+norm(x(:,3)-xBar(:,k))^2;
        r(k,time)=sqrt(r(k,time));
        
        xNorm(k,time)=norm(x(:,1))+norm(x(:,2))+norm(x(:,3));
        lambdaNorm(k,time)=norm(lambda(:,1))+norm(lambda(:,2))+norm(lambda(:,3)); 
       
        epsilonPri(k,time)=c.epsilonAbs+c.epsilonRel*max(xNorm(k,time),(c.Nu+1)*norm(z)); 
        
        epsilonDual(k,time)=c.epsilonAbs+c.epsilonRel*lambdaNorm(k,time);

        if  r(k,time)<=epsilonPri(k,time) && s(k,time)<=epsilonDual(k,time) 
            stopCriterion=true; 
        end 

    end

    k=k+1;
    if k==30 
        c.rho=saveRho(end,time)*500;
    end 

    %Printing how far we got! 
    k
    time 
    Xsave(:,:,k,time)=x; 

end 


%Saving the entire X for latter analyzes. 

%Resseting part which varys rho; 
clear xBar

%Prinitng on the go the procent wise difference in cost functions
for i=1:size(costGlobal,2)
    for k=1:size(costDifference,1)
    procentDifference(k,i)=costDifference(k,i).*inv(costGlobal(1,i)).*100;
    end 
end 

FrontSize=16;
plot(procentDifference)
xlabel("Iterations",'FontSize',FrontSize)
ylabel("Procentwise difference in cost functions",'FontSize',FrontSize)
grid 
ylim([-2 2])
drawnow
end 
%%
 %Determing the time it took: 
toc 

%% Plotting  procentwise difference between the global cost value and the consensus cost value 
%Determine procentwise difference between the global and consensus cost 
for i=1:size(costGlobal,2)-1
    for k=1:size(costDifference,1)
    procentDifference(k,i)=costDifference(k,i).*inv(costGlobal(1,i)).*100;
    end 
end 
%Making the plot 
f=figure
ax=axes; 

hold on 
plot(procentDifference)
hold off 
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'


xlabel("Iterations")
ylabel("Performance")
fontname(f,'Times')
set(gca,'fontname','times')

ylim([-20 20])
set(gca,'fontname','times')

%Making a smaller box to another plot 
axes('Position', [.5 .57 .3 .3])
box on 
hold on 
plot(procentDifference)
hold off 
ytickformat('%g%%');
xlim([50 200]) 
ylim([-0.05 0.2])
grid 




%exportgraphics(f,'Plots/percentage_diff_1000_hr_varying_rho_first_10_el_scaled_K=900_changing_rho_end_the_end.pdf')
%% Making a zoomed in version of the procentwise differencing between the global cost value and the consensus cost value
f=figure
hold on 
plot(procentDifference(:,1),'LineWidth',3)
plot(procentDifference(:,2:end))
hold off 
legend('First Hour','Rest')

xlabel("Iterations",'FontSize',FrontSize)
ylabel("Procentwise difference in cost functions",'FontSize',FrontSize)
grid 
set(gca,'fontname','times')
yline(0,'HandleVisibility','off');
xlim([280 300])
%exportgraphics(f,'Plots/percentage_diff_24_hr_varying_rho_K=900_el_scaled_Jv_with_water_tower_zoomed.pdf')

%% Plotting the rho value at the 10 iterations: 
f=figure
ax=axes; 
stairs(saveRho(end,:))
xlabel('Hour [h_a]')
ylabel('$\rho$ value', 'Interpreter', 'latex')
box off 
grid on 
ylim([1 3])

set(gca,'fontname','times')

%exportgraphics(gcf,'Plots/rho_value_10_iterations.pdf','ContentType','image')

%% Determining the average disargement from consensus 
clear meanDiffFromConsensus 
clear DiffFromConsensus
for time=1:size(Xsave,4)
    for k=1:size(Xsave,3) 
        for entire=1:size(Xsave,1)
            DiffFromConsensus(k,time)=abs(Xsave(entire,1,k,time)-Xsave(entire,2,k,time))+abs(Xsave(entire,1,k,time)-Xsave(entire,3,k,time))+abs(Xsave(entire,2,k,time)-Xsave(entire,3,k,time));
            %DiffFromConsensus(k,time)=max(max(abs(Xsave(entire,1,k,time)-Xsave(entire,2,k,time)),abs(Xsave(entire,1,k,time)-Xsave(entire,3,k,time))),abs(Xsave(entire,2,k,time)-Xsave(entire,3,k,time)));
            % if mod(entire, 2) == 1
            %     %The number is odd use first entire 
            %     %DiffFromConsensus(entire,k,time)=abs(Xsave(entire,1,k,time)-Xsave(entire,2,k,time))+abs(Xsave(entire,1,k,time)-Xsave(entire,3,k,time));
            %     DiffFromConsensus(entire,k,time)=(Xsave(entire,1,k,time)-Xsave(entire,3,k,time));
            % else
            %     %The number is not odd use second entire
            %     %DiffFromConsensus(entire,k,time)=abs(Xsave(entire,2,k,time)-Xsave(entire,1,k,time))+abs(Xsave(entire,2,k,time)-Xsave(entire,3,k,time));
            %     DiffFromConsensus(entire,k,time)=(Xsave(entire,2,k,time)-Xsave(entire,1,k,time));
            % end
        end 
        meanDiffFromConsensus(k,time)=sum(DiffFromConsensus(k,time))/((c.Nu+1)*c.Nc*3); 
        %meanDiffFromConsensus(k,time)=sum(DiffFromConsensus(:,k,time))*600/3600*1000;

    end 
    time
end 

%% Making a plot on the average disargment from consensus 
f=figure
plot(meanDiffFromConsensus) 
xlabel('Iterations')
ylabel('$\Delta \mathbf{x}''$ [m$^3$/h]', 'Interpreter', 'latex');
grid 
box off 
set(gca,'fontname','times')
axes('Position', [.3 .3 .55 .55])
box on 
hold on 
plot(meanDiffFromConsensus)
hold off 
xlim([100 200])
grid 
%exportgraphics(f,'Plots/Mean_abs_diff_from_consensus.pdf','ContentType','image')

%exportgraphics(gcf,'Plots/Mean_abs_diff_from_consensus.pdf', 'ContentType', 'vector')
%% Plotting the Volume for each of the stakeholders 
time=1; 
iterationsNumber=120; 

[consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
%Moving the predicted consumption to a struct for each use to functions
c.d=consumptionPred;

%Determing the volume for each, of the 3 stakeholders 
c.V=0.0560; 

Vx1=ModelPredicted(c.V,Xsave(:,1,iterationsNumber,time),c.d);
Vx2=ModelPredicted(c.V,Xsave(:,2,iterationsNumber,time),c.d);
Vx3=ModelPredicted(c.V,Xsave(:,3,iterationsNumber,time),c.d);

f=figure 
hold on 
    plot(Vx1)
    plot(Vx2)
    plot(Vx3)
    yline(c.Vmin)
    yline(c.Vmax)
hold off
grid 
legend('Pump 1','Pump 2','Water Tower','Constraints') 
ylabel('Water volume [m^{3}]') 
xlabel('Hours [h_a]')
set(gca,'fontname','times')

%exportgraphics(f,'Plots/Prediction_each_stakeholder_changing_rho_end_the_end.pdf','ContentType','image') 

