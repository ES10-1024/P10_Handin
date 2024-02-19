%% Setting up the optimization problem and solving it.
function [up1,uAll] = mpcRun(V,d,currentTime,currentConsumption, Je,u)
% The inputs is: 
% V water volumen  
% d vector of consumpotion in the prediction/control horizion 
% currentTime The current time in s 0s=midnight 
% currentConsumption amount pumped total during the day for pumps in vector with pump 1 first  
% Je eletrict price currently in the time steps made for the prediction horizion  
% u current input

%% Defining constant values
%Loading in standard constants 
c=standardConstants; 

%% Defining optimization variable

% Initialize problem
Problem = optimproblem();

%Making optimziation variables as matrix each columen is a different pump 
U = optimvar('U',c.Nc, c.Nu);

%% Implemtering constraints for max and minimum pump mass flow

% Making each pumps input to be larger than zero 
Problem.Constraints.Pump1Low=c.umin1<=U(:,1); 
Problem.Constraints.Pump2Low=c.umin2<=U(:,2);
Problem.Constraints.Pump3Low=c.umin3<=U(:,3);


% Setting upper limit for the two pumps 
Problem.Constraints.Pump1Upper=U(:,1)<=c.umax1; 
Problem.Constraints.Pump2Upper=U(:,2)<=c.umax2;
Problem.Constraints.Pump3Upper=U(:,3)<=c.umax3;

%% Implemeting limitations for height in water tower
% Making As 
As=c.ts*tril(ones(c.Nc,c.Nc));


%Implemting lower limations 
Problem.Constraints.WaterLevelLow=c.At*c.hmin<=V+(As*(U*ones(c.Nu,1)-d)); 

%Implemting upper limtations
Problem.Constraints.WaterLevelUpper=V+(As*(U*ones(c.Nu,1)-d))<=c.hmax*c.At; 

%% Implemting the total daliy extraction Limith

%Function which returns q, with the given time of day 
q=DayLimtPumps(currentTime);

%Multipling q with the sample time to go from m^3/s to m^3 
q=q*c.ts; 

%Make such that the currentConsumption is only added to the first row! 
currentConsumption1Temp=[currentConsumption(1,1);zeros(size(q,1)-1,1)]; 
currentConsumption2Temp=[currentConsumption(2,1);zeros(size(q,1)-1,1)]; 
currentConsumption3Temp=[currentConsumption(3,1);zeros(size(q,1)-1,1)]; 



%Making the lower constraint
Problem.Constraints.ConsumptionLower1=c.TdMin1<=q*U(:,1)+currentConsumption1Temp; 
Problem.Constraints.ConsumptionLower2=c.TdMin2<=q*U(:,2)+currentConsumption2Temp;
Problem.Constraints.ConsumptionLower3=c.TdMin3<=q*U(:,3)+currentConsumption3Temp; 


%Making the upper constraint 
Problem.Constraints.ConsumptionUpper1=q*U(:,1)+currentConsumption1Temp<=c.TdMax1; 
Problem.Constraints.ConsumptionUpper2=q*U(:,2)+currentConsumption2Temp<=c.TdMax2; 
Problem.Constraints.ConsumptionUpper3=q*U(:,3)+currentConsumption3Temp<=c.TdMax3; 


%% Defining the part of cost function which ensures start and stop levels are the same!

%Start by defining the term which the norm is taken to 
ToTakeNorm=ones(1,c.Nc)*(U*ones(c.Nu,1)-d); 

%Defining the cost term
Js=c.K*norm(ToTakeNorm)^2; 
%% Defining cost term which include the eletricty price! This one should be updated it is not that pretty to use to for loops! 
    %Making for loop to determine the sum, first determine the power used of the 
    % pumps and when determine the cost 
Jp1=0; 
for index=1:c.Nc 
    P1(index,1)=c.e1*U(index,1)*(c.rf1*U(index,1)*U(index,1)+c.rho*c.g*c.z1-c.p10); 
    Jp1=Jp1+1/(3600*1000)*Je(index,1)*c.ts*P1(index,1); 
end 


Jp2=0; 
for index=1:c.Nc 
    P2(index,1)=c.e2*U(index,2)*(c.rf2*U(index,2)*U(index,2)+c.rho*c.g*c.z2-c.p20); 
    Jp2=Jp2+1/(3600*1000)*Je(index,1)*c.ts*P2(index,1); 
end 

Jp3=0; 
for index=1:c.Nc 
    P3(index,1)=c.e3*U(index,3)*(c.rf3*U(index,3)*U(index,3)+c.rho*c.g*c.z3-c.p30); 
    Jp3=Jp3+1/(3600*1000)*Je(index,1)*c.ts*P3(index,1); 
end
%% Defining the cost and solving the problem
J=0; 
J=c.Kp*(Jp1+Jp2+Jp3)+Js;
Problem.Objective=J; 
init = struct;
init.U = [ones(c.Nc,1)*u(1,1), ones(c.Nc,1)*u(2,1),ones(c.Nc,1)*u(3,1)];
solution = solve(Problem,init);

up1=solution.U(1,:)'; 
uAll=solution.U;


end
