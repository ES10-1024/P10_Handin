
for time=1:size(zSave,4)-1
    for k=1:size(zSave,3)
        Difference(:,:,k,time)=abs(zSave(:,:,k,time)-Xsave(:,:,k,time));
    end 
    time 
end 
%%
meanDifference=mean(mean(Difference)); 
meanDifference=squeeze(meanDifference);
clf
f=figure
plot(meanDifference)
grid on
xlabel('Iterations')
ylabel('Mean x diff from z') 
set(gca,'fontname','times')

axes('Position', [.4 .4 .45 .45])
box on 
hold on 
plot(meanDifference)
hold off 
xlim([950 1000]) 
grid 
set(gca,'fontname','times')

exportgraphics(f,'if_x=z_with_underrelexation.pdf')
