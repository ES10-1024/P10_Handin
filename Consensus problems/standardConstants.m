function constants = standardConstants()
  %% Constraints   
%Define the minimum and maximum amount each pump are allowed to pump during a day
constants.TdMin1=0;
constants.TdMin2=0;
constants.TdMin3=0;

constants.TdMax1=600; 
constants.TdMax2=500;
constants.TdMax3=400; 

%Defining pressure before the pumps [Pa]: 
constants.p10=0;%101325; 
constants.p20=0;%101325; 
constants.p30=0;%101325;

% Define max mass flow for each pump (m^3/h) 
constants.umax1=1/90*3600; 
constants.umax2=1/90*3600;
constants.umax3=1/90*3600;

% Defining minimum mass flow for each pump (m^3/h)
constants.umin1=0; 
constants.umin2=0;
constants.umin3=0; 

%Define minimum and maximum height in the water tower later calcuated to volumen [m]
constants.hmin=1; 
constants.hmax=2; 

constants.Vmin=270; 
constants.Vmax=540; 

%% Constant model values 
% area of the water tower 
constants.At=10;  %270; 

%Defining rho (density of water in m^3/kg)  
constants.rhoW=997;

% Defining gravitational acceleration m/s^s 
constants.g0=9.82; 

%Defining effeciny of the 3 pumps 
constants.e1=1.1; %To Be Updated!
constants.e2=1.3; %To Be Updated!
constants.e3=1.5; %To Be Updated!

% Defining pipe resistance  (stupied units so not included here
constants.rf1=1.906*10^9; 
constants.rf2=2.542*10^9; 
constants.rf3=3.018*10^9; 

% Defining pipe elevation In meters
constants.z1=50; 
constants.z2=70;
constants.z3=80;

%Amount of pumps
constants.Nu=3; 
%Amount of demands
constants.Nd=1;

%% Initial values
%initial water level [m]
constants.h=1.5; 
%Inital volumen [m^c]
%constants.V=constants.h*constants.At; 
constants.V=405;
%% noise for consumpition model
constants.NoiseMean=0; 
constants.NoiseVariance=4; 

%% MPC tuning parameter


%Defining wired K in the cost function
constants.K=0.01;%1/3600;  %To Be Updated!

%Weight for the price term
constants.Kp=1; 

%Setting sampletime in hours
constants.ts=1; 

% Defining control horizion in hours 
constants.Nc_hours = 24; %To Be Updated!

% Defining control horizion in samples 
%constants.Nc = constants.Nc_hours*3600/constants.ts; 
constants.Nc = 24; 


end