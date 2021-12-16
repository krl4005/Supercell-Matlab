GA1 = [0.908445; 0.832723; 0.745906; 0.682993; 1.116206];
GA2 = [0.841999; 0.722835; 0.553784; 0.55252; 1.135515];
GA3 = [1.09072; 0.820218; 1.396819; 0.642799; 0.936673];
GA4 = [0.663255; 0.628634; 0.821775; 0.659433; 1.26309];
num= [1; 2; 3; 4; 5];

scatter(num, GA1, 'r', 'filled')
hold on 
scatter(num, GA2, 'g', 'filled')
hold on 
scatter(num, GA3, 'y', 'filled')
hold on
scatter(num, GA4, 'k', 'filled')
yline(1, '--b')

legend('GA1', 'GA2', 'GA3', 'GA4', 'baseline','location','southeast')
xlim([0,6])
xticklabels({'.','ICaL','IKr','IKs','INaL','Jup','.'})
ylabel("Parameter Value")
hold off

