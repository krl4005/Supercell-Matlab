%% Setting parameters
clear 
% param is the default model parametrization here
param.bcl = 4000;
param.model = @model_Torord;
param.IKr_Multiplier = 1;
ICaL_Multiplier = 1;

% A list of multipliers
ikrMultipliers = [0.3 0.5 0.5 0.5 0.6];
icalMultipliers = [3 4 5 6 7]; 

% Here, we make an array of parameter structures
params(1:length(ikrMultipliers)) = param; % These are initially all the default parametrisation
params(1:length(icalMultipliers)) = param;

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(icalMultipliers)
    params(iParam).IKr_Multiplier = ikrMultipliers(iParam); % because of this line, the default parametrisation needs to have IKr_Multiplier defined (otherwise Matlab complains about different structure type).
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

title('Exploration of I_{CaL} & I_{Kr}');
legend('IKr=0.3, ICaL=3','IKr=0.5, ICaL=4','IKr=0.5, ICaL=5','IKr=0.5, ICaL=6','IKr=0.6, ICaL=7'); 
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 1000]);

%% EAD Detection 
currentsV = currents{5}.V;
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

for j=1:length(blocks)
    group = blocks{j};
    low= min(blocks{j});
    up= max(blocks{j});
    if up-low>1
        EAD_rise = group; 
    end 
end 

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
    disp('Amp = 0')
end 