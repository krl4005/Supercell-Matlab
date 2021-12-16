%% This gives an example of a genetic algorithm which refits the ToR-ORd model to aim for baseline APDs, Calcium Transient, and EAD 
clear

addpath KL_SupergaFitness; % this folder contains fitness functions

disp('starting fitting');

% Parameters for the optimizer:
nGenerations = 10; % number of optimization generations (cycles of crossover, mutation, and selection)
timeLimit = 300 * 60; % rough time limit of the optimization in seconds. However, the generation that happens when the limit is reached is finished.
popSize = 100; % Number of creatures in the population.

 options = optimoptions('ga', 'outputFcn', @saveGeneration, 'PopulationSize', popSize, 'Generations', nGenerations, 'TimeLimit', timeLimit,'SelectionFcn', ...
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
[coeffEstimate,FVAL,EXITFLAG,OUTPUT,POPULATION,SCORE] = ga(@KL_SuperfitnessTesting, 5,[],[],[],[], lowerBound, upperBound, [],[], options);

save data/gaOutputs.mat; 
load data/gaOutputs.mat;

for iCreature = 1:size(coeffEstimate, 1) 
   [errorvalues{iCreature}, currentsModels{iCreature}, X, time, E_EAD] = KL_SuperfitnessTestingCurrents(coeffEstimate(iCreature,:)); % fitnessTestingCurrents is copy-pasted fitnessTesting, which furthermore returns the structure of currents, so we can look at how the optimized cell looks.
end

%% Plotting outputs of the models. The models best in one criterion are usually quite bad in the other one, so it's mainly about whether the models that are pretty good in both criteria are good enough.
%for iCreature = 1:size(coeffEstimate, 1)
    
    apd90 = DataReporter.getAPD(time{1,1}, X{1,1}(:,1), 0.9);
    CaTamplitude = max(X{1,1}(:,6)) - min(X{1,1}(:,6));
    
    %figure(iCreature+1); clf
    figure(2); clf
    
    subplot(3,1,1);
    plot(time{1,1}, X{1,1}(:,1));
    xlabel('Time (ms)');
    ylabel('Mem. pot. (mV)');
    xlim([0 600]);
    title(['APD90: ' num2str(apd90) ' ms']);
    
    subplot(3,1,2);
    plot(time{2,1}, X{2,1}(:,1))
    xlabel('Time (ms)');
    ylabel('Mem. Pot. (mV)');
    xlim([0 600]);
    title(['EAD amplitude: ' num2str(E_EAD) ' mV']);
    
    subplot(3,1,3);
    plot(time{1,1}, X{1,1}(:,6));
    xlabel('Time (ms)');
    ylabel('Cai (mM)');
    xlim([0 600]);
    title(['CaT amplitude: ' num2str(CaTamplitude*10^6) ' nM']);
%end

%% Generate Intermediate Error Matrix and Plot Error over Generations 
location = 'C:\Users\Kristin\Desktop\Rotation3\torord-master\torord-master\matlab\Research\GA_Supercell\intermediateGAstates';
cd(location);

folder = ls(location);
file = {};

for k = 3:nGenerations+3
    file{k} = convertCharsToStrings(folder(k,1:length(folder(1,:))));
end 

file(1:2)=[]; %delete first two cells since they do not contain data

if nGenerations == 10 
file{12}=file{3}; %move "10.mat" to the end of the list
file(3)=[]; %delete "10.mat" from the 3rd position in the list 
end 

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
yline(4.49e+3,'k--') %Baseline Model Error for type 3
%yline(22.32,'k--') %Baseline Model Error for type 2

legend('Mean Fit', 'Best Fit', 'Baseline')
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

%% Plot all parameter solutions for last generation
%% Color by error value 
figure(5)
scatter(repelem(1, length(POPULATION(:,1))), exp(POPULATION(:,1)), 20, AllErrors(:,nGenerations+1), 'filled')
hold on 
scatter(repelem(2, length(POPULATION(:,2))), exp(POPULATION(:,2)), 20, AllErrors(:,nGenerations+1), 'filled')
hold on 
scatter(repelem(3, length(POPULATION(:,3))), exp(POPULATION(:,3)), 20, AllErrors(:,nGenerations+1), 'filled')
hold on
scatter(repelem(4, length(POPULATION(:,4))), exp(POPULATION(:,4)), 20, AllErrors(:,nGenerations+1), 'filled')
hold on
scatter(repelem(5, length(POPULATION(:,5))), exp(POPULATION(:,5)), 20, AllErrors(:,nGenerations+1), 'filled')
yline(1, '--b')

colormap(jet);
hcb = colorbar();
hcb.Title.String = "Error";

% figure(5)
% scatter(repelem(1, length(POPULATION(:,1))), exp(POPULATION(:,1)), 'r', 'filled')
% hold on 
% scatter(repelem(2, length(POPULATION(:,2))), exp(POPULATION(:,2)), 'g', 'filled')
% hold on 
% scatter(repelem(3, length(POPULATION(:,3))), exp(POPULATION(:,3)), 'y', 'filled')
% hold on
% scatter(repelem(4, length(POPULATION(:,4))), exp(POPULATION(:,4)), 'k', 'filled')
% hold on
% scatter(repelem(5, length(POPULATION(:,5))), exp(POPULATION(:,5)), 'b', 'filled')
% yline(1, '--b')

xlim([0,6])
ylim([0,2])
xticklabels({'.','ICaL','IKr','IKs','INaL','Jup','.'})
ylabel("Parameter Value")
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



