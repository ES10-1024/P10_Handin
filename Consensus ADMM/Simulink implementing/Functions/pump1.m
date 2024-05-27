function u_hat = pump1(lambda, data, z,x,rhoValue)
% Making the consensus problem for pump station 1. 
%Lambda= Lagrangian mulptipler 
%z the consensus variable   
%x is the previous solution and i utilize as initial condition for the
%solver
%rho value, the value of penalty parameter 
%u_hat returns the solution for the given pump 
%% loading in scaled standard constants 
c=scaled_standard_constants; 
%Moving data for eletricity price, demand and matrix needed to solve the problem: 
c.Je=data.Je; 
c.d=data.d;
c.V=data.V; 
c.rho=rhoValue; 



c.A_1=data.A_1; 
c.A_2=data.A_2; 

c.v1=data.v1; 
c.v2=data.v2; 

c.A_31=data.A_31; 
c.A_32=data.A_32; 


%% Defining the total number of varaibles which has to be determinted
total=c.Nc*c.Nu;
%% setting fmincon to use sqp
options = optimoptions(@fmincon,'Algorithm','sqp');
%Need a few empty matrix: 
Aeq=[];
beq=[];
lb=[];
ub=[];
nonlcon=[];


%% Water level in water tower (need for the cost functions)
 h=@(u) 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);
        
%% Defining inequality constraints on matrix form with Ax<=b 
%Extraction limith 
A.extract = c.v1'*c.ts/3600;  
B.extract = c.TdMax1;

%Upper pump flow limith 
A.pumpU = c.A_31; 
B.pumpU = ones(c.Nc,1)*c.umax1;

%LOwer pump flow limith
A.pumpL = -eye(total);
B.pumpL = zeros(total,1);


%Collecting constraints into two matrix one which is mutliple with the optimization varaible (AA), and a costant BB: 
AA=[A.extract;A.pumpU;A.pumpL];
BB=[B.extract;B.pumpU;B.pumpL];

%% Defining cost function: 

%Elevation 
height1=@(u) c.A_31*u.*(c.g0*c.rhoW/c.condScaling*(h(u)+c.z1));
%Unqie resistance 
PipeResistance1= @(u) c.rf1/c.condScaling*c.A_31*(u.*abs(u).*abs(u)); 
%Common resistance 
PipeResistanceTogether= @(u) c.A_31*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)));  
%Written up power term
Jp= @(u) (1/c.eta1*c.Je'*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u)));

%Defining that the amount of water in the tower in the start and end
%has to be the same 
Js= @(u) c.K/3*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;

%Defining the part of the cost function which is in regard to the ADMM consensus
%algortime 
J_con_z = @(u) lambda'*(u-z)+c.rho/2*((u-z)'*(u-z));

%Collecting into one cost function
costFunction=@(u) Js(u)+Jp(u)+J_con_z(u); 


%Initial guess
x0 =[x(3:end,1);x(end-1:end,1)]; 
    
%Solving the problem  
u_hat = fmincon(costFunction,x0,AA,BB,Aeq,beq,lb,ub,nonlcon,options);

end

