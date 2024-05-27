%% Describtion
% Use this script to run the global controller in Simulink  
%% Making alot of clears 
clf 
clc 
clear
close all
%% Adding path and standard values
addpath("Functions\")
addpath("..\Subsystem Reference\")
addpath("..\..\")
c=scaled_standard_constants; 
%% Define simulation time 
simHour=250; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 
%% Running the simulation 
simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% Saving the data from the simulation 
save('global_controller_465_mm.mat')




