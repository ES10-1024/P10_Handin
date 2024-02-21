function plotsToGif(V,Vc,Tsim,u,uP,d,dP,Elp,ElpP,Bill,BillPred,dNoise,dNoisePred)
%This function makes plots which are turned into a gif 
% Vp=all previcous volume in the taken 
% Vc=all predicted volumes in the controlhorizion! 
% Tsim=simulation time 
% u=current and previous inputs 
% uP=predited inputs
% d=consumption so far 
% dP=predited consumption 
% Elp=previous el prices 
% ElpP=predicted el prices 
% Bill=electricity  bill so far 
% BillPred=predited electricity  bill 
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

set(0, 'DefaultAxesFontName', 'Times');
set(0, 'DefaultLegendFontName', 'Times');

%% 
%The plots is made such that the first columen is listed first and when the
%second columen

%% Making plot 
clf(1)
%Determining offset for the predictions 
offset=size(V,1); 
offsetVector=offset-1:1:size(Vc)+offset-2; 

%% Making plot for summed pump mass flows vs eletricity prices. 
subplot(4,2,1)
hold on 
%PLots sum of previous inputs 
stairs(uSum,'Color','blue')
%Plotting sum of predicted inputs 
stairs(offsetVector,uPsum, 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
ylim([0 0.025])
ylabel('Mass flow [m^{3}/s]')

%Updatting offset 
offsetVector=offset-1:1:size(Vc)+offset-2; 
yyaxis right
%Plotting previous el prices 
%stairs(Elp,'Color','green')
stairs(Elp)
%Plotting preditive el prcies
%stairs(offsetVector,ElpP, 'LineStyle', ':', 'HandleVisibility','off','Color','green')
stairs(offsetVector,ElpP, 'LineStyle', ':', 'HandleVisibility','off')
ylabel('Electricity  prices [Euro]')
ylim([0.02 0.25])
hold off 
legend('Summed pump mass flow','Electricity  price') 
xlabel('Samples [*]')
grid on 
xlim([0 MaxX])
title('Summed pump mass flow vs eletricity price')
%Updating offset 
%offsetVector=offset:1:size(Vc)+offset-1; 


%% Plotting consumption with and without noise 
subplot(4,2,3) 
hold on 
%Plotting previous consumption 
stairs(d,'Color','b')
%Plotting preditive consumption
stairs(offsetVector,dP, 'LineStyle', ':', 'HandleVisibility','off','Color','b')
%Plotting previous noise consumption 
stairs(dNoise,'Color',"#EDB120")
%Plotting preditive noise consumption
stairs(offsetVector,dNoisePred, 'LineStyle', ':', 'HandleVisibility','off','Color',	"#EDB120")
ylim([0 0.03])
hold off
ylabel('Mass flow [m^{3}/s]')
xlabel('Samples [*]')
xlim([0 MaxX])
grid 
legend('MPC consumption','Model consumption')
title('Consumption')

%% Plotting water volume 
%Updating offset 
offsetVector=offset:1:size(Vc)+offset-1; 
subplot(4,2,5) 
hold on 
%Plots the previous volume
plot(V,'Color','blue')
%Plotting predicted volumes
plot(offsetVector,Vc(:,1), 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
yline(c.hmax*c.At)
yline(c.hmin*c.At)
hold off 
xlim([0 MaxX])
grid 
xlabel('Samples [*]')
ylabel('Volume [m^{3}]')
ylim([220 600])
legend('Volume','Constraints')
title('Water volume')

%% Plotting eletricty bill 
subplot(4,2,7) 
hold on 
plot(Bill,'Color','blue')
plot(offsetVector,BillPred, 'LineStyle', ':', 'HandleVisibility','off','Color','blue')
hold off 
grid 
xlabel('Samples [*]')
ylabel('Electricity  bill [Euro]')
xlim([0 MaxX])
title('Electricity  bill')
%% Plotting each pump mass flows 
%Plotting each of the pumps mass flows 
%u previous 
%uP preditied 
%% Mass flow pump 1
subplot(4,2,2) 
hold on 
plot(u(1,:),'Color','blue')
%Plotting predicted volumes
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
%% Mass flow pump 2 
subplot(4,2,4) 
hold on 
plot(u(2,:),'Color','blue')
%Plotting predicted volumes
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


%%  Mass flow pump 3 
subplot(4,2,6) 
hold on 
plot(u(3,:),'Color','blue')
%Plotting predicted volumes
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
%% Making the gif!
drawnow()
frame = getframe(1);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);
if size(V,1) <=2 
    imwrite(imind,cm,"gifs"+".gif",'gif','DelayTime',1, 'Loopcount',inf);
else
    imwrite(imind,cm,"gifs"+".gif",'gif','DelayTime',1,'WriteMode','append');
end 


end