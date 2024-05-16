
%% A bit of spring cleaning! 
clear 
clf 
close all 
clc 
%% Loading in the needed data
addpath("New data\")
load("short_new_sim_data_global.mat"); 
clear filename 
distrubtedCon=load("short_new_sim_data_ADMM.mat");

clc 
clf
close all 
%% adding a few paths, and loading in scaled standard constants  
addpath('C:\Users\is123\Downloads')
addpath('..\')
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Consensus ADMM\Functions\")
c=scaled_standard_constants; 

%% Determining the performance 
scaledCostfunction=true;

time1=1;
for time=1:200:size(distrubtedCon.ADMM_1.x_i,2)-200
        % Solving the Global optimization problem
        %Setting up the data such it can be used by the function: 
        data.d(:,:,1) = distrubtedCon.pump1.electricity_price(:,time1); 
        data.Je(:,1) = distrubtedCon.pump1.demand_pred(:,time1); 
        data.V=200/1000*c.At;  
        %Solving the global optimization problem: 
        c.d = distrubtedCon.pump1.electricity_price(:,time1);
        c.Je = distrubtedCon.pump1.demand_pred(:,time1); 
        c.V = 200/1000*c.At; 
        globalU(:,time1)=globalCon.Solution(:,time1);
        %Determinging the cost of the global controller 
        costGlobal(:,time1) = costFunction(globalU(:,time1),c,scaledCostfunction);
       for k=1:200
            % Determing cost consensus ADMM 
            for index=1:48 
                if mod(index,2)==0 
                    %even number
                    mathcalU(index,1) = distrubtedCon.ADMM_2.x_i(index,time+k-1); 
                else 
                    %odd number 
                    mathcalU(index,1) = distrubtedCon.ADMM_3.x_i(index,time+k-1);
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
ax=axes
plot(procentDifference)
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
ax.XGrid='on'
xlabel("Iterations")
ylabel("Performance")
fontname(f,'Times')
set(gca,'fontname','times')


%% 
stopCriterionStart=35; 
betweenStop=5; 
time1=1;
c.epsilonAbs=0.05 % 0.0005%1*10^(0); %skrue lidt op for denne for at det stoppe tidligere! 



c.epsilonRel=0.3*10^(0) % 1*10^(-4);

clear stopCriterion
clear first_occurrence_row
for time=1:200:size(distrubtedCon.ADMM_1.x_i,2)-200
   for k=1:200 
        xBar(:,k,time1)=1/(c.Nu+1)*(distrubtedCon.ADMM_1.x_i(:,time+k-1)+distrubtedCon.ADMM_2.x_i(:,time+k-1)+distrubtedCon.ADMM_3.x_i(:,time+k-1));
        if k==1 
            s(k,time1)=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k,time1))^2);
        else 
            s(k,time1)=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k,time1)-xBar(:,k-1,time1))^2);
        end 
        r(k,time1)=sqrt(norm(distrubtedCon.ADMM_1.x_i(:,time+k-1)-xBar(:,k,time1))^2+norm(distrubtedCon.ADMM_2.x_i(:,time+k-1)-xBar(:,k,time1))^2+norm(distrubtedCon.ADMM_3.x_i(:,time+k-1)-xBar(:,k,time1))^2);        
        if k>=stopCriterionStart-5 && mod(k - stopCriterionStart, betweenStop) == 0
                c.rho=0.67*10000; %IKKE LAVET RIGTIGT!
                s(k,time1)=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k,time1)-xBar(:,k-1,time1))^2);

                r(k,time1)=sqrt(norm(distrubtedCon.ADMM_1.x_i(:,time+k-1)-xBar(:,k,time1))^2+norm(distrubtedCon.ADMM_2.x_i(:,time+k-1)-xBar(:,k,time1))^2+norm(distrubtedCon.ADMM_3.x_i(:,time+k-1)-xBar(:,k,time1))^2);        
                
                xNorm(k,time1)=norm(distrubtedCon.ADMM_1.x_i(:,time+k-1))+norm(distrubtedCon.ADMM_2.x_i(:,time+k-1))+norm(distrubtedCon.ADMM_3.x_i(:,time+k-1));
                lambdaNorm(k,time1)=norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1))+norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1))+norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1)); 
        
                epsilonPri(k,time1)=c.epsilonAbs+c.epsilonRel*max(xNorm(k,time1),(c.Nu+1)*norm(distrubtedCon.ADMM_1.z(:,time+k-1))); 
                epsilonPriSecondTerm(k,time1)=c.epsilonRel*max(xNorm(k,time1),(c.Nu+1)*norm(distrubtedCon.ADMM_1.z(:,time+k-1)));
        
                epsilonDual(k,time1)=c.epsilonAbs+c.epsilonRel*lambdaNorm(k,time1);
                epsilonDualSecondTerm(k,time1)=c.epsilonRel*lambdaNorm(k,time1);
        
                if r(k,time1)<=epsilonPri(k,time1) && s(k,time1)<=epsilonDual(k,time1)
                    stopCriterion(k,time1)=true; 
                    k
                     
                end 
        end 
   end
   time1=time1+1
