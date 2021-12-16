
%% Setting parameters
clear 
% param is the default model parametrization here
param.bcl = 1000;
param.model = @model_Torord;
param.INa_Multiplier = 1;
param.INaL_Multiplier = 1;

% A list of multipliers
%inaMultipliers = [0.5 1 1.5];
inaMultipliers = [0];

% Here, we make an array of parameter structures
params(1:length(inaMultipliers)) = param; % These are initially all the default parametrisation

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(inaMultipliers)
    %params(iParam).INa_Multiplier = inaMultipliers(iParam); % because of this line, the default parametrisation needs to have IKr_Multiplier defined (otherwise Matlab complains about different structure type).
    params(iParam).INaL_Multiplier = inaMultipliers(iParam);
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
    plot(currents{i}.time, currents{i}.Cai);
    hold off
end

title('Exploration of I_{Na}+I_{NaL}');
legend('0.5','1.0', '1.5');
xlabel('Time (ms)');
ylabel('Ca_mmol/L (mV)');
xlim([0 1000]);