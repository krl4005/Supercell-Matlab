%% Setting parameters
clear 

param.bcl = 4000; % basic cycle length in ms
param.model = @model_Torord; % which model is to be used - right now, use @model_Torord. In general, any model with the same format of inputs/outputs as @model_Torord may be simulated, which is useful when current formulations are changed within the model code, etc.
param.verbose = true; % printing numbers of beats simulated.
param.IKr_Multiplier = 0.15; 
param.nao = 137;
param.cao = 2;
param.clo = 148; 

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

%% EAD Detection 
rises=[];
for i=170:length(currents.V)-1
    t1=currents.V(i);
    t2=currents.V(i+1);
    if t2>t1
        rises(i)=t2;
    end 
end 

EAD_rise = nonzeros(rises);

LP = EAD_rise(1);
L_index = find(currents.V==LP);

peak = find(currents.V>LP-1 & currents.V<LP+1.0);

R_index = peak(length(peak));
RP=currents.V(R_index);

EAD = currents.V(L_index:R_index);
for j=1:length(EAD)
if EAD(j) > -89 & EAD(j)< -87
    EAD(j)=0
end 
end 

%If the Amplitude is under 1mV, there is no EAD
Amp = max(EAD)-min(EAD)
