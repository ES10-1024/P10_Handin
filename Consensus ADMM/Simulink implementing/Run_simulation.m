%% Describtion
% Use this script to run the consensus ADMM controller in Simulink  
%% Making alot of clears 
clf 
clc 
clear
close all
%adding a few path: 
addpath("..\..\")
addpath("..\..\Global controller\Subsystem Reference\")
addpath("..\..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\..\Shamirs Secret Sharing\Functions\")

addpath("Functions\")
addpath("Subsystem Reference\")



%% Adding path and standard values
c=scaled_standard_constants; 
%% Define the amount of scaled hours it is desired to simulate for: 
simHour=250; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 


%% Running the simulation 
simData=sim('ADMM_consensus.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% Saving the data 
save("ADMM_consensus.mat")
