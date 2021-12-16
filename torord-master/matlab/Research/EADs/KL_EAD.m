% This is a simple script which runs the control endocardial model for 100
% beats and plots membrane potential and calcium transient.

%% Setting parameters
clear 

param.bcl = 4000; % basic cycle length in ms
param.model = @model_Torord; % which model is to be used - right now, use @model_Torord. In general, any model with the same format of inputs/outputs as @model_Torord may be simulated, which is useful when current formulations are changed within the model code, etc.
param.verbose = true; % printing numbers of beats simulated.
param.IKr_Multiplier = 0.15; 
param.nao = 137
param.cao = 2
param.clo = 148 %Could not find this parameter in the model!!

options = []; % parameters for ode15s - usually empty
beats = 100; % number of beats
ignoreFirst = beats - 1; % this many beats at the start of the simulations are ignored when extracting the structure of simulation outputs (i.e., beats - 1 keeps the last beat).

X0 = getStartingState('Torord_endo'); % starting state - can be also Torord_mid or Torord_epi for midmyocardial or epicardial cells respectively.

%% Simulation and extraction of outputs
[time, X] = modelRunner(X0, options, param, beats, ignoreFirst);

currents = getCurrentsStructure(time, X, param, 0);


%% Plotting membrane potential and calcium transient
figure(1);
plot(currents.time, currents.V);
xlabel('Time (ms)');
ylabel('Membrane potential (mV)');
xlim([0 1000]);