%% Setting parameters
clear 

param.bcl = 1000; % basic cycle length in ms
param.model = @model_Torord; % which model is to be used - right now, use @model_Torord. 
param.verbose = true; % printing numbers of beats simulated.
%param.IKr_Multiplier = 0.15;
param.ICaL_Multiplier = 8;
param.nao = 137;
param.cao = 2;
param.clo = 148; 

options = []; % parameters for ode15s - usually empty
beats = 100; % number of beats
ignoreFirst = beats - 1; % this many beats at the start of the simulations are ignored- keeps the last beat

X0 = getStartingState('Torord_endo'); % starting state

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
% currentsV = currents.V;
% currentsT = currents.time;

currentsV = X{1,1}(:,1);
currentsT = time{1,1};

clear 'EAD_rise'
rises=[];
e=length(currentsV);
startTime = 100;
[val,idx]=min(abs(currentsT-startTime));
s=idx; %starts at time=100

%Finds rises in the action potential after the initial 170 values 
for i=s:e-3 %change this to start relative to length
    t1=currentsV(i);
    t2=currentsV(i+3);
    
    %test 1: find all rises 
    if t2>t1
        rises(i)=t2;
    end 
end 

%Pull out the blocks of rises to determine if they are really EADs
 rises       = [0 rises 0]; %start and end with 0 so diff detects differences between elements 
 index       = diff( rises ~= 0 ) ; %finds differences between adjacent elements
 riseStart   = find( index == 1 ) + 1 ;
 riseEnd     = find( index == -1 ) ;
 blocks      = arrayfun( @(block) rises(riseStart(block):riseEnd(block)), 1:numel(riseStart), 'UniformOutput', false ) ;

if isempty(blocks)==0
amps = []; %loop through each block and find amplitudes
for j=1:length(blocks)
    group = blocks{j};
    low= min(blocks{j});
    up= max(blocks{j});
    amps(j)= up-low;
end 

greatest = find(amps==max(amps));  %determine which block has the largest amplitude 
EAD_rise = blocks{greatest}; %define largest amplitude as EAD

%Eliminates all zero values and finds the left and right points of the EAD
LP = EAD_rise(1);
L_index = find(currentsV==LP);
peak = find(currentsV>LP-1 & currentsV<LP+1.0);
R_index = peak(length(peak));
RP=currentsV(R_index);

EAD = currentsV(L_index:R_index); %All membrane potential values during EAD

%If the Amplitude is under 1mV, there is no EAD
Amp = max(EAD)-min(EAD)

else
    Amp = 0
end 