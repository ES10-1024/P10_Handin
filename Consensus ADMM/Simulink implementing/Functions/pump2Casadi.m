function u_hat= pump2(lambda, data, z,x,rhoValue)
% Making the consensus problem for each of the pumps stations  where n_unit
% describes which of the pumps the problem is solved for. 
%Lambda= Lagrangian mulptipler 
%z the consensus variable   
%n_unit which of the pumps is running 
%x is the previous solution and i utilize as initial condition for the
%solver
%rho value, the value of penalty parameter 
%u_hat returns the solution for the given pump 

%% loading in scaled standard constants 
c=scaled_standard_constants; 
%Moving data for eletricity price and demand: 
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


%Defining the total number of varaibles which has to be determinted
total=c.Nc*c.Nu;

%% Setting up the optimization problem: 
import casadi.* 
opti=casadi.Opti(); 
%Definining optimiztion varaible: 
u=opti.variable(total,1);



%% Water level in water tower (need for the cost functions)
 h= 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);
        %Writting up the constraints on the form Ax<=b 
        %Extraction limith 
        A.extract = c.v1'*c.ts/3600;  
        B.extract = c.TdMax1; 
        %Upper pump mass flow limith 
        A.pumpU = c.A_31; 
        B.pumpU = ones(c.Nc,1)*c.umax1; 
        %Lower pump mass flow limith 
        A.pumpL = -eye(total);
        B.pumpL = zeros(total,1);

        %Collecting constraints into two matrix one which is mutliple with the optimization varaible (AA), and a costant BB: 
        AA=[A.extract;A.pumpU;A.pumpL];
        BB=[B.extract;B.pumpU;B.pumpL];

        %Defining the cost function

        %elevation 
        height2= c.A_32*u.*(c.g0*c.rhoW/c.condScaling*(h+c.z2));
        %Uniq pipe resistance
        PipeResistance2=  c.rf2/c.condScaling*c.A_32*(u.*abs(u).*abs(u)); 
        %common pipe resistance 
        PipeResistanceTogether= c.A_32*u.*(c.rfTogether/c.condScaling*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d))); 
        %Writting up the power term 
        Jp=  (1/c.eta2*c.Je'*((PipeResistance2+PipeResistanceTogether+height2)));
        %Defining that the amount of water in the tower in the start and end
        %has to be the same 
        Js=  c.K/3*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;
        %Js= @(u) c.K/3*(abs(ones(1,c.Nc)*(c.A_1*u-c.d)));

        %Collecting into one cost function
        costFunction= Js+Jp; 
        %% Defining constraints 
    opti.subject_to(AA*u<=BB);
    %% Cost function definition

    %Defining the part of the cost function which is in regard to the ADMM consensus
    %algortime 
    J_con_z = lambda'*(u-z)+c.rho/2*((u-z)'*(u-z));



    %Defining that the amount of water in the tower in the start and end
    %has to be the same 
    
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

