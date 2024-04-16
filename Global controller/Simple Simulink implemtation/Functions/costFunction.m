function [cost] = costFunction(u,c)
%Determing the cost of the cost function with the given solution 
%u= pumps mass flow
%c= standard constants 


%% Written up the cost function with the given solution: 
%Water level 
h=c.g0*c.rhoW*1/c.At*(c.A_2*(c.A_1*u-c.d)+c.V);

%Cost for each of the pumps 
J1 = ones(1,c.Nc)*(c.e1*c.Je/1000.*(c.A_31*(u.*u.*u./3600^3*c.rf1 + u/3600*c.g0*c.rhoW*c.z1) + (c.A_31*u/3600).*h+c.A_31*u/3600.*(c.rfTogether*(c.A_1*u/3600).*(c.A_1*u/3600))));
J2 = ones(1,c.Nc)*(c.e2*c.Je/1000.*(c.A_32*(u.*u.*u./3600^3*c.rf2 + u/3600*c.g0*c.rhoW*c.z2) + (c.A_32*u/3600).*h+c.A_32*u/3600.*(c.rfTogether*(c.A_1*u/3600).*(c.A_1*u/3600))));

%Start and end water amount should by the same 
Js=c.K*(ones(1,c.Nc)*(c.A_1*u-c.d))^2;

%% Determining the cost: 
cost=J1+J2+Js;
end