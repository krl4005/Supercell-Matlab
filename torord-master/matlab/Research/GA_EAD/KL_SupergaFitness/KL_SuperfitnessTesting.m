function [errors] = KL_SuperfitnessTesting(logMultipliers)
%FITNESSTESTING Returns fitness of a ToR-ORd model with modifications

%% Making log-multipliers multipliers again.
currentMultipliers = exp(logMultipliers); 

%% Setting parameters (multipliers are used here
%param.bcl = 1000; %ICaL
param.bcl = 4000;
param.cellType = 0; % endocardial
param.ICaL_Multiplier = currentMultipliers(1);
param.IKr_Multiplier = currentMultipliers(2);
param.IKs_Multiplier = currentMultipliers(3);
param.INaL_Multiplier = currentMultipliers(4);
param.Jup_Multiplier = currentMultipliers(5);

% The next parameter setting is commented out at the moment - if uncommented, it slows the runtime by ca.
% 5-10%, but it makes sure no beat is simulated for much more than 5 seconds. This
% is key when the GA can produce nonsensical models (e.g. when currents can
% go crazy high) that crash - such crashes take ages to happen when ode15s
% is used, and they are extremely costly, as they eat a processor core for
% a long time and they can stall a generation of the GA too. In our
% experience, this is not a problem in the sample GA given here, but it did
% occur to us when we were making the ToR-ORd model.
% param.maxTimePerBeat = 0.5; 

options = [];
%% Standard setting of parameter simulations and running the simulation

beats = 50; % number of beats - very short for demonstration purposes
%ignoreFirst=[1:(beats/2)-2 beats/2:beats-1];
%ignoreFirst=beats-1;
ignoreFirst=[1:(beats/2)-2 beats/2:beats-1];
X0 = getStartingState('Torord_endo');

%[time, X, parameters] = modelRunner(X0, options, param, beats, ignoreFirst);
[time, X, parameters] = KL_SUPERmodelRunner(X0, options, param, beats, ignoreFirst);
currents = getCurrentsStructure(time, X, param, 0);

%% Plotting APs
% figure(5); clf
% plot(time{1,1}, X{1,1}(:,1));
% xlabel('Time (ms)');
% ylabel('Membrane potential (mV)');
% xlim([0 500]);
    
% 
% figure(6)
% plot(time{2,1}, X{2,1}(:,1));
% xlabel('Time (ms)');
% ylabel('Membrane potential (mV)');
% xlim([0 1000]);

%% Computing fitness errors 
if parameters.isFailed == 0 % If this condition holds, the simulation finished fine.   
%% EAD Detection 
Amp=[];
for x=1:length(X)
currentsV = X{x,1}(:,1);
currentsT = time{x,1};
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
Amp(x) = max(EAD)-min(EAD);

else
    Amp(x) = 0;
end 
end 

%% Calculate Error for Second Action Potential 
E_EAD = Amp(2);

%% Calculate Error for First Action Potential
    % ACTION POTENTIAL DURATION CONSTRAINTS 
    apd10 = DataReporter.getAPD(time{1,1}, X{1,1}(:,1), 0.1);
    if (0<apd10) && (apd10<50)
        E_apd10=0;
    else 
        E_apd10=1000;
    end 
    
    apd50 = DataReporter.getAPD(time{1,1}, X{1,1}(:,1), 0.5);
    if (200<apd50) && (apd50<250)
        E_apd50=0;
    else 
        E_apd50=1000;
    end 
    
    
    apd90 = DataReporter.getAPD(time{1,1}, X{1,1}(:,1), 0.9);
    if (270<apd90) && (apd90<320)
        E_apd90=0;
    else 
        E_apd90=1000;
    end 
    
    % CALCIUM TRANSIENT CONSTRAINTS 
    CaTamp = max(X{1,1}(:,6)) - min(X{1,1}(:,6));
    if (3e-04<CaTamp) && (CaTamp<4e-04)
        E_CaTamp=0;
    else 
        E_CaTamp=1000;
    end 
    
    CaT90 = DataReporter.getAPD(time{1,1}, X{1,1}(:,6), 0.9);
    if (430<CaT90) && (CaT90<480)
        E_CaT90=0;
    else 
        E_CaT90=1000;
    end 
    
    CaT50 = DataReporter.getAPD(time{1,1}, X{1,1}(:,6), 0.5);
    if (180<CaT50) && (CaT50<230)
        E_CaT50=0;
    else 
        E_CaT50=1000;
    end 
    
    CaT10 = DataReporter.getAPD(time{1,1}, X{1,1}(:,6), 0.1);
    if (30<CaT10) && (CaT10<80)
        E_CaT10=0;
    else 
        E_CaT10=1000;
    end 
    
    % AP UPSTOKE VELOCITY CONSTRAINT 
    voltage = X{1,1}(:,1); 
    t = time{1,1};
    upstroke = zeros(length(voltage-2),1);
        
    for iV=1:length(voltage)-2
        V = voltage(iV + 1)-voltage(iV);
        T = t(iV + 1)-t(iV);
        upstroke(iV) = abs(V/T);
    end 

    maxV = max(upstroke);
    
    if (300<maxV) && (maxV<400)
        E_maxV=0;
    else 
        E_maxV=1000;
    end 
    
%% Error Value

errors(1) = E_apd10 + E_apd50 + E_apd90 + E_CaTamp + E_CaT90 + E_CaT50 + E_CaT10 + E_maxV + E_EAD;

else % If simulation terminated prematurely, it's most likely useless

errors(1) = Inf;

end
%     figure(10);
%     plot(time{2,1}, X{2,1}(:,1))
%     xlabel('Time (ms)');
%     ylabel('Mem. Pot. (mV)');
%     xlim([0 600]);
%     title(['EAD amplitude: ' num2str(E_EAD) ' mV']);
end

