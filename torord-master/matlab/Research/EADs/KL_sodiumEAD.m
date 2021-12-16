%% Setting parameters
clear 
% param is the default model parametrization here
param.bcl = 4000;
param.model = @model_Torord;
param.cao = 140;

% A list of multipliers
cao = [2 3 4 5 6 7 8 9 10];

% Here, we make an array of parameter structures
params(1:length(cao)) = param; % These are initially all the default parametrisation

% And then each is assigned a different IKr_Multiplier
for iParam = 1:length(cao)
    params(iParam).cao = cao(iParam); % because of this line, the default parametrisation needs to have IKr_Multiplier defined (otherwise Matlab complains about different structure type).
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

title('Exploration of Cao');
legend('2', '3', '4', '5', '6', '7', '8', '9', '10'); 
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
xlim([0 700]);