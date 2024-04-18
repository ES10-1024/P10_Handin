function [summedSecret] = GetFunctionParameter(summedFunctionValue)
%Taking in the sum of the function values summedFunction 
%The output is the summed of the secret 

%Predetermine the output (something Simulink wants) 
summedSecret=zeros(size(summedFunctionValue,2),1);
%Defining the reconnestion vector: 
r=[3 -3 1];

%Going though each of the entires in summed Function values 
for index=1:size(summedFunctionValue,2)
   
    %Determine the sum of the secret: (or a or intersection with the y-axis)  
    summedSecret(index,1)=r*summedFunctionValue(:,index); 
    
    %Making it finith/getting the value within the finith field 
    summedSecret(index,1)=FinithFields(summedSecret(index,1)); 
end 

end

