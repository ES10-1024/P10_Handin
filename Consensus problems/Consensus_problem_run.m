%% Simple script to get standard on consenus problem starting, 
% with a simple problem which looks a bit like the one we are working with
%% 
clear 
clc 
clf
%% Loading in standard Constants and adding a few path to save values.  
c=standardConstants; 
addpath("Data\")
addpath("Functions\") 
addpath("Plots\")
%Getting in consumption and eletricity prices for the first 24 hours 
load('Elpriser.mat');
c.Je = ElPrices(:,1);

load('consumption.mat');
c.d = d(:,:,2);
%Removing the data that we do not needed
clear d ElPrices

%% Defining A and v matrices for the constraints
%A_1 each row have 3 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix to add consumption and inflow 
c.A_2 = tril(ones(c.Nc,c.Nc));


%Making v1 vectors ultized to pick out 1 of the 3 pumps values, add them up

c.v1=ones(c.Nu*c.Nc,1);
c.v1(2:3:end) =0; 
c.v1(3:3:end) =0;

c.v2=ones(c.Nu*c.Nc,1);
c.v2(1:3:end) =0;
c.v2(3:3:end) =0;

c.v3=ones(c.Nu*c.Nc,1);
c.v3(1:3:end) =0;
c.v3(2:3:end) =0;
%Making matrix which picks out 1 of the pumps for the enitre control
%horizion
c.A_31=[];
for i=1:c.Nc
    c.A_31 = blkdiag(c.A_31,[1 0 0]);
end

c.A_32=[];
for i=1:c.Nc
    c.A_32 = blkdiag(c.A_32,[0 1 0]);
end

c.A_33=[];
for i=1:c.Nc
    c.A_33 = blkdiag(c.A_33,[0 0 1]);
end
clear i

%% Global problem
%Setting up the optimziation problem 
problem = optimproblem;
u = optimvar('u',c.Nc*c.Nu);



%% Constraints
%Max and minimum flow for each pump 
problem.Constraints.pump1U = c.A_31*u <= c.umax1;
problem.Constraints.pump2U = c.A_32*u <= c.umax2;
problem.Constraints.pump3U = c.A_33*u <= c.umax3;
problem.Constraints.pump1L = c.A_31*u >=0;
problem.Constraints.pump2L = c.A_32*u >=0;
problem.Constraints.pump3L = c.A_33*u >=0;
%% Cost function
%Water level in water tower
h=c.g0*c.rhoW*1/c.At*(c.A_2*(c.A_1*u-c.d)+c.V);

%Defining cost function for each of the pumps 
J1 = ones(1,c.Nc)*(c.e1*c.Je/1000.*(c.A_31*(u.*u.*u./3600^3*c.rf1 + u/3600*c.g0*c.rhoW*c.z1) + (c.A_31*u/3600).*h));
J2 = ones(1,c.Nc)*(c.e2*c.Je/1000.*(c.A_32*(u.*u.*u./3600^3*c.rf2 + u/3600*c.g0*c.rhoW*c.z2) + (c.A_32*u/3600).*h));
J3 = ones(1,c.Nc)*(c.e3*c.Je/1000.*(c.A_33*(u.*u.*u./3600^3*c.rf3 + u/3600*c.g0*c.rhoW*c.z3) + (c.A_33*u/3600).*h));
%Start and end water amount should by the same 
Js=c.K*(ones(1,c.Nc)*(c.A_1*u-c.d))^2;

%Defining the entire cost function
problem.Objective = J1+J2+J3+Js;
%Inital condition for the solver
x0.u = zeros(c.Nc*c.Nu,1);  

%Solving problem 
solution = solve(problem,x0);
solution.u;
%Making a plot
clf
figure(1)
stairs([solution.u(1:3:end)'; solution.u(2:3:end)'; solution.u(3:3:end)']','LineWidth',3)

%% Consensus problem
%Setting value for rho, determinted with the help of for loops and alot of
%different tries
c.rho =0.1.^(3.1);



%Picking initial values
z=zeros(c.Nc*c.Nu,1)*1; 
lambda = zeros(c.Nc*c.Nu,c.Nu); 
x = zeros(c.Nc*c.Nu,c.Nu);



%%
for k=1:2000
    %Solving each of the consensus problems 
    parfor(i=1:3)
        x(:,i) = u_consensus(lambda(:,i),z(:,k),c,i);
    end
    
    %Updating z. 
    z_tilde = sum(x,2)/(c.Nu) + 1/(c.rho*c.Nu)*sum(lambda,2);

    %Updating lambda.  
    for i=1:3
        lambda_tilde(:,i) = lambda(:,i) + c.rho*(x(:,i)-z(:,k));
    end
    %updating z and lambda: 
    z(:,k+1) = z_tilde; 
    lambda=lambda_tilde;
    %Determing the convergence
    p(k) = norm(solution.u-x(:,1),"inf");
    %writing in command window how far we got. 
    k
   
  
end
   save('Data\error_consensus_simple_with_demand_6-3_4.mat','p')
%% Making a few figures 
%Convergence error full 
load('Data\error_consensus_simple_with_demand_6-3_4.mat')

f = figure
plot(p)
grid
xlabel("Iterations")
ylabel_text = sprintf("|| \\mathcal U^* -\\mathcal U||_\\infty"); 
ylabel(strcat("$", ylabel_text, "$"), 'Interpreter', 'latex');
set(gca,'fontname','times')
exportgraphics(f,'Plots/infity_norm_difference_2.pdf')
%% convergence error zoomed
f = figure
plot(p)
grid
xlabel("Iterations")
ylabel_text = sprintf("|| \\mathcal U^* -\\mathcal U||_\\infty"); 
ylabel(strcat("$", ylabel_text, "$"), 'Interpreter', 'latex');
set(gca,'fontname','times')
xlim([1900 2000])
exportgraphics(f,'Plots/infity_norm_difference_2_zoomed.pdf')

%% compariosion between global and local controller 
clf
f = figure
hold on 
stairs([x(1:3:end,1)'; x(2:3:end,2)'; x(3:3:end,3)']','LineWidth',3)
stairs([solution.u(1:3:end)'; solution.u(2:3:end)'; solution.u(3:3:end)']','LineWidth',3)
hold off 
grid 
xlabel('Time [h]')
ylabel('Pump mass flows [m^{3}/{s}]')
set(gca,'fontname','times')
legend('consensus','consensus','consensus','global','global','global')
exportgraphics(f,'Plots/comparision_2.pdf')

