function [Vp1] = Model(V,u,d)
%Function for the model, which gives the next output, as inputs has:
%V volumen hieght in the water twoer
%u pump mass flows in m^3/s 
%d demand in m^3/s 

%% Define constant from the rapport
c=standardConstants;
%% Define the state space matrixs (from the report) 
A=1; 
Bu=ones(1,c.Nu)*c.ts; 
Bd=ones(1,c.Nd)*c.ts;

%% Determine the next output corresponding to the output of the function 
Vp1=A*V+Bu*u-Bd*d; 




end