%% In this script simulated result from the global and consensus ADMM controller is compared 
%% Making a bit of cleaning 
clear 
clf 
clc
close all 
%% Adding paths and scaled standard constants
addpath("..\Global controller\Subsystem Reference\")
addpath("..\Global controller\Simple Simulink implemtation\Functions\")
addpath("..\Global controller\Simple Simulink implemtation\")
addpath("..\Consensus ADMM\Simulink implementing\")
addpath("..\Consensus ADMM\Simulink implementing\Functions\")
addpath("..\Consensus ADMM\Simulink implementing\Subsystem Reference\")
addpath("..\")
c=scaled_standard_constants; 
%% Define simulation time 
simHour=250; 
simTime=simHour/c.AccTime*3600; 
c.Tsim=num2str(simTime); 
%% Simulating the global controller
globalCon.simData=sim('GlobalMPC.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% Simulating the consensus controller 
consensusCon.simData=sim('ADMM_consensus.slx',"StartTime",'0',"StopTime",c.Tsim,'FixedStep','200');
%% Saving the data
save('Simulated_results_fmincon_no_smpc_250hr.mat')

