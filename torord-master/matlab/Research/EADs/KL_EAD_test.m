%% Setting parameters
clear 
% param is the default model parametrization here
param1.bcl = 4000;
param1.model = @model_Torord;
param1.ko= 5;
param1.nao= 140;
param1.cao= 1.8;
param1.INa_Multiplier = 1;
param1.ICaL_Multiplier = 1;
param1.INaL_Multiplier = 1;
param1.IKr_Multiplier=1;
param1.IKs_Multiplier=1;
param1.IK1_Multiplier=1;
param1.INaCa_Multiplier = 1;
param1.INaK_Multiplier=1;

% A list of multipliers
%kr =  [0.05 0.05 0.05 0.05 0.05  0.3   0.3 0.3 0.3 0.3   0.6   0.6 0.6 0.6 0.6];
%Ik1 = [0.1   0.5   1    3   6   0.1   0.5   1   3   6   0.1   0.5   1   3   6];

kr =  [0.05 0.05 0.05 0.3 0.3 0.3];
Naca = [1  2  5    1    3    5];

% Here, we make an array of parameter structures
params1(1:length(kr)) = param1; % These are initially all the default parametrisation
params1(1:length(Naca)) = param1;

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(kr)
    params1(iParam).IKr_Multiplier = kr(iParam); 
    params1(iParam).INaCa_Multiplier = Naca(iParam);
end

options = [];
beats = 100;
ignoreFirst = beats - 1;

%% Simulation and output extraction

% Now, the structure of parameters is used to run multiple models in a
% parallel-for loop.
parfor i = 1:length(params1) 
    X0 = getStartingState('Torord_endo');
    [time{i}, X{i}] = modelRunner(X0, options, params1(i), beats, ignoreFirst);
    currents{i} = getCurrentsStructure(time{i}, X{i}, params1(i), 0);
end


%% Plotting APs
figure(1); clf
for i = 1:length(params1)
    hold on
    plot(currents{i}.time, currents{i}.V);
    hold off
end

title('Exploration of IKr with INaL');
%legend('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'); 
%legend('IKr=0.05, INaL=0.1', 'IKr=0.05, INaL=0.5', 'IKr=0.05, INaL=1', 'IKr=0.05, INaL=3', 'IKr=0.05, INaL=6', 'IKr=0.05, INaL=8')
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 1500]);

%% EAD Detection 
Amp=[];
for x=1:length(params1)
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