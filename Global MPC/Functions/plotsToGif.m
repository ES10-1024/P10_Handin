function plotsToGif(V,Vc,Tsim,u,uP,d,dP,Elp,ElpP,Bill,BillPred,dNoise,dNoisePred)
%This function makes plots which are turned into a gif 
% Vp=all previcous volumen in the taken 
% Vc=all predicted volumens in the controlhorizion! 
% Tsim=simulation time 
% u=current and previous inputs 
% uP=predited inputs
% d=consumption so far 
% dP=predited consumption 
% Elp=previous el prices 
% ElpP=predicted el prices 
% Bill=eletricty bill so far 
% BillPred=predited eletricty bill 
% dNoise=previous consumption with noise
% dNoisePred=predited consumption with noise
%% Setting a few things up 
%Getting the standard constant
c=standardConstants; 
%Placing the figure 
fig1 = figure(1);
%set(fig1, 'Position', [0 0 1280 1024])
set(fig1, 'Position', [0 0 1920 1080])
%Determining max plot length
MaxX=3600*Tsim/c.ts+c.Nc;

%summing inputs 
uSum=sum(u);
uPsum=sum(uP);
uSum=uSum(1,2:end);
%uPsum=uPsum(2:end,1);

%% Making plot 
clf(1)
%Determining offset for the predictions 
offset=size(V,1); 
offsetVector=offset-1:1:size(Vc)+offset-2; 
subplot(3,2,1)
hold on 
%PLots sum of previous inputs 
stairs(uSum,'Color','blue')
%Plotting sum of predicted inputs 
stairs(offsetVector,uPsum, 'LineStyle', ':', 'HandleVisibility','off','Color','blue')

%Updatting offset 
offsetVector=offset-1:1:size(Vc)+offset-2; 

%Plotting previous consumption 
stairs(d,'Color','red')
%Plotting preditive consumption
stairs(offsetVector,dP, 'LineStyle', ':', 'HandleVisibility','off','Color','red')
ylabel('Mass flow [m^{3}/s]')
ylim([0 0.025])


%Plotting previous noise consumption 
stairs(dNoise,'Color','m')
%Plotting preditive noise consumption
stairs(offsetVector,dNoisePred, 'LineStyle', ':', 'HandleVisibility','off','Color','m')
ylabel('Mass flow [m^{3}/s]')
ylim([0 0.025])
yyaxis right
%Plotting previous el prices 
%stairs(Elp,'Color','green')
stairs(Elp)
%Plotting preditive el prcies
%stairs(offsetVector,ElpP, 'LineStyle', ':', 'HandleVisibility','off','Color','green')
stairs(offsetVector,ElpP, 'LineStyle', ':', 'HandleVisibility','off')
ylabel('Eletricty prices [Euro]')
ylim([0.02 0.18])
hold off 
legend('Summed pump mass flow','Consumption','Consumption with noise','Eletricty price') 
xlabel('Samples [*]')
grid on 
xlim([0 MaxX])


offsetVector=offset:1:size(Vc)+offset-1; 
subplot(3,2,3) 
hold on 
%Plots the previous volumen
plot(V,'Color','blue')
%Plotting predicted volumens
plot(offsetVector,Vc(:,1), 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
yline(c.hmax*c.At)
yline(c.hmin*c.At)
hold off 
xlim([0 MaxX])
grid 
xlabel('Samples [*]')
ylabel('Volumen [m^{3}]')
ylim([260 550])
legend('Volumen','Constraints')
title('Water volumen')

%Plotting each of the pumps mass flows 
%u previous 
%uP preditied 
subplot(3,2,2) 
hold on 
plot(u(1,:),'Color','blue')
%Plotting predicted volumens
plot(offsetVector,uP(1,:), 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
yline(c.umax1)
yline(c.umin1)
hold off 
grid 
ylim([-0.002 0.012])
ylabel('Pump mass flow [m^{3}/s]')
xlabel('Samples [*]')
legend('Pump mass flow','Constraints')
title('Pump mass flow 1')
xlim([0 MaxX])

subplot(3,2,4) 
hold on 
plot(u(2,:),'Color','blue')
%Plotting predicted volumens
plot(offsetVector,uP(2,:), 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
yline(c.umax2)
yline(c.umin2)
hold off 
grid 
ylim([-0.002 0.012])
ylabel('Pump mass flow [m^{3}/s]')
xlabel('Samples [*]')
legend('Pump mass flow','Constraints')
title('Pump mass flow 2')
xlim([0 MaxX])

subplot(3,2,5) 
hold on 
plot(Bill,'Color','blue')
%Plotting predicted volumens
plot(offsetVector,BillPred, 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
hold off 
grid 
xlabel('Samples [*]')
ylabel('Eletricty bill [Euro]')
xlim([0 MaxX])
title('Eletricty bill')


subplot(3,2,6) 
hold on 
plot(u(3,:),'Color','blue')
%Plotting predicted volumens
plot(offsetVector,uP(3,:), 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
yline(c.umax3)
yline(c.umin3)
hold off 
grid 
ylim([-0.002 0.012])
ylabel('Pump mass flow [m^{3}/s]')
xlabel('Samples [*]')
legend('Pump mass flow','Constraints')
title('Pump mass flow 3')
xlim([0 MaxX])


%Making the gif!
drawnow()
frame = getframe(1);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);
if size(V,1) <=2 
    imwrite(imind,cm,"gifs"+".gif",'gif','DelayTime',1, 'Loopcount',inf);
else
    imwrite(imind,cm,"gifs"+".gif",'gif','DelayTime',1,'WriteMode','append');
end 


hold off 
end