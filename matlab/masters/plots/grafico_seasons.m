% Estaciones
seasons = {'Summer', 'Autumn', 'Winter', 'Spring'};

custom_colors = [
    1    0    0;     % Rojo (Summer)
    1    0.5  0;     % Naranja (Autumn)
    0    0.5  1;     % Azul (Winter)
    0    0.7  0      % Verde (Spring)
];

% Número de agentes y estaciones
agents = [1 2 5 6 9 10 11 12 13 14 15];
nAgents = length(agents);
nSeasons = 4;

% Cumulative Reward por agente y estación
cumulative_reward = [
   -80.3,   -52.9,   -54.0,  -112;    % Agente 1
   -81.9,   -49.4,   -46.7,  -99.0;   % Agente 2
  -127,   -39.8,   -47.0,  -160;    % Agente 5
  -106,   -88.0,   -78.2,  -136;    % Agente 6
   -94.8,  -42.7,   -45.5,  -130;    % Agente 9
   -73.4,  -67.7,   -59.7,  -91.3;   % Agente 10
   -85.9,  -37.2,   -36.8,  -117;    % Agente 11
  -119,   -90.5,   -79.6,  -149;    % Agente 12
  -101,   -40.8,   -46.9,  -134;    % Agente 13
  -103,  -129,    -112,   -106;    % Agente 14
   -68.5,  -52.7,   -50.2,  -92.8;   % Agente 15
];


% Battery Difference por agente y estación
battery_difference = [
    0.0121, -0.00295, -0.00111, 0.0224;   % Agente 1
    0.0105, -0.00147, -0.000491, 0.0208;  % Agente 2
    0.0178,  0.00130,  0.00361, 0.0277;   % Agente 5
    0.0150, -0.00398, -0.00100, 0.0253;   % Agente 6
    0.0143, -0.00177,  0.000072, 0.0247;  % Agente 9
    0.00950,-0.00243, -0.00181, 0.0193;   % Agente 10
    0.0137,  0.000254, 0.00142, 0.0234;   % Agente 11
    0.0169, -0.00339, -0.000484, 0.0265;  % Agente 12
    0.0159,  0.00188,  0.00320, 0.0255;   % Agente 13
    0.00969,-0.00549, -0.00409, 0.0206;   % Agente 14
    0.00979,-0.00221, -0.00152, 0.0196;   % Agente 15
];

activity_index = [
    2.57, 0.925, 1.08, 2.63;  % Agente 1
    2.58, 0.932, 1.09, 2.64;  % Agente 2
    2.55, 0.920, 1.07, 2.62;  % Agente 5
    2.57, 0.963, 1.11, 2.63;  % Agente 6
    2.56, 0.925, 1.08, 2.63;  % Agente 9
    2.57, 0.917, 1.07, 2.64;  % Agente 10
    2.54, 0.882, 1.03, 2.61;  % Agente 11
    2.56, 0.942, 1.09, 2.63;  % Agente 12
    2.54, 0.882, 1.03, 2.61;  % Agente 13
    2.55, 0.904, 1.05, 2.61;  % Agente 14
    2.57, 0.919, 1.07, 2.64;  % Agente 15
];

figure;

% --- Subplot 1: Cumulative Reward ---
subplot(3,1,1);
h1 = bar(cumulative_reward, 'grouped');
title('Avg. Daily Reward');
ylabel('Reward');
xticks(1:length(agents));
xticklabels(string(agents));
for i = 1:4
    h1(i).FaceColor = custom_colors(i,:);
end
legend(seasons, 'Location', 'northeastoutside');

% --- Subplot 2: Battery Difference ---
subplot(3,1,2);
h2 = bar(battery_difference, 'grouped');
title('Battery Difference');
ylabel('Difference');
ylim([-0.0065 0.03])
xticks(1:length(agents));
xticklabels(string(agents));
for i = 1:4
    h2(i).FaceColor = custom_colors(i,:);
end

% --- Subplot 3: Activity Index ---
subplot(3,1,3);
h3 = bar(activity_index, 'grouped');
title('Activity Index');
ylabel('Index');
ylim([0 3])
xticks(1:length(agents));
xticklabels(string(agents));
xlabel('Agent');
for i = 1:4
    h3(i).FaceColor = custom_colors(i,:);
end







% 
% 
% figure;
% 
% % Subplot 1: Cumulative reward
% subplot(3,1,1);
% bar(cumulative_reward, 'grouped');
% title('Avg. Daily Reward');
% ylabel('Reward');
% xticks(1:nAgents);
% xticklabels(string(agents));
% for i = 1:4
%     h1(i).FaceColor = custom_colors(i,:);
% end
% legend(seasons, 'Location', 'northeastoutside');
% 
% % Subplot 2: Battery Difference
% subplot(3,1,2);
% bar(battery_difference, 'grouped');
% title('Battery Difference');
% ylabel('Difference');
% xticks(1:nAgents);
% for i = 1:4
%     h1(i).FaceColor = custom_colors(i,:);
% end
% xticklabels(string(agents));
% 
% % Subplot 3: Activity Index
% subplot(3,1,3);
% bar(activity_index, 'grouped');
% title('Activity Index');
% ylabel('Index');
% xticks(1:nAgents);
% xticklabels(string(agents));
% for i = 1:4
%     h1(i).FaceColor = custom_colors(i,:);
% end
% xlabel('Agent');
