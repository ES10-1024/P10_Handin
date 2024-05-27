function [Vp1] = Model(V,u,d)
%Function for the model, which gives the next water volume given the
% Inputs:
%V volumen in the water twoer [m^3]
%u pump mass flows in m^3/h 
%d comupstion in m^3/h

%Output 
%Vp1 Next water volume in water [m^3] 

%% Loading in scaled standard constants 
c=scaled_standard_constants;

%% Define the model:  
A=1; 
Bu=ones(1,c.Nu)*c.ts/3600; 
Bd=ones(1,c.Nd)*c.ts/3600;

%% Determine the next water volume:  
Vp1=A*V+Bu*u(1:c.Nu,1)-Bd*d(1,1);

end