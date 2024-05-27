function [share] = generatedOutFromFunction(secret) 
%Here it is desired to determine the output from function based on random b
%and c values, where a is the secret

%Loading in scaled standard constants
cc=scaled_standard_constants;

%Predetermining the output size 
share=zeros(cc.Nu+1,size(secret,1)); 

%Going though each entries in the matrix, and hidding the secret using a
%function 
for index=1:size(secret,1)
    %a correspondes to the secret: 
    a=round(secret(index,1)); 
    
    %b and c is determinted from a unifrom distrubtion from 0 to fininth field
    %prime-1
    b=round(unifrnd(0,cc.prime-1));
    c=round(unifrnd(0,cc.prime-1));
    
    %Making a matrix to determine 3 different outputs one for each stakeholder: 
    constants=[a;b;c]; 
    %Making matrix of the different x values (rho 1 x=1, rho 2 x=2, rho 3 x=3): 
    Q=[1 1 1; 1 2 4; 1 3 9];
    
    %Determining the share value: 
    share(:,index)=mod(Q*constants,cc.prime); 
end 

end

