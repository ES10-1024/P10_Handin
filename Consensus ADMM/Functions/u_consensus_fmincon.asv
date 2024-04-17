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
 %% Need a few empty matrix to allow for the change in option for the solver
 Aeq=[];
 beq=[];
 lb=[];
 ub=[];
 nonlcon=[];

 %Setting the solver to use the Alorigthm sqp 
 options = optimoptions(@fmincon,'Algorithm','sqp');



%% Water level in water tower (need for the cost functions)
 h=@(u) 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);

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
        if scaledCostFunction == false 
                %Elevation 
                height1=@(u) c.g0*c.rhoW*(h(u)+c.z1);
                %Unqie resistance 
                PipeResistance1= @(u) c.rf1*c.A_31*(u.*abs(u)); 
                %Common resistance 
                PipeResistanceTogether= @(u) c.rfTogether*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d));  
                %Written up power term
                J_l= @(u) c.ts*ones(1,c.Nc)*(c.e1*c.Je/(3600*1000).*(c.A_31*u/3600.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u))));

 
        else 
                %Elevation 
                height1=@(u) c.g0*c.rhoW/10000*(h(u)+c.z1);
                %Unqie resistance 
                PipeResistance1= @(u) c.rf1/10000*c.A_31*(u.*abs(u)); 
                %Common resistance 
                PipeResistanceTogether= @(u) c.rfTogether/10000*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d));  
               %Written up power term
                J_l= @(u) ones(1,c.Nc)*(c.e1*c.Je.*(c.A_31*u.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u))));



        end 

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
        if scaledCostFunction == false 
                %elevation 
                height2=@(u) c.g0*c.rhoW*(h(u)+c.z2);
                %Uniq pipe resistance 
                PipeResistance2= @(u) c.rf2*c.A_32*(u.*abs(u)); 
                %common pipe resistance 
                PipeResistanceTogether= @(u) c.rfTogether*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 
                %Writting up the power term 
                J_l= @(u) c.ts*ones(1,c.Nc)*(c.e2*c.Je/(3600*1000).*(c.A_32*u/3600.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u))));

        
        else 
                %elevation 
                height2=@(u) c.g0*c.rhoW/10000*(h(u)+c.z2);
                %Uniq pipe resistance
                PipeResistance2= @(u) c.rf2/10000*c.A_32*(u.*abs(u));
                %common pipe resistance 
                PipeResistanceTogether= @(u)c.rfTogether/10000*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 
                %Writting up the power term 
                J_l= @(u) ones(1,c.Nc)*(c.e2*c.Je.*(c.A_32*u.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u))));
        end 

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
    
    %Defining the cost function: 
    J_l= @(u) 0; 
end 

    %% Cost function definition

    %Defining the part of the cost function which is in regard to the ADMM consensus
    %algortime 
    J_con_z = @(u) lambda'*(u-z)+c.rho/2*((u-z)'*(u-z));



    %Defining that the amount of water in the tower in the start and end
    %has to be the same 
    Js= @(u) c.K*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;
    
    %Making the entire cost function
    costFunction=@(u) (J_l(u)+Js(u)+J_con_z(u));
    %Initial guess
    x0 = x;
    
    %Solving the problem  
    u_hat = fmincon(costFunction,x0,AA,BB,Aeq,beq,lb,ub,nonlcon,options);

end

