function constants = scaled_standard_constants()
  %% Constraints   
%Define the maximum amount each pump are allowed to pump during a day


constants.TdMax1=3.6; 
constants.TdMax2=3.6;

% Define max mass flow for each pump (m^3/h) 
constants.umax1=0.3;   
constants.umax2=0.3;


% Defining minimum mass flow for each pump (m^3/h)
constants.umin1=0; 
constants.umin2=0;


%Define minimum and maximum height in the water tower later calcuated to volumen [m]
constants.hmin=0.1; 
constants.hmax=0.55; 

constants.Vmin=28/1000; 
constants.Vmax=155/1000; 

%% Constant model values 
% area of the water tower 
constants.At=0.283; 

%Defining rho (density of water in m^3/kg)  
constants.rhoW=997;

% Defining gravitational acceleration m/s^s 
constants.g0=9.82; 

%Defining effeciny of the 3 pumps 
% constants.e1=1.1; 
% constants.e2=1.3; 

constants.eta1=0.909;
constants.eta2=0.769;

% Defining pipe resistance  (stupied units so not included here
constants.rf1=0.35*10^5;
constants.rf2=0.42*10^5;

%Defining ressistance after 
constants.rfTogether = 0.29*10^5; 

% Defining pipe elevation In meters
constants.z1=2; 
constants.z2=1.5;

%Amount of pumps
constants.Nu=2; 
%Amount of demands
constants.Nd=1;

%% Initial values
%Inital volumen [m^c]
constants.V = 0.1316;%56/1000; %0.085;


%% MPC tuning parameter


%Defining wired K in the cost function
constants.K=900; %450; %800

%Setting sampletime in seconds
constants.ts=600;%1; 

% Defining control horizion in samples 
constants.Nc =24;  

%Defining accelerated time (amount of accelered hour in one real world hour 
constants.AccTime=6; 
%% Variables defining for the consensus algortime 
%Defining amount of iteration that the consensus ADMM should do 
constants.iteration=125; %125;%300;% 150;

constants.rho=1; 
%% If the cost function should be scaled: 
constants.scaled=true; 
%% If disturbance with regard to demand should be utilized: 
constants.disturbance=true;
%% If the electricity price should be scaled 
constants.scaledEletricityPrice=true;
%% If SMPC should be used for consensus ADMM 
constants.UseSMPC=false; 
%% If rho should changes its value in the end to ensure consensus 
constants.changeRhoEnd=true;
%The value rho should have in the end 
constants.RhoEnd=500; 
%The iteration number that rho should change to a higher number 
constants.iterationRhoChange=30; 
%% Define if it is allowed to vary rho if it is the case how many iterations 
constants.varying_rho=true; 
constants.varying_rho_iterations_numbers=10; 
constants.mu=5;  
constants.tauIncr=1.5;
constants.tauDecr=1.5;
%% Stopping criteria values 
constants.epsilonPri=0.07; %0.90; %1e-2; 
constants.epsilonDual=0.06; %0.90; %1e-2;
constants.epsilonRel=10^(-3); 
constants.epsilonAbs=0.05; 
constants.maxIterations=500; 
constants.stopCriterionStart=35; 
constants.betweenStopCheck=5;
%% Scaling for conditioning 
constants.condScaling=10000;
%% SMPC varaibles 
  %% Constraints   
%Defining the primenumber for the finith field 
constants.prime=4294967029;  

% Defining scaling factor 
constants.scaling=10000;

constants.sMPCOffset=5;
end