function [Finith] = FinithFields(NotFinith)
%FINITH_FIELDS Making a number fit in the finith field 
%Loading standardConstants to get the prime number 
Finith=zeros(size(NotFinith,1),1);
c=standardConstants(); 
for index=1:size(Finith,1) 
    %If within the finit do nothing
    if 0<=NotFinith(index,1) && NotFinith(index,1)<=c.prime-1
        Finith(index,1)=NotFinith(index,1); 
        %If above the fininth field of prime-1, substract the finith field
        %value
    elseif  c.prime-1<NotFinith(index,1)
        while  c.prime-1<NotFinith(index,1)
            NotFinith(index,1)=NotFinith(index,1)-c.prime; 
        end 
        Finith(index,1)=NotFinith(index,1); 
        %If below 0 added the prime value such it becomes with the finith
        %field
    else
        while NotFinith(index,1)<0
            NotFinith(index,1)=NotFinith(index,1)+c.prime;
        end 
        Finith(index,1)=NotFinith(index,1); 
    end 
end 

end

