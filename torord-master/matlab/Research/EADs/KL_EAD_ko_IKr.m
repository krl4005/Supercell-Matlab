%% Setting parameters
clear 
% param is the default model parametrization here
param1.bcl = 4000;
param1.model = @model_Torord;
param1.INaCa_Multiplier = 1;
param1.ICaL_Multiplier = 1;

% A list of multipliers
ko = [3 4 5];
ikrMultipliers = [4 3 3];

% Here, we make an array of parameter structures
params1(1:length(ko)) = param1; % These are initially all the default parametrisation
params1(1:length(ikrMultipliers)) = param1;

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(ko)
    params1(iParam).INaCa_Multiplier = ko(iParam); 
    params1(iParam).ICaL_Multiplier = ikrMultipliers(iParam);
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

title('Exploration of NaCa with ICaL block');
legend('NaCa=3, ICaL=4', 'NaCa=4, ICaL=4', 'NaCa=5, ICaL=3'); 
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 1500]);