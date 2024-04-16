function [Bill, BillPred]= eletrictyBill(uAll,Je,c,V)
%Determine the eletricty Bill now (Bill) and a prediction (BillPred) with the given U 
%U=current and expected input
%Je= eletricty prices 
%c= getting standard constant and some matrix needed for writting up the
%cost functions 
%V= voulme in the water tower 
%% Making A and v matrices for the constraints


%Setting up a few matrix needed for the consensus ADMM problem 
c.A_1=zeros(c.Nc,c.Nu*c.Nc);
index=1; 
for i=1:c.Nc
    c.A_1(i,index:index+c.Nu-1) = 1;
    index=index+c.Nu;
end

%Lower trangiular matrix to add consumption and flows 
c.A_2 = tril(ones(c.Nc,c.Nc));


%Making vi vectors utilized to pick out 1 of the 3 pumps values, add them up
%used to make extration limit. 
c.v1=ones(c.Nu*c.Nc,1);
c.v1(2:2:end) =0; 

c.v2=ones(c.Nu*c.Nc,1);
c.v2(1:2:end) =0;

%Making matrix which picks out 1 of the pumps for the enitre control
%horizion

c.A_31=zeros(c.Nc,c.Nu*c.Nc);
index=1; 
for i=1:c.Nc
    c.A_31(i,index) = 1;
    index=index+c.Nu;
end

c.A_32=zeros(c.Nc,c.Nu*c.Nc);
index=2; 
for i=1:c.Nc
    c.A_32(i,index) = 1;
    index=index+c.Nu;
end


clear i

%% Determing the Water heigh: 
 h=@(u) 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+V);

%% Determine the eletricity bill for each of the pumps: 


    %Defining part which is about the height: 
    height1=@(u) c.g0*c.rhoW*(h(u)+c.z1);
    
    height2=@(u) c.g0*c.rhoW*(h(u)+c.z2); 
    
    %Defining  part due to pipe resitance which is separated: 
      PipeResistance1= @(u) c.rf1*c.A_31*(u.*abs(u)); 
    
    PipeResistance2= @(u) c.rf2*c.A_32*(u.*abs(u)); 
    
    %Definine pipe resistance in the end with all flows: 
    PipeResistanceTogether= @(u) c.rfTogether*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 
    
    
    %Defining the cost function for the two pumps: 
    %Pump 1
    Jl1= @(u) c.ts*ones(1,c.Nc)*(c.e1*Je/(3600*1000).*(c.A_31*u/3600.*(PipeResistance1(u)+PipeResistanceTogether(u)+height1(u)))); 
    %Pump 2 
    Jl2= @(u) c.ts*ones(1,c.Nc)*(c.e2*Je/(3600*1000).*(c.A_32*u/3600.*(PipeResistance2(u)+PipeResistanceTogether(u)+height2(u)))); 
    
    costFunction=@(u) (Jl1(u)+Jl2(u));

    BillTemp=costFunction(uAll); 
    BillPred=c.A_2*BillTemp; 

    Bill=BillPred(1,1);

end 

