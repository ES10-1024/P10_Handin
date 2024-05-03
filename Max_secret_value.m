
for time=1:size(Xsave,4)
 for k=1:size(Xsave,3)
    SummedX(:,k,time)=Xsave(:,1,k,time)+Xsave(:,2,k,time)+Xsave(:,3,k,time);
 end 
end 
disp("Max summed x is:")
max(SummedX(:))
disp("Mini summed x is:")
min(SummedX(:))


for time=1:size(Xsave,4)
 for k=1:size(Xsave,3)
    r(:,k,time)=norm(Xsave(:,1,k,time)-SummedX(:,k,time))^2+norm(Xsave(:,2,k,time)-SummedX(:,k,time))^2+norm(Xsave(:,3,k,time)-SummedX(:,k,time))^2;
 end 
end

disp("Max residual is:")
max(r(:))
disp("Mini residual x is:")
min(r(:))

%% 
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
%% Printing the results
disp("Max summed x is:")
disp(max(SummedX(:)))
disp("Mini summed x is:")
disp(min(SummedX(:)))


disp("Max residual is:")
disp(max(r(:)))
disp("Mini residual x is:")
disp(min(r(:)))

disp("Max value of zi is:")
disp(max(zi(:)))
disp("Min value of zi is:")
disp(min(zi(:)))

disp("Max value of zi summed is:")
disp(max(ziSum(:)))
disp("Min value of zi summed is:")
disp(min(ziSum(:)))
%% 
clear zi 
clear ziSum
k=1; 
time=1; 
for x=1:3 
    zi(:,k,time,x)=Xsave(:,x,k,time)+1/rho*lambdaSave(:,x,k,time);
end 
ziSum=zi(:,:,:,1)+zi(:,:,:,2)+zi(:,:,:,3); 
%% 







