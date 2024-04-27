%% Setting up the optimization problem and solving it.
function [up1,uAll] = mpcRunV2Casadi(data,uPrev,scaled)
% The inputs is:
%A struct Data which haves the demand data, electricity price, and current
%volume in the water tower 
% The previous prediction of inputs uPrev (The entire control  horizon
% from the last should be in this 
% scaled, if true the optimization problem is caled 

%The output is: 
%up1, the input which should be set on the pumps 
%uAll, all mass flow in the entire control horizon 
%% loading in scaled_standard_constants, and moving the data a bit around to 
% make it easier. 
c=scaled_standard_constants; 

c.d=data.d(:,:,end); 
c.Je=data.Je(:,end); 
c.V=data.V(end,1); 

% Defining the total number of varaibles which has to be determinted
total=c.Nc*c.Nu;

% Need a few empty matrix to allow for the change in option for the solver
%% Setting up the optimization problem: 
import casadi.* 
opti=casadi.Opti(); 
%Definining optimiztion varaible: 
u=opti.variable(total,1);


%% Making A and v matrices for the constraints

%A_1 each row have 2 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end

% A_2 Lower trangiular matrix  to make a integral  
c.A_2 = tril(ones(c.Nc,c.Nc));

%Making vi vectors utilized to pick out 1 of the 2  pumps values, add them up
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

%% Setting up the constraints on the form Ax<=b
%All pumps mass flows should be above zero: 
A.pumpL = -eye(total);
B.pumpL = zeros(total,1);

% Extraction limith pump one 
A.extract1 = c.v1'*c.ts/3600;  
B.extract1 = c.TdMax1;

% Pump one upper limith
A.pumpU1 = c.A_31; 
B.pumpU1 = ones(c.Nc,1)*c.umax1; 

%Extraction limith pump two 
A.extract2 = c.v2'*c.ts/3600;  
B.extract2 = c.TdMax2;

% Pump two upper limith 
A.pumpU2 = c.A_32; 
B.pumpU2 = ones(c.Nc,1)*c.umax2; 

%Water Tower upper and lower limith: 
A.towerL=-c.A_2*c.A_1*c.ts/3600; 
B.towerL=-c.Vmin*ones(c.Nc,1)+c.V*ones(c.Nc,1)-c.A_2*c.ts*c.d/3600;  

A.towerU=c.A_2*c.A_1*c.ts/3600;
B.towerU=c.Vmax*ones(c.Nc,1)-c.V*ones(c.Nc,1)+c.A_2*c.ts*c.d/3600;  

%Collecting all into one matrix: 
AA=[A.pumpL;A.extract1;A.pumpU1;A.extract2;A.pumpU2;A.towerL;A.towerU];
BB=[B.pumpL;B.extract1;B.pumpU1;B.extract2;B.pumpU2;B.towerL;B.towerU];

%% Defining cost functions: 

% Water level in water tower (need for the cost functions)
 h= 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);
 %h=@(u) 0; 
  

%Different cost function if it is the scaled version or not  
if scaled == false 


    %Defining part which is about the elevation and water height: 
    height1=@(u) c.A_31*u/3600.*(c.g0*c.rhoW*(h(u)+c.z1));
    
    height2=@(u) c.A_32*u/3600.*(c.g0*c.rhoW*(h(u)+c.z2)); 
    
    %Defining  part due to pipe resitance which is separated: 
    PipeResistance1= @(u) c.rf1*c.A_31*(u.*abs(u).*abs(u)); 
    
    PipeResistance2= @(u) c.rf2*c.A_32*(u.*abs(u).*abs(u)); 
    
    %Definine pipe resistance with both flows presented: 
    PipeResistanceTogether1= @(u) c.A_31*u/3600.*c.rfTogether*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 
    PipeResistanceTogether2= @(u) c.A_32*u/3600.*c.rfTogether*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 

    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jp1= @(u) c.ts*(1/c.eta1*c.Je'/(3600*1000)*((PipeResistance1(u)+PipeResistanceTogether1(u)+height1(u)))); 
    %Pump 2 
    Jp2= @(u) c.ts*(1/c.eta2*c.Je'/(3600*1000)*(c.A_32*u/3600.*(PipeResistance2(u)+PipeResistanceTogether2(u)+height2(u)))); 
    
    %setting the allowed max evaluation for the solver higher due to the
    %cost function not being scaled, and setting the alogrithm to be sqp: 
    options = optimoptions(@fmincon,'Algorithm','sqp','MaxFunctionEvaluations',10e6);

else 
    %Defining part which is about the elevation and water height: 
    height1= c.A_31*u.*(c.g0*c.rhoW/c.condScaling*(h+c.z1));
    
    height2= c.A_32*u.*(c.g0*c.rhoW/c.condScaling*(h+c.z2)); 
    
    %Defining  part due to pipe resitance which is separated: 
    PipeResistance1=c.rf1/c.condScaling*c.A_31*(u.*abs(u).*abs(u)); 
    
    PipeResistance2=c.rf2/c.condScaling*c.A_32*(u.*abs(u).*abs(u)); 
    
    %Definine pipe resistance with both flows presented: 
    PipeResistanceTogether1=  c.A_31*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d))); 
    PipeResistanceTogether2=  c.A_32*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d))); 

    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jp1= (1/c.eta1*c.Je'*(PipeResistance1+PipeResistanceTogether1+height1)); 
    %Pump 2 
    Jp2=  (1/c.eta2*c.Je'*(PipeResistance2+PipeResistanceTogether2+height2)); 
    
    %Setting the solver alogrithm to be sqp: 
end 


%Defining that the amount of water in the tower in the start and end
%has to be the same 
Js=  c.K*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;


%Setting up the cost function: 
costFunction= (Jp1+Jp2+Js);

    
%Making the entire cost function
    
    %Defining that the cost function is to be minimized: 
    opti.minimize(costFunction); 
    opti.subject_to(AA*u<=BB);

    %Selecting solver (just using the recommanded!) 
    opti.solver('ipopt');
    sol=opti.solve();
    %Solving the problem  
    temp=sol.value(u); 
    up1=temp(1:2,1)
    %Taking out the solution: 
    uAll=temp;


end
