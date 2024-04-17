function [VolumePred] = ModelPredicted(V,u,d)
%Function for the model, which gives water volume predictions within the entire control horzion,

%V volumen in the water twoer
%u pump mass flows in m^3/h for the entire control horizion
%d demand in m^3/h for the entire control horizion

%VolumePred the prediction for water volume for the entire control horzion

%% Define constant from the rapport
c=scaled_standard_constants;
%% Define the state space matrixs (from the report) 
A=1; 
Bu=ones(1,c.Nu)*c.ts/3600; 
Bd=ones(1,c.Nd)*c.ts/3600;

%% Determine the next water volume based on the inputs to the system which will be utilized:  
VolumePred=A*V+Bu*u(1:c.Nu,1)-Bd*d(1,1);

%% Next making prediction for the rest of the control horizion, based on the determinted inputs 
i=2;
for index=c.Nu+1:c.Nu:size(u,1)
    VolumePred(i,1)=A*VolumePred(i-1,1)+Bu*u(index:index+c.Nu-1,1)-Bd*d(i,1);
    i=i+1;
end 






end