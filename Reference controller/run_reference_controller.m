%% Script to run the reference contorller implemented in Matlab, and work on the data gotten 

%% Making a bit of cleaning 
clear 
clf 
clc
close all 
%% Adding paths and scaled standard constants
addpath("..\Global controller\Subsystem Reference\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Global controller\Simple Simulink implemtation\")
addpath("..\")
addpath("Simulink implementation\")
addpath("Simulink implementation\Subsystem reference\")
c=scaled_standard_constants; 
%% Define simulation time 
simHour=24*10+1; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 
%% Simulating the global controller
RefCon.simData=sim('Reference_controller.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','30');
%% Saving the data
save('Reference_controller.mat')
