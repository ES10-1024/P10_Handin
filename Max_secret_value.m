
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





