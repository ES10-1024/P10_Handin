function u_hat = u_consensus(lambda, z, c, n_unit)
% Making the consensus problem for each of the pumps stations  where: 

% n_unit describes which of the pumps the problem is solved for.
%Lambda = lagrange mulptiplyer
% u_c corresponds to z. 
%c standard constants 
%n_unit which of the pumps is running 
%u_hat returns the solution for the given pump 
%% Setting up the optimization problem (THIS SHOULD INCLUDE THE LAST DETERMINTED PUMPE time shift one forward!) 
    problem = optimproblem;
    u = optimvar('u',c.Nc*c.Nu);    
   

%Water level in water tower (need for the cost functions)
    h=c.g0*c.rhoW*1/c.At*(c.A_2*(c.A_1*u-c.d)+c.V);
    
    %Setting up constraints and cost function which is unique for the given
    %pump
    %Pump 1
if (n_unit==1) 
        %Defining constraints 
        problem.Constraints.pump1U = c.A_31*u <= c.umax1;
        problem.Constraints.pump1L = u >=0;
        %Defining cost function 
        J_l = ones(1,c.Nc)*(c.e1*c.Je/1000.*(c.A_31*(u.*u.*u/3600^3*c.rf1 + u/3600*c.g0*c.rhoW*c.z1) + (c.A_31*u/3600).*h));

end     
%Pump 2 
if (n_unit==2)
        %Defining constraints 
        problem.Constraints.pump2U = c.A_32*u <= c.umax2;
        problem.Constraints.pump2L = u >=0;
        %Defining cost function 
        J_l = ones(1,c.Nc)*(c.e2*c.Je/1000.*(c.A_32*(u.*u.*u/3600^3*c.rf2 + u/3600*c.g0*c.rhoW*c.z2) + (c.A_32*u/3600).*h));

end 
%Pump 3
if (n_unit==3)
        %Defining constraints 
        problem.Constraints.pump3U = c.A_33*u <= c.umax3;
        problem.Constraints.pump3L = u >=0;
        %Defining cost function 
        J_l = ones(1,c.Nc)*(c.e3*c.Je/1000.*(c.A_33*(u.*u.*u/3600^3*c.rf3 + u/3600*c.g0*c.rhoW*c.z3)+ (c.A_33*u/3600).*h));
end





    %% Cost function definition

    %Defining cost function part which is in regard to the ADMM consensus
    %algortime 
    J_ADMM1 = lambda'*(u-z);
    J_ADMM2 = c.rho/2*norm(u-z)^2;
    %Start and stop water level should be equal! 
    Js=c.K*(ones(1,c.Nc)*(c.A_1*u-c.d))^2;
    
    %Defining entire cost function
    problem.Objective = J_l+Js+J_ADMM1+J_ADMM2;

    
    %Initial guess
    x0.u = zeros(c.Nc*c.Nu,1);
    
    %Solving the problem and getting the solution. 
    solution = solve(problem,x0);
    u_hat = solution.u;
end

