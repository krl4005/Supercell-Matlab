%% Setting parameters
clear 
% param is the default model parametrization here
param.bcl = 4000;
param.model = @model_Torord;
param.IKr_Multiplier = 1;
ICaL_Multiplier = 1;

% A list of multipliers
icalMultipliers = [ 17 18 19]; %above 17 causes multiple EADs

% Here, we make an array of parameter structures
params(1:length(icalMultipliers)) = param;

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(icalMultipliers)
    params(iParam).ICaL_Multiplier = icalMultipliers(iParam);
end

options = [];
beats = 100;
ignoreFirst = beats - 1;

%% Simulation and output extraction

% Now, the structure of parameters is used to run multiple models in a
% parallel-for loop.
parfor i = 1:length(params) 
    X0 = getStartingState('Torord_endo');
    [time{i}, X{i}] = modelRunner(X0, options, params(i), beats, ignoreFirst);
    currents{i} = getCurrentsStructure(time{i}, X{i}, params(i), 0);
end


%% Plotting APs
figure(1); clf
for i = 1:length(params)
    hold on
    plot(currents{i}.time, currents{i}.V);
    hold off
end

title('Exploration of I_{CaL}');
legend('1','12','14','16','17','18','19'); 
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 1000]);

%% EAD Detection 
Amp=[];
for x=1:length(params)
currentsV = currents{x}.V;
currentsT = currents{x}.time
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

greatest = find(max(amps));  %determine which block has the largest amplitude 
EAD_rise = blocks{greatest}; %define largest amplitude as EAD

%Eliminates all zero values and finds the left and right points of the EAD
LP = EAD_rise(1);
L_index = find(currentsV==LP);
peak = find(currentsV>LP-1 & currentsV<LP+1.0);
R_index = peak(length(peak));
RP=currentsV(R_index);

EAD = currentsV(L_index:R_index); %All membrane potential values during EAD

%If the Amplitude is under 1mV, there is no EAD
Amp(x) = max(EAD)-min(EAD);

else
    Amp(x) = 0;
end 
end 
Amp