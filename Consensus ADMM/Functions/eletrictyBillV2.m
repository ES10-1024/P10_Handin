function [Bill]= eletrictyBillV2(uAll,Je,c,V)
%Determine the eletricty Bill now (Bill) and a prediction (BillPred) with the given U 
%U=current and expected input
%Je= eletricty prices 
%c= getting standard constant and some matrix needed for writting up the
%cost functions 
%V= voulme in the water tower 
%% Making A and v matrices for the constraints
%A_1 each row have 3 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:1
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix to add consumption and inflow 
c.A_2 = tril(ones(1,1));

%Making vi vectors utilized to pick out 1 of the 3 pumps values, add them up
%and used to make extration limit. 
c.v1=ones(c.Nu,1);
c.v1(2:c.Nu:end) =0; 

c.v2=ones(c.Nu,1);
c.v2(1:c.Nu:end) =0;

%Making matrix which picks out 1 of the pumps for the enitre control
%horizion
c.A_31=[];
for i=1:1
    c.A_31 = blkdiag(c.A_31,[1 0]);
end

c.A_32=[];
for i=1:1
    c.A_32 = blkdiag(c.A_32,[0 1]);
end
clear i
%% Determing the Water heigh: 
 h=@(u) 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d(1,1)/3600)+V);

%% Determine the eletricity bill for each of the pumps: 


    %Defining part which is about the height: 
    height1=@(u) c.g0*c.rhoW*(h(u)+c.z1);
    
    height2=@(u) c.g0*c.rhoW*(h(u)+c.z2); 
    
    %Defining  part due to pipe resitance which is separated: 
      PipeResistance1= @(u) c.rf1*c.A_31*(u.*abs(u)); 
    
    PipeResistance2= @(u) c.rf2*c.A_32*(u.*abs(u)); 
    
    %Definine pipe resistance in the end with all flows: 
    PipeResistanceTogether= @(u) c.rfTogether*(abs(c.A_1*u-c.d(1,1)).*(c.A_1*u-c.d(1,1))); 
    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jl1= @(u) c.ts*ones(1,1)*(1/c.eta1*Je(1,1)/(3600*1000).*(c.A_31*u/3600.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u)))); 
    %Pump 2 
    Jl2= @(u) c.ts*ones(1,1)*(1/c.eta2*Je(1,1)/(3600*1000).*(c.A_32*u/3600.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u)))); 
    
    costFunction=@(u) (Jl1(u)+Jl2(u));

    Bill=costFunction(uAll(1:c.Nu)); 

end 

