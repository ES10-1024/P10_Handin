function [Finith] = FinithFields(NotFinith)
%FINITH FIELDS Making a number fit in the finith field 
%Input NotFinith is not within the fintih field, whereas the out Finith is
%within the finith field 

%Defining the output size because Simulink needs 
Finith=zeros(size(NotFinith,1),size(NotFinith,2)); 

%Loading in scaled standard constants 
c=scaled_standard_constants;
 
%Going though each entire, in the vector, if the value is above the max,
%the prime number is subscracted until it fits. If the value is below the
%minimum value, the prime number is add until non neagtive value is reached
%
for index=1:size(NotFinith,1)
    while  c.prime-1<NotFinith(index,1)
                NotFinith(index,1)=NotFinith(index,1)-c.prime; 
               
    end 
    
    while NotFinith(index,1)<=0
            NotFinith(index,1)=NotFinith(index,1)+c.prime;
           
    end 
end 

Finith=NotFinith; 

end

