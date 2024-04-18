%% In this secript there is maked a test implementation of shamirs secret sharing 
 
%% Doing a bit of spring cleaning 
clf 
clear 
clc
close all

%% Adding path and loading in scaled standard constants
addpath("Functions\")
addpath("..\")
c=scaled_standard_constants;

%% Defining the secret and scaling it 
secret=ones(48,3)*200; 
%Scaling and rounding the secret: 
secretScaling=round(secret*c.scaling);
%% Making 3 polynium with the secret: 
yOut1=generatedOutFromFunction(secretScaling(:,1)); 
yOut2=generatedOutFromFunction(secretScaling(:,2)); 
yOut3=generatedOutFromFunction(secretScaling(:,3)); 

%% Making the sum: 
yOutSum=yOut1+yOut2+yOut3; 

%% Determine the summed value: 
a=GetFunctionParameter(yOutSum);

%% Descaling it 
aDescaled=a/c.scaling;

%% Displaying result 
disp("Scret is: ")
disp(sum(secret))

disp("The descaled secret was determinted to be: ")
disp(aDescaled) 







