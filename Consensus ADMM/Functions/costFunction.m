function [cost] = costFunction(u,c,scaledCost)
%Determing the cost of the cost function with the given solution 
%u= pumps mass flow
%c= standard constants 
%scaledCost = if the scaled cost function should be used. 

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

%% Defining cost functions: 
% Water level in water tower (need for the cost functions)
 h=@(u) 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);

%If a scaled cost function should be utilized
if scaledCost == false 


    %Defining part which is about the height: 
    height1=@(u) c.g0*c.rhoW*(h(u)+c.z1);
    
    height2=@(u) c.g0*c.rhoW*(h(u)+c.z2); 
    
    %Defining  part due to pipe resitance which is separated: 
    PipeResistance1= @(u) c.rf1*c.A_31*(u.*abs(u)); 
    
    PipeResistance2= @(u) c.rf2*c.A_32*(u.*abs(u)); 
    
    %Definine pipe resistance in the end with all flows: 
    PipeResistanceTogether= @(u) c.rfTogether*(abs(c.A_1*u-c.d).*abs(c.A_1*u-c.d)); 
    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jl1= @(u) c.ts*ones(1,c.Nc)*(1/c.eta1*c.Je/(3600*1000).*(c.A_31*u/3600.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u)))); 
    %Pump 2 
    Jl2= @(u) c.ts*ones(1,c.Nc)*(1/c.eta2*c.Je/(3600*1000).*(c.A_32*u/3600.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u)))); 


else 

    %Defining part which is about the height: 

    height1=@(u) c.g0*c.rhoW/10000*(h(u)+c.z1);
    
    height2=@(u) c.g0*c.rhoW/10000*(h(u)+c.z2); 
    
    %Defining  part due to pipe resitance which is separated: 
    PipeResistance1= @(u) c.rf1/10000*c.A_31*(u.*abs(u)); 
    
    PipeResistance2= @(u) c.rf2/10000*c.A_32*(u.*abs(u)); 
    
    %Definine pipe resistance in the end with all flows: 
    PipeResistanceTogether= @(u) c.rfTogether/10000*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 
    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jl1= @(u) ones(1,c.Nc)*(1/c.eta1*c.Je.*(c.A_31*u.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u)))); 
    %Pump 2 
    Jl2= @(u) ones(1,c.Nc)*(1/c.eta2*c.Je.*(c.A_32*u.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u)))); 

end 



%Defining that the amount of water in the tower in the start and end
%has to be the same 
Js= @(u) c.K*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;


%Setting up the cost function: 
costFunction=@(u) (Jl1(u)+Jl2(u)+Js(u));

%% Determining the cost 

cost=costFunction(u); 


end