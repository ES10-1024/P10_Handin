%% Setting up the optimization problem and solving it.
function [up1,uAll] = mpcRun(data,uPrev)
% The inputs is:
% Standard constant, which also have the current water volume, and demand
c=scaled_standard_constants; 

c.d=data.d(:,:,end); 
c.Je=data.Je(:,end); 
c.V=data.V(end,1); 


%% Defining optimization variable

%Setting up the optimziation problem 
problem = optimproblem;
u = optimvar('u',c.Nc*c.Nu);
%% Making A and v matrices for the constraints
%A_1 each row have 3 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix to add consumption and inflow 
c.A_2 = tril(ones(c.Nc,c.Nc));

%Making vi vectors utilized to pick out 1 of the 3 pumps values, add them up
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
%% Constraints
%Upper and lower limit for the water tower
problem.Constraints.towerU = ones(c.Nc,1)*c.V + c.A_2*((c.A_1*u)-c.d) <= c.Vmax;    
problem.Constraints.towerL = ones(c.Nc,1)*c.V + c.A_2*((c.A_1*u)-c.d) >= c.Vmin;

%Extration litmit for each pump
problem.Constraints.extract1 = c.v1'*u <= c.TdMax1;
problem.Constraints.extract2 = c.v2'*u <= c.TdMax2;

%Max and minimum flow for each pump 
problem.Constraints.pump1U = c.A_31*u <= c.umax1;
problem.Constraints.pump2U = c.A_32*u <= c.umax2;
problem.Constraints.pump1L = c.A_31*u >=0;
problem.Constraints.pump2L = c.A_32*u >=0;
%% Cost function
%Water level plus at bit extra to make it nice and short
h=c.g0*c.rhoW*1/c.At*(c.A_2*(c.A_1*u-c.d)+c.V);

%Defining cost function for each of the pumps  
% J1 = ones(1,c.Nc)*(c.e1*c.Je/1000.*(c.A_31*(u.*u.*u./3600^3*c.rf1 + u/3600*c.g0*c.rhoW*c.z1) + (c.A_31*u/3600).*h+c.A_31*u/3600.*(c.rfTogether*(c.A_1*u/3600).*(c.A_1*u/3600))));
% J2 = ones(1,c.Nc)*(c.e2*c.Je/1000.*(c.A_32*(u.*u.*u./3600^3*c.rf2 + u/3600*c.g0*c.rhoW*c.z2) + (c.A_32*u/3600).*h+c.A_32*u/3600.*(c.rfTogether*(c.A_1*u/3600).*(c.A_1*u/3600))));
     J1 = ones(1,c.Nc)*(c.e1*c.Je.*(c.A_31*(u.*u.*u.*(c.rf1/1000) + u*c.g0*c.rhoW*(c.z1/1000)) + (c.A_31*u).*(h/1000)+c.A_31*u.*((c.rfTogether/1000)*(c.A_1*u-c.d).*(c.A_1*u-c.d))));
     J2 = ones(1,c.Nc)*(c.e2*c.Je.*(c.A_32*(u.*u.*u.*(c.rf2/1000) + u*c.g0*c.rhoW*(c.z2/1000)) + (c.A_32*u).*(h/1000)+c.A_32*u.*((c.rfTogether/1000)*(c.A_1*u-c.d).*(c.A_1*u-c.d))));
   
%Defining that start and end volumen has to be the same 
Js=c.K*(ones(1,c.Nc)*(c.A_1*u-c.d))^2;

%Collecting the entire objective function
problem.Objective = J1+J2+Js;

%Inital condition
x0.u =[uPrev(2:end,1);uPrev(end,end)]; 

%Solving problem and making plots: 
solution = solve(problem,x0);

%Setting output from the function
up1=solution.u(1:c.Nu); 
uAll=solution.u;

end
