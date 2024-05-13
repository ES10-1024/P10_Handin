%% In this script it is desired to determine the minimum and maximum value, for all shares and secret in SMPC
% It is neccesary to load in a mat file before use!

%% Summed value of x 
for time=1:size(Xsave,4)
     for k=1:size(Xsave,3)
        SummedX(:,k,time)=Xsave(:,1,k,time)+Xsave(:,2,k,time)+Xsave(:,3,k,time);
     end 
end 
%% Primal residual both individual and summed
for time=1:size(Xsave,4)
     for k=1:size(Xsave,3)
         ri(:,k,time,1)=norm(Xsave(:,1,k,time)-SummedX(:,k,time)/3)^2; 
         ri(:,k,time,2)=norm(Xsave(:,2,k,time)-SummedX(:,k,time)/3)^2;
         ri(:,k,time,3)=norm(Xsave(:,3,k,time)-SummedX(:,k,time)/3)^2;
        r(:,k,time)=ri(:,k,time,1)+ri(:,k,time,2)+ri(:,k,time,3);
     end 
end



%% consensus variable z, both indiviudal and summed 
for x=1:3 
  for time=1:size(Xsave,4)
    for k=1:size(Xsave,3)
           if k<=10
               rho=saveRho(k,time); 
           elseif k>=30 
               rho=saveRho(end,time)*500; 
           else 
               rho=saveRho(end,time); 
           end 
          zi(:,k,time,x)=Xsave(:,x,k,time)+1/rho*lambdaSave(:,x,k,time);
    end
    time
  end 
end 
ziSum=zi(:,:,:,1)+zi(:,:,:,2)+zi(:,:,:,3);
%% Printing the all the maximum and minimum, of the secrets
clc
disp("Min value of zi is:")
disp(min(zi(:)))
disp("Max value of zi is:")
disp(max(zi(:)))

disp("Min value of xi is:")
disp(min(Xsave(:)))
disp("Max value of xi is:")
disp(max(Xsave(:)))

disp("Min value of ri is:")
disp(min(ri(:)))
disp("Max value of ri is:")
disp(max(ri(:)))


disp("Min zi summed zi is:")
disp(min(ziSum(:)))
disp("Max  summed zi is:")
disp(max(ziSum(:)))


disp("Mini summed x is:")
disp(min(SummedX(:)))
disp("Max summed x is:")
disp(max(SummedX(:)))

disp("Mini summed ri is:")
disp(min(r(:)))
disp("Max summed ri is:")
disp(max(r(:)))

 