end 
% Loop through each column
for col = 1:size(stopCriterion, 2)
    % Find the first non-zero element in the column
    row = find(stopCriterion(:, col), 1, 'first');
    if ~isempty(row)
        first_occurrence_row(col) = row;
    else
        first_occurrence_row(col) = NaN; % If no non-zero element is found
    end
end
f=figure
stairs(first_occurrence_row)
grid
first_occurrence_row
%% 
first_occurrence_row=[200,200,200]
%procentDifferenceShort=zeros(size(procentDifference));
for index=1:size(procentDifference,2) 
    procentDifferenceShort(:,index)=[procentDifference(1:first_occurrence_row(index),index);zeros(200-first_occurrence_row(index),1)];
    epsilonPriEndValue(:,index)=epsilonPri(first_occurrence_row(index),index);
    epsilonDualEndValue(:,index)=epsilonDual(first_occurrence_row(index),index);
    x1used(:,index) = distrubtedCon.ADMM_1.x_i(:,first_occurrence_row(index)+(index-1)*200);
    x2used(:,index) = distrubtedCon.ADMM_2.x_i(:,first_occurrence_row(index)+(index-1)*200); 
    x3used(:,index) = distrubtedCon.ADMM_3.x_i(:,first_occurrence_row(index)+(index-1)*200);
end 
mean(epsilonPriEndValue)
mean(epsilonDualEndValue)
%% 
f=figure
ax=axes
plot(procentDifferenceShort)
yline(0,'HandleVisibility','off');
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
ax.XGrid='on'
xlabel("Iterations")
ylabel("Performance")
fontname(f,'Times')
set(gca,'fontname','times')
%%  Checking for consensus! 

for time=1:size(procentDifference,2)
        [consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
        %Moving the predicted consumption to a struct for each use to functions
        c.d=consumptionPred;
        
        %Determing the volume for each, of the 3 stakeholders 
        c.V=200/1000*c.At; 
        
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
plot(maxDiff(end,:))
%% 
time=3; %time=757; 


[consumptionPred,consumptionActual(time,:)] = consumption(time*c.ts);
%Moving the predicted consumption to a struct for each use to functions
c.d=consumptionPred;

%Determing the volume for each, of the 3 stakeholders 
c.V=200/1000*c.At; 


Vx1=ModelPredicted(c.V,x1used(:,time),c.d);
Vx2=ModelPredicted(c.V,x2used(:,time),c.d);
Vx3=ModelPredicted(c.V,x3used(:,time),c.d);

f=figure 
hold on 
    plot(Vx1)
    plot(Vx2)
    plot(Vx3)
    yline(c.Vmin)
    yline(c.Vmax)
hold off
grid 
legend('Water Tower','Pump 1','Pump 2','Constraints') 
ylabel('Water volume [m^{3}]') 
xlabel('Hours [h_a]')
set(gca,'fontname','times')


