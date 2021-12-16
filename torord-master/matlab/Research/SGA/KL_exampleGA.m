%% This gives an example of a genetic algorithm which refits the ToR-ORd model to aim for baseline APD90 and Calcium Transient 
clear

addpath KL_gaFitness; % this folder contains fitness functions

disp('starting fitting');

% Parameters for the optimizer:
nGenerations = 5; % number of optimization generations (cycles of crossover, mutation, and selection)
timeLimit = 60 * 60; % rough time limit of the optimization in seconds. However, the generation that happens when the limit is reached is finished.
popSize = 10; % Number of creatures in the population.

 options = optimoptions('ga', 'outputFcn', @saveGeneration, 'PopulationSize',popSize, 'Generations', nGenerations, 'TimeLimit', timeLimit,'SelectionFcn', ...
     {@selectiontournament,2}, 'CrossoverFcn','crossoverscattered', 'CrossoverFraction', 0.8, 'EliteCount',5,...
   'PlotFcn', @gaplotbestf);

%options = optimoptions('ga', 'PopulationSize',popSize, 'Generations', nGenerations, 'TimeLimit', timeLimit, 'PlotFcn', {@gaplotbestf, @gaplotrange, @gaplotscores});
%options = optimoptions(@ga,'PlotFcn',@gaplotpareto, 'UseParallel',false, 'Generations', nGenerations, 'TimeLimit', timeLimit, 'PopulationSize', popSize);
%options = optimoptions(@ga, 'PopulationSize',popSize, 'UseParallel',false, 'Generations', nGenerations, 'TimeLimit', timeLimit, 'PlotFcn', {@gaplotbestf, @gaplotrange, @gaplotdistance});
%options = optimoptions('ga', 'PopulationSize',popSize, 'Generations', nGenerations, 'TimeLimit', timeLimit, 'PlotFcn', @gaplotbestf);


% We can restrict the multipliers of curents. Here, we restrict them to 50%-200% of the current. As we're using
% log-multipliers (see Appendix/SupMat 2 for rationale), these correspond to log(0.5) ~ -0.7 and log(2) ~ 0.7.
lowerBound = -0.7 * ones(5,1);  
upperBound = 0.7 * ones(5,1);  

% @fitnessTesting is a handle to the fitness function.
[coeffEstimate,FVAL,EXITFLAG,OUTPUT,POPULATION,SCORE] = ga(@KL_fitnessTesting, 5,[],[],[],[], lowerBound, upperBound, [],[], options);

save data/gaOutputs.mat; 
load data/gaOutputs.mat;

for iCreature = 1:size(coeffEstimate, 1)
   [ errorvalues{iCreature}, currentsModels{iCreature}] = KL_fitnessTestingCurrents(coeffEstimate(iCreature,:)); % fitnessTestingCurrents is copy-pasted fitnessTesting, which furthermore returns the structure of currents, so we can look at how the optimized cell looks.
end

%% Plotting outputs of the models. The models best in one criterion are usually quite bad in the other one, so it's mainly about whether the models that are pretty good in both criteria are good enough.
for iCreature = 1:size(coeffEstimate, 1)
    
    apd90 = DataReporter.getAPD(currentsModels{iCreature}.time, currentsModels{iCreature}.V, 0.9);
    CaTamplitude = max(currentsModels{iCreature}.Cai) - min(currentsModels{iCreature}.Cai);
    
    figure(iCreature+1); clf
    
    subplot(2,1,1);
    plot(currentsModels{iCreature}.time, currentsModels{iCreature}.V);
    xlabel('Time (ms)');
    ylabel('Mem. pot. (mV)');
    xlim([0 600]);
    title(['APD90: ' num2str(apd90) ' ms']);
    
    subplot(2,1,2);
    plot(currentsModels{iCreature}.time, currentsModels{iCreature}.Cai);
    xlabel('Time (ms)');
    ylabel('Cai (mM)');
    xlim([0 600]);
    title(['CaT amplitude: ' num2str(CaTamplitude*10^6) ' nM']);
end

%% Generate Intermediate Error Matrix 
location = 'C:\Users\Kristin\Desktop\Rotation3\torord-master\torord-master\matlab\intermediateGAstates';
cd(location);

folder = ls(location);
file = {};

for k = 3:nGenerations+3
    file{k} = convertCharsToStrings(folder(k,1:length(folder(1,:))));
end 

file(1:2)=[]; %delete first two cells since they do not contain data 

AllErrors = zeros(popSize,nGenerations);
for i = 1:nGenerations+1
    data = load(file{i});
    AllErrors(:,i)= data.score;
end 

 meanFit = zeros(1, nGenerations+1);
 bestFit = zeros(1, nGenerations+1);
 for j = 1:nGenerations+1 
     meanFit(:,j)= mean(AllErrors(:,j));
     bestFit(:,j)= min(AllErrors(:,j));
 end 

figure(3)
scatter(0:nGenerations, meanFit, 'r', 'filled')
hold on 
scatter(0:nGenerations, bestFit, 'b', 'filled')

legend('Mean Fit', 'Best Fit')
ylabel("Fitness Value")
xlabel("Generation")
hold off

figure(4)
scatter(0:nGenerations, log(meanFit), 'r', 'filled')
hold on 
scatter(0:nGenerations, log(bestFit), 'b', 'filled')

%set(gca,'yscale','log')
legend('Mean Fit', 'Best Fit')
ylabel("Fitness Value")
xlabel("Generation")
hold off
%% COMMENT: When large population is computed with long generations, it's often worth storing each generation (in case of power outage, or researcher wanting
% to look at non-final generations, to see how the algorithm converges). To do this, outputFcn (set in gaoptimset) can be defined to store population 
% at the end of each generation.
%
% That may look e.g. like:
function [state,options,optchanged] = saveGeneration(options,state,flag)
generation = state.Generation;
population = state.Population;
score = state.Score;
optchanged = false;
save(['intermediateGAstates/' num2str(generation)], 'population','score');
end

% % Note that the folder intermediateGAstates must exist first.



