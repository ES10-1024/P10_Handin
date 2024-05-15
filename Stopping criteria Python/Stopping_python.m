
%% A bit of spring cleaning! 
clear 
clf 
close all 
clc 
%% Loading in the needed data
load("global_controller.mat"); 
clear filename 
distrubtedCon=load("consensusADMM_controller_new_new_new.mat");
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
for time=1:200:3*200%size(distrubtedCon.ADMM_1.x_i,2)
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
c.epsilonAbs=0.1;



c.epsilonRel=1*10^(-3);

clear stopCriterion
clear first_occurrence_row
for time=1:200:3*200%size(distrubtedCon.ADMM_1.x_i,2)
   for k=1:200 
        xBar(:,k,time1)=1/(c.Nu+1)*(distrubtedCon.ADMM_1.x_i(:,time+k-1)+distrubtedCon.ADMM_2.x_i(:,time+k-1)+distrubtedCon.ADMM_3.x_i(:,time+k-1));
        if k>=2% stopCriterionStart && mod(k - stopCriterionStart, betweenStop) == 0
                s(k,time1)=sqrt((c.Nu+1)*c.rho^2*norm(xBar(:,k)-xBar(:,k-1))^2);

                r(k,time1)=sqrt(norm(distrubtedCon.ADMM_1.x_i(:,time+k-1)-xBar(:,k))^2+norm(distrubtedCon.ADMM_2.x_i(:,time+k-1)-xBar(:,k))^2+norm(distrubtedCon.ADMM_3.x_i(:,time+k-1)-xBar(:,k))^2);        
                 rr(k,time1)=1;
                
                xNorm(k,time1)=norm(distrubtedCon.ADMM_1.x_i(:,time+k-1))+norm(distrubtedCon.ADMM_2.x_i(:,time+k-1))+norm(distrubtedCon.ADMM_3.x_i(:,time+k-1));
                lambdaNorm(k,time1)=norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1))+norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1))+norm(distrubtedCon.ADMM_1.lambda_i(:,time+k-1)); 
        
                epsilonPri(k,time1)=c.epsilonAbs+c.epsilonRel*max(xNorm(k,time1),(c.Nu+1)*norm(distrubtedCon.ADMM_1.z(:,time+k-1))); 
        
                epsilonDual(k,time1)=c.epsilonAbs+c.epsilonRel*lambdaNorm(k,time1);
        
                % if r(k,time1)<=epsilonPri(k,time1) && s(k,time1)<=epsilonDual(k,time1)
                %     stopCriterion(k,time1)=true; 
                %     k
                %     break 
                % end 
        end 
   end
   time1=time1+1
end 

% % Loop through each column
% for col = 1:size(stopCriterion, 2)
%     % Find the first non-zero element in the column
%     row = find(stopCriterion(:, col), 1, 'first');
%     if ~isempty(row)
%         first_occurrence_row(col) = row;
%     else
%         first_occurrence_row(col) = NaN; % If no non-zero element is found
%     end
% end
% f=figure
% stairs(first_occurrence_row)
% grid