function u_hat = u_consensus_fmincon(lambda, z, c, n_unit,x,scaledCostFunction)
% Making the consensus problem for each of the pumps stations and water tower where n_unit
% describes which of the pumps  or water the problem is solved for. 
%Lambda= Lagrangian mulptipler 
%z the consensus variable   
%c scaled standard constants 
%n_unit which of the pumps is running 
%x is the previous solution and is utilize as initial condition for the
%scaledCostFunction if a scaled cost function is to be utilized. 
%solver
%u_hat returns the solution for the given pump 

%Defining the total number of varaibles which has to be determinted
total=c.Nc*c.Nu;
%% Setting up the optimization problem: 
import casadi.* 
opti=casadi.Opti(); 
%Definining optimiztion varaible: 
u=opti.variable(total,1);


%% Water level in water tower (need for the cost functions)
 h=1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);

%% Making cost function based on the which of the pump or water tower it is for:

    %Pump one
if (n_unit==1) 
        %Defining inequality constraints on matrix form  for which Ax<=b
        %Extraction limit
        A.extract = c.v1'*c.ts/3600;  
        B.extract = c.TdMax1;
        %Upper pump mass flow limit 
        A.pumpU = c.A_31; 
        B.pumpU = ones(c.Nc,1)*c.umax1;
        %Lower pump mass flow limit 
        A.pumpL = -eye(total);
        B.pumpL = zeros(total,1);

        %Collecting constraints into two matrix one which is mutliple with the optimization varaible (AA), and a costant BB: 
        AA=[A.extract;A.pumpU;A.pumpL];
        BB=[B.extract;B.pumpU;B.pumpL];
        %Based on if a scaled or no scaled cost function should be use the
        %cost function is written up 
 
        %Elevation 
        height1= c.A_31*u.*(c.g0*c.rhoW/c.condScaling*(h+c.z1));
        %Unqie resistance 
        PipeResistance1=  c.rf1/c.condScaling*c.A_31*(u.*abs(u).*abs(u)); 
        %Common resistance 
        PipeResistanceTogether= c.A_31*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)));  
       %Written up power term
        Jp=  (1/c.eta1*c.Je'*(PipeResistance1+PipeResistanceTogether+height1));

        %Defining that the amount of water in the tower in the start and end
        %has to be the same 
        Js=  c.K/3*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;
        %Collecting into one cost function
        costFunction= Js+Jp; 



         

end  

%Pump two 
if (n_unit==2)
        %Defining inequality constraints on matrix form  for which Ax<=b
        %Extraction limith 
        A.extract = c.v2'*c.ts/3600;  
        B.extract = c.TdMax2;
        %Upper pump mass flow limith 
        A.pumpU = c.A_32; 
        B.pumpU = ones(c.Nc,1)*c.umax2;
        %Lower pump mass flow limith 
        A.pumpL = -eye(total);
        B.pumpL = zeros(total,1);

        %Collecting constraints into two matrix one which is mutliple with the optimization varaible (AA), and a costant BB: 
        AA=[A.extract;A.pumpU;A.pumpL];
        BB=[B.extract;B.pumpU;B.pumpL];
        %Based on if a scaled or no scaled cost function should be use the
        %cost function is written up 

        
        %elevation 
        height2= c.A_32*u.*(c.g0*c.rhoW/c.condScaling*(h+c.z2));
        %Uniq pipe resistance
        PipeResistance2 = c.rf2/c.condScaling*c.A_32*(u.*abs(u).*abs(u));
        %common pipe resistance 
        PipeResistanceTogether= c.A_32*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d))); 
        %Writting up the power term 
        Jp= (1/c.eta2*c.Je'*((PipeResistance2+PipeResistanceTogether+height2)));
        %Defining that the amount of water in the tower in the start and end
        %has to be the same 
        Js= c.K/3*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;
        %Collecting into one cost function
        costFunction=Js+Jp; 
         

end 


%Water tower
if n_unit==3
    %Defining inequality constraints on matrix form  for which Ax<=b
    %Defining constraints, each pump mass flow has to be above zero, upper
    %and lower water volumen limit
    A.pumpL = -eye(total);
    B.pumpL = zeros(total,1);
    %Lower water tower limith 
    A.towerL=-c.A_2*c.A_1*c.ts/3600; 
    B.towerL=-c.Vmin*ones(c.Nc,1)+c.V*ones(c.Nc,1)-c.A_2*c.ts*c.d/3600;  
    %Upper water tower limith 
    A.towerU=c.A_2*c.A_1*c.ts/3600;
    B.towerU=c.Vmax*ones(c.Nc,1)-c.V*ones(c.Nc,1)+c.A_2*c.ts*c.d/3600;  

   %Collecting constraints into two matrix one which is mutliple with the optimization varaible (AA), and a costant BB: 
    AA=[A.pumpL;A.towerL;A.towerU];
    BB=[B.pumpL;B.towerL;B.towerU];
    
    Js=  c.K/3*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;
    
    %Defining the cost function: 
    costFunction=  Js; 
    %costFunction= @(u) 0; 

end 
    %% Defining constraints 
    opti.subject_to(AA*u<=BB);
    %% Cost function definition

    %Defining the part of the cost function which is in regard to the ADMM consensus
    %algortime 
    J_con_z = lambda'*(u-z)+c.rho/2*(transpose(u-z)*(u-z));
  
   
    %Making the entire cost function
    costFunctionAll= (costFunction+J_con_z);
    %Defining that the cost function is to be minimized: 
    opti.minimize(costFunctionAll); 

    %Selecting solver (just using the recommanded!) 
    opti.solver('ipopt');
    
    %Solving the problem  
    sol=opti.solve();
    %Taking out the solution: 
    u_hat=sol.value(u);

end

