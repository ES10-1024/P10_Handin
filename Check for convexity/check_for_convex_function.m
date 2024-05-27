%% In this script it is desired to determine if the cost function is convex 
%Starting by making a bit of cleaning  and adding scaled_standard_constants
clf 
clear 
clc 
close all 

%% Adding a few functions to the path. 
addpath("..\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")

%% Loading in the scaled electricty price 
c=scaled_standard_constants; 

%% Selected the hour which is desired to look at: 
hour=165;  
currentTime=hour*c.ts;
%% Only working with the current and one future time step: 
c.Nc=2;

%% Getting the electricty and demand 
[c.Je] = ElectrictyPrices(currentTime); 
c.Je=c.Je/norm(c.Je); 
c.Je=c.Je(1:c.Nc); 

[c.d,consumptionNoise] = consumption(currentTime);
c.d=c.d(1,1); 



%% Making A and v matrices for the optimization problem 

%A_1 each row have 2 ones such that the flow from the given time stamp is
%added
c.A_1=[];
for i=1:c.Nc
    c.A_1 = blkdiag(c.A_1,ones(1,c.Nu));
end
%Lower trangiular matrix which works as a integrer:  
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

%% Making symbol
syms u [c.Nu*c.Nc 1] 

syms H(u1,u2,u3,u4)


%% Defining cost functions 

% Water level in water tower 
h= 1/c.At*(c.A_2*(c.A_1*c.ts*u/3600-c.ts*c.d/3600)+c.V);

%Cost function with regarding the elevation: 
height1=c.g0*c.rhoW/10000*(h+c.z1);

height2= c.g0*c.rhoW/10000*(h+c.z2); 

%Defining the cost function part due to pipe resitance which is separated: 
PipeResistance1= c.rf1/10000*c.A_31*(u.*abs(u)); 

PipeResistance2=  c.rf2/10000*c.A_32*(u.*abs(u)); 

%Definine part which is due to collected mass flow though a pipe resistance: 
PipeResistanceTogether= c.rfTogether/10000*(abs(c.A_1*u-c.d).*(c.A_1*u-c.d)); 

%Writting up the cost function for pump1 and pump2 
%Pump 1
Jl1=  ones(1,c.Nc)*(1/c.eta1*c.Je.*(c.A_31*u.*(PipeResistance1+PipeResistanceTogether+height1))); 
%Pump 2 
Jl2=  ones(1,c.Nc)*(1/c.eta2*c.Je.*(c.A_32*u.*(PipeResistance2+PipeResistanceTogether+height2))); 

%Defining part of the cost function which states that the water volume
%should be the same at the start and end of the control horzion: 
Js= c.K*(c.ts*ones(1,c.Nc)*(c.A_1*u/3600-c.d/3600))^2;

%Collecting it all to one comparing cost function: 

costFunction=Jl1+Jl2+Js; 


%% Determining the Hessian of the cost function 

H(u)=hessian(costFunction,[u1 u2 u3 u4]); 

%% Going though some of the mass flows to determine if the hessian is positive semidefint
% for these values. This is determinted by seeing if the lowest eigenvalue is below zero, 
% if this is the case it is not positive semidefinite 

%Defining mass flows to go though
u11=0.001:0.01:0.3;
u22=0.001:0.01:0.3;
u33=0.001:0.01:0.3; 
u44=0.001:0.01:0.3;

%A few index to save some data: 
index=1;
indexSaveU=1; 

%Going though all the different mass flows: 
for indexU4=u44
    for indexU3=u33 
        for indexU2=u22 
            for indexU1=u11
                %Determine the hessian with the given mass flow
                temp=H(indexU1,indexU2,indexU3,indexU4); 
                %Taking out the lowest eigenvalue: 
                temp1=double(temp);
                res(index,1)=min(eig(temp1));
                %Saving the mass flows if it is below 0, such it is known
                %at which mass flow it is not convex
                if res(index,1)<0
                SaveU(:,indexSaveU)=[indexU1;indexU2;indexU3;indexU4];
                    indexSaveU=indexSaveU+1;
                end 
                index=index+1;
            end 
            
        end
        indexU3
    end 
    indexU4
end 
%% Plotting the lowest eigenvalue to see if it is below zero. 
hold on 
plot(res)
yline(0)
hold off 
xlabel('Iterations number') 
ylabel('Lowest eigenvalue')

save("check_for_convex_function_saved.mat")

