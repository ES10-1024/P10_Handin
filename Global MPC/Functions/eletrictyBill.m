function [Bill, BillPred]= eletrictyBill(U,Je)
%Determine the eletrictyBill now and a prediction with the given U 
%U=current and expected input
%Je= eletricty prices 
%loading in costant
%U=uAll;
%Je=ElPrices;
c=standardConstants();

Jp1=0; 
for index=1:c.Nc 
    P1(index,1)=c.e1*U(index,1)*(c.rf1*U(index,1)*U(index,1)+c.rho*c.g*c.z1-c.p10); 
    Jp1(index,1)=1/(3600*1000)*Je(index,1)*c.ts*P1(index,1); 
end 


Jp2=0; 
for index=1:c.Nc 
    P2(index,1)=c.e2*U(index,2)*(c.rf2*U(index,2)*U(index,2)+c.rho*c.g*c.z2-c.p20); 
    Jp2(index,1)=1/(3600*1000)*Je(index,1)*c.ts*P2(index,1); 
end 

Jp3=0; 
for index=1:c.Nc 
    P3(index,1)=c.e3*U(index,3)*(c.rf3*U(index,3)*U(index,3)+c.rho*c.g*c.z3-c.p30); 
    Jp3(index,1)=1/(3600*1000)*Je(index,1)*c.ts*P3(index,1); 
end
Bill=Jp1(1,1)+Jp2(1,1)+Jp3(1,1);
BillPred=Jp1+Jp2+Jp3;

for index=2:size(BillPred,1) 
    BillPred(index,1)=BillPred(index,1)+BillPred(index-1,1);
end