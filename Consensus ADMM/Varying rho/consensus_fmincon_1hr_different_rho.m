%% Script to determine the rho value needed for ADMM consensus, 
%% Making a bit of cleaning  
clear 
clc 
clf

close all
%% Loading in scaled standard Constants and addning a path.   
addpath("..\..\Global controller\Simple Simulink implemtation\Functions\") 
addpath("..\Functions\")
addpath("..\..\")

addpath("Plots\")

c=scaled_standard_constants; 

%% getting the  one hour of eletricity price and demand data
%Select the hour which is desired to work with 
hour=1;  

%Determining the time in physical seconds 
currentTime=hour*c.ts;

%If the electricty price should be scaled such it 2-norm is one 
scaledEletricityPrice=true;


%Getting the electricty price and consumption data
[c.Je] = ElectrictyPrices(currentTime); 
[consumptionPred,consumptionActual] = consumption(currentTime);
%Moving the predicted data to a struct for easier use with functions 
c.d=consumptionPred;

%Scaling the electricty price such the 2-norm is one if it is desired: 
if scaledEletricityPrice==true 
c.Je=c.Je/norm(c.Je); 
end 

%% If the cost function should be scaled: 
scaledCostFunction=true; 


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

%% Running the Global problem to compare with consensus problem

%Setting up the data such it can be used by the function for solving the global optimization problem: 
data.d(:,:,1)=c.d; 
data.Je(:,1)=c.Je; 
data.V=c.V; 

%Solving the global optimization problem: 
[up1,uAll] = mpcRunV2(data,zeros(c.Nu*c.Nc),scaledCostFunction); 


%Determining the global cost: 
costGlobal=costFunction(uAll,c,scaledCostFunction);

%% Consensus problem

%Defining the penalty parameter rho, which is desired to look at 
rho_v=[1 2 3 4 5];
 
%if a varying rho should be utilized: 
varying_rho=false; 
%Values for varying rho 
mu=10; 
tauIncr=2; 
tauDecr=2; 

% Defining if the water tower should be used in the consensus problem 
useWaterTower=true;

% Defining if underrelaxation should be utilized 
underrelaxation=false; 

%setting the number of agents based on if the water tower is utilized: 
if useWaterTower == true 
    Nu=c.Nu+1;
else 
    Nu=c.Nu; 
end 
%Predifing a matrix which saves the used input for the consensus ADMM
%controller. 
UsedInput=zeros(c.Nc*c.Nu,size(rho_v,2)); 

%% Making a for loop to go though each of the penalty parameter 
tic
for j=1:size(rho_v,2) 

%Setting inital values 
z=zeros(c.Nc*c.Nu,1); 
lambda = zeros(c.Nc*c.Nu,Nu); 
x = zeros(c.Nc*c.Nu,Nu);
xBar=0;

%Picking the penalty parameter to be used 
c.rho = rho_v(j);

%Going thoung iterations for one consensus ADMM problem 
for k=1:300 
  %Solving each of the distrubted optimization problems 
   parfor(i=1:Nu)
        x(:,i) = u_consensus_fmincon(lambda(:,i),z(:,k),c,i,x(:,i),scaledCostFunction);
    end
    
    %Updating z tilde . 
    z_tilde = sum(x,2)/(Nu) + 1/(c.rho*Nu)*sum(lambda,2);

    %Updating lambda tilde.  
    for i=1:Nu
        lambda_tilde(:,i) = lambda(:,i) + c.rho*(x(:,i)-z(:,k));
    end

   %Making underrelaxation if  (only walking a little bit and not all the
    %way!) 
    if underrelaxation==true 
        z(:,k+1) = z(:,k) - 1/(Nu+1)*(z(:,k)-z_tilde);
        lambda = lambda - 1/(Nu+1)*(lambda - lambda_tilde);
    else
        z(:,k+1) =  z_tilde; 
        lambda= lambda_tilde;
    end 
    
    % Picking out the values from the solution which will be used to set
    % massf low on the pumps
    index=1;
     for i=1:c.Nu*c.Nc
         UsedInput(i,j)=x(i,index);
         index=index+1;
         if index==Nu
             index=1; 
         end 
     end 

    %Determine cost of the cost function for the consensus ADMM controller
    costConsensus(k,j)=costFunction(UsedInput(:,j),c,scaledCostFunction);

    %Determing the cost difference between distrubted and global 
    costDifference(k,j)=costConsensus(k,j)-costGlobal; 
    
    %Varying rho if desired: 
    if varying_rho==true
        r=0;
        s=0; 
        %Determine the mean value of x/mass flos 
        xBar(:,k)=sum(x,2)/(Nu); 

        %determine the primal residual 
        for index=1:Nu 
            r=norm(x(:,index)-xBar(:,k))+r; 
        end 
        
        %determine the dual residual 
        if k==1
            s=sqrt(Nu*c.rho^2*norm(xBar(:,k))^2);
        else
            s=sqrt(Nu*c.rho^2*norm(xBar(:,k)-xBar(:,k-1))^2);
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
    %Printing how far we got! 
    k
    j
end
end 
%%
 %Determing time it took: 
toc 

%% Plotting difference between the global cost value and the consensus cost value 
FrontSize=24;
for i=1:size(costDifference,2)
    for k=1:size(costDifference,1)
    procentDifference(k,i)=costDifference(k,i).*inv(costGlobal).*100;
    end 
end 

f=figure
ax=axes; 
hold on 
plot(procentDifference)
yline(0)
hold off 
ytickformat(ax, 'percentage');
ax.YGrid = 'on'
%ytickformat(ax, '%g%%');
ax.XGrid = 'on'

xlabel('Iterations','FontSize',FrontSize)
ylabel('$P_\mathrm{ADMM}$','Interpreter','latex','FontSize',FrontSize)
fontname(f,'Times')
legend('\rho=1','\rho=2','\rho=3','\rho=4','\rho=5')

set(gca,'fontname','times')
ylim([-2 5])

% Making a zoomed in version of the differencing between the global cost value and the consensus cost value

% axes('Position', [.35 .5 .4 .4])
% ax=axes; 
% ytickformat(ax, 'percentage');
% ax.YGrid = 'on'
% 
% box on 
% plot(procentDifference)
% 
% xlim([250 300])
% ylim([-1 1])

% yline(0)
fontname(f,'Times')

set(gca,'fontname','times')

exportgraphics(f,'Plots/rho=1_to_5_hour_1_kappa=900.pdf')



