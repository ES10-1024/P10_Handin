function [Vp1] = ModelPredicted(V,u,d)
%Function for the model, which gives prediction within the entire control horzion,
% 
% as inputs has:
%V volumen hieght in the water twoer
%u pump mass flows in m^3/s for the entire control horizion
%d demand in m^3/s for the entire control horizion

%% Define constant from the rapport
c=standardConstants;
%% Define the state space matrixs (from the report) 
A=1; 
Bu=ones(1,c.Nu)*c.ts; 
Bd=ones(1,c.Nd)*c.ts;

%% Determine the next output corresponding to the output of the function 
Vp1=A*V+Bu*u(:,1)-Bd*d(1,1);

%% Next making prediction for the rest of the control horizion 
for index=2:size(u,2) 
    Vp1(index,1)=A*Vp1(index-1,1)+Bu*u(:,index)-Bd*d(index,1);
end 






end