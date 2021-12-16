%% Color by GA Trial
% GA1 = [0.908445; 0.832723; 0.745906; 0.682993; 1.116206];
% GA2 = [0.841999; 0.722835; 0.553784; 0.55252; 1.135515];
% GA3 = [1.09072; 0.820218; 1.396819; 0.642799; 0.936673];
% GA4 = [0.663255; 0.628634; 0.821775; 0.659433; 1.26309];
 %num= [1, 2, 3, 4, 5];
%  num=repelem([1, 2, 3, 4, 5],25,1);
% scatter(num, GA1, 'r', 'filled')

%legend('GA1', 'GA2', 'GA4', 'GA5', 'baseline','location','southeast')

%% Color by parameter 
scatter(repelem(1, length(POPULATION(:,1))), exp(POPULATION(:,1)), 'r', 'filled')
hold on 
scatter(repelem(2, length(POPULATION(:,2))), exp(POPULATION(:,2)), 'g', 'filled')
hold on 
scatter(repelem(3, length(POPULATION(:,3))), exp(POPULATION(:,3)), 'y', 'filled')
hold on
scatter(repelem(4, length(POPULATION(:,4))), exp(POPULATION(:,4)), 'k', 'filled')
hold on
scatter(repelem(5, length(POPULATION(:,5))), exp(POPULATION(:,5)), 'b', 'filled')
yline(1, '--b')

%% Color by error value 
% scatter(repelem(1, length(POPULATION(:,1))), exp(POPULATION(:,1)), 20, POPULATION(:,6), 'filled')
% hold on 
% scatter(repelem(2, length(POPULATION(:,2))), exp(POPULATION(:,2)), 20, POPULATION(:,6), 'filled')
% hold on 
% scatter(repelem(3, length(POPULATION(:,3))), exp(POPULATION(:,3)), 20, POPULATION(:,6), 'filled')
% hold on
% scatter(repelem(4, length(POPULATION(:,4))), exp(POPULATION(:,4)), 20, POPULATION(:,6), 'filled')
% hold on
% scatter(repelem(5, length(POPULATION(:,5))), exp(POPULATION(:,5)), 20, POPULATION(:,6), 'filled')
% yline(1, '--b')
% 
% colormap(jet);
% hcb = colorbar();
% hcb.Title.String = "Error";
%% Color by GA Trial 
% p1 = scatter(num, exp(POPULATION(1:25,:)), 'r', 'filled', 'DisplayName', 'GA1');
% hold on 
% p2 = scatter(num, exp(POPULATION(26:50,:)), 'g','filled', 'DisplayName', 'GA2') ;
% p3 = scatter(num, exp(POPULATION(51:75,:)), 'y','filled', 'DisplayName', 'GA4');
% p4 = scatter(num, exp(POPULATION(76:100,:)), 'b','filled', 'DisplayName', 'GA5');
% yline(1, '--b')

%legend([p1(1),p2(2),p3(3),p4(4)],{'GA1', 'GA2', 'GA4', 'GA5'})

%% Plot Asthetics 
xlim([0,6])
ylim([0,2])
xticklabels({'.','ICaL','IKr','IKs','INaL','Jup','.'})
ylabel("Parameter Value")
hold off

