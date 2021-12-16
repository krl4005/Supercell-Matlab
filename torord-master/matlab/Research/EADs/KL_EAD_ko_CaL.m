%% Setting parameters
clear 
% param is the default model parametrization here
param1.bcl = 4000;
param1.model = @model_Torord;
param1.ko = 5;
param1.IKr_Multiplier = 1;
param1.ICaL_Multiplier = 1;

% A list of multipliers
ko = [1 1 2 2 3 3 4 4 5 5]; %high and low bounds each parameter that cause SINGLE EADs
icalMultipliers = [17 18 8 11 9 13 10 15 13 14];

% Here, we make an array of parameter structures
params1(1:length(ko)) = param1; % These are initially all the default parametrisation
params1(1:length(icalMultipliers)) = param1;

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(ko)
    params1(iParam).ko = ko(iParam); % because of this line, the default parametrisation needs to have IKr_Multiplier defined (otherwise Matlab complains about different structure type).
    params1(iParam).ICaL_Multiplier = icalMultipliers(iParam);
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

title('Exploration of Ko with CaL');
legend('Ko=1, ICaL=17', 'Ko=1, ICaL=18', 'Ko=2, ICaL=8', 'Ko=2, ICaL=11', 'Ko=3, ICaL=9', 'Ko=3, ICaL=13', 'Ko=4, ICaL=10', 'Ko=4, ICaL=15', 'Ko=5, ICaL=13', 'Ko=5, ICaL=14'); 
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 1000]);

%% EAD Detection 
currentsV = currents{3}.V;
clear 'EAD_rise'
rises=[];
e=length(currentsV);
s=round(length(currentsV)/2);

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
 wrap       = [0, rises, 0] ;
 temp       = diff( wrap ~= 0 ) ;
 blockStart = find( temp == 1 ) + 1 ;
 blockEnd   = find( temp == -1 ) ;
 blocks     = arrayfun( @(bId) wrap(blockStart(bId):blockEnd(bId)), ...
                         1:numel(blockStart), 'UniformOutput', false ) ;

amps = []
for j=1:length(blocks)
    group = blocks{j};
    low= min(blocks{j});
    up= max(blocks{j});
    amps(j)= up-low
end 
greatest = find(max(amps));
EAD_rise = blocks{greatest};

if exist('EAD_rise')==1
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
    disp('No EADs Detected or ERROR') 
end 