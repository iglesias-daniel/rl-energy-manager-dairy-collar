% Este script está diseñado para crear, entrenar y evaluar agentes de RL
% con diferentes observaciones. Inicialmente se tienen 6:
% 
% 1. Orientación
% 2. Radiación 1h
% 3. Radiación prom. dia
% 4. Hora
% 0. Batería deseada
% 0. Batería actual
%
% Las primeras dos siempre se utilizarán, las otras se combinarán, siendo
% un total de 2^4= 16 combinaciones.


%% Iteraciones

%Parametros entrenamiento
n = 41600 % Número de episodios
%n = 10000

%Parametros evaluacion
%% Ajuste de datos de radiacion

inicio_2016 = (4384 - 1)*24 + 1;

difh = [difh(1:113856,:);difh(113856-95:113856,:);difh(inicio_2016:end,:)];
difh = difh(:,2);
dni = [dni(1:113856,:);dni(113856-95:113856,:);dni(inicio_2016:end,:)];
dni = dni(:,2);
ghi = [ghi(1:113856,:);ghi(113856-95:113856,:);ghi(inicio_2016:end,:)];
ghi = ghi(:,2);
glb = [glb(1:113856,:);glb(113856-95:113856,:);glb(inicio_2016:end,:)];
glb = glb(:,2);
viento = [viento(1:113856,:);viento(113856-95:113856,:);viento(inicio_2016:end,:)];
viento = viento(:,2);

col = (1:length(difh))';
difh = [col difh];
dni = [col dni];
ghi = [col ghi];
glb = [col glb];
viento = [col viento];

sun_vector = [sun_vector; sun_vector];

%% Evaluación

% Cargar el modelo de evaluacion
load_system('model8_agente');
set_param('model8_agente', 'StopTime', num2str(24*365));

mov_g = [g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias];
mov_g = mov_g(:,2:4);
mov_m = [m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias];
mov_m = mov_m(:,2:4);
col = (1:length(mov_g))';
mov_g = [col mov_g];
mov_m = [col mov_m];


arr_bat_inicial = [25 50 75];
%dias_de_inicio = [1 80 172 266];
dias_de_inicio = [1:30:365];
bat_deseado = 0;

autonomia_data = zeros(25*9*6, 4);
duty_cycle_data = zeros(25*9*6, 4);
num_trans_data = zeros(25*9*6, 4);
num_gps_data = zeros(25*9*6, 4);

k = 1;
n_ag = 1;


%for i = 6:15
for i = 1
    selection = [4];

    obs_info = rlNumericSpec([6 1]); %El [2 0] es por las dos entradas que siempre están
    act_info = rlNumericSpec([1 1]); 
    act_info.LowerLimit = 16.326;
    act_info.UpperLimit = 112.715;

    env = rlSimulinkEnv("model8_train","model8_train/TinyMan",obs_info,act_info);
    env.ResetFcn = @randomstart;

    fprintf('Ambiente %d creado :D\n', i)

    %% Definición de las redes del actor y del critico
  
    actorNetwork = dlnetwork;

    tempNet = [
        featureInputLayer(6,"Name","state")
        fullyConnectedLayer(64,"Name","fc1")
        reluLayer("Name","relu1")
        fullyConnectedLayer(64,"Name","fc2")
        reluLayer("Name","relu2")
        fullyConnectedLayer(64,"Name","fc3")
        reluLayer("Name","relu3")
        fullyConnectedLayer(1,"Name","action")
        tanhLayer("Name","tanh")
        scalingLayer("Name","scale","Bias", 48.1945, 'Bias', 64.520)];
    actorNetwork = addLayers(actorNetwork,tempNet);
    
    % clean up helper variable
    clear tempNet;
    
    actorNetwork = initialize(actorNetwork);

    criticNetwork = dlnetwork;

    tempNet = [
        featureInputLayer(6,"Name","input_1")
        fullyConnectedLayer(64,"Name","fc_1")];
    criticNetwork = addLayers(criticNetwork,tempNet);
    
    tempNet = [
        featureInputLayer(1,"Name","input_2")
        fullyConnectedLayer(64,"Name","fc_2")];
    criticNetwork = addLayers(criticNetwork,tempNet);
    
    tempNet = [
        concatenationLayer(1,2,"Name","concat")
        reluLayer("Name","relu_body_1")
        fullyConnectedLayer(64,"Name","fc_body_1")
        reluLayer("Name","relu_body_2")
        fullyConnectedLayer(64,"Name","fc_body_2")
        reluLayer("Name","body_output")
        fullyConnectedLayer(1,"Name","output")];
    criticNetwork = addLayers(criticNetwork,tempNet);
    
    % clean up helper variable
    clear tempNet;
    
    criticNetwork = connectLayers(criticNetwork,"fc_1","concat/in1");
    criticNetwork = connectLayers(criticNetwork,"fc_2","concat/in2");
    criticNetwork = initialize(criticNetwork);

    %% Opciones del actor y del crítico

    %actorOptions = rlOptimizerOptions("LearnRate", 1e-4); %ORIGINAL
    %criticOptions = rlOptimizerOptions("LearnRate", 1e-4); %ORIGINAL

    actorOptions = rlOptimizerOptions("LearnRate", 1e-3);
    criticOptions = rlOptimizerOptions("LearnRate", 1e-3);


    % agentOptions = rlTD3AgentOptions(...
    %     "ExperienceBufferLength",1e5,...
    %     "MiniBatchSize",100,...
    %     "DiscountFactor",0.995,...
    %     "PolicyUpdateFrequency",2); %ORIGINAL

    agentOptions = rlTD3AgentOptions(...
        "ExperienceBufferLength",1e5,...
        "MiniBatchSize",100,...
        "DiscountFactor",0.9,...
        "PolicyUpdateFrequency",2);

    agentOptions.ExplorationModel.StandardDeviation = 0.3;
    agentOptions.TargetPolicySmoothModel.StandardDeviation = [0.2];
    agentOptions.TargetPolicySmoothModel.LowerLimit = -0.5;
    agentOptions.TargetPolicySmoothModel.UpperLimit = 0.5;

    %agentOptions.ActorOptimizerOptions.LearnRate = 1e-4; %ORIGINAL
    %agentOptions.CriticOptimizerOptions(1).LearnRate = 1e-4; %ORIGINAL
    %agentOptions.CriticOptimizerOptions(2).LearnRate = 1e-4; %ORIGINAL

    agentOptions.ActorOptimizerOptions.LearnRate = 1e-3; 
    agentOptions.CriticOptimizerOptions(1).LearnRate = 1e-3; 
    agentOptions.CriticOptimizerOptions(2).LearnRate = 1e-3; 

    actor = rlDeterministicActorRepresentation(...
    actorNetwork, obs_info, act_info, ...
    'Observation', {'state'}, ...
    'Action', {'tanh'}, ...
    actorOptions);

    critic = rlQValueFunction(criticNetwork, obs_info, act_info);

    critic2 = rlQValueFunction(criticNetwork, obs_info, act_info);


    agent = rlTD3Agent(actor, critic, agentOptions);

    fprintf('Agente tinyMAN %d creado :D\n', i);
    nombreCarpeta = sprintf('\\Agente%d_tinyMAN_10k_5x_t22_easy_1e3', i); %modificado

    opt = rlTrainingOptions(...
    MaxEpisodes=n,...
    MaxStepsPerEpisode=24,...
    StopTrainingCriteria="None", ...
    SaveAgentCriteria="EpisodeCount", ...
    SaveAgentValue=n, ...
    SaveAgentDirectory = pwd + string(nombreCarpeta), ...
    UseParallel=false, ...
    Plots = "none");
    %Plots = "training-progress");

    tic
    trainResults = train(agent,env,opt);
    time = toc/60;

    fprintf('Agente %d entrenado :D en %d minutos\n', i, time);

end



%% Función de inicio aleatorio
% Esta funcion permite que cada episodio de entrenamiento, sea con
% distintos valores.
function siminput = randomstart(siminput)
    siminput = setVariable(siminput,"seed_x",randi(1e5),"Workspace","model8_train");
    siminput = setVariable(siminput,"seed_y",randi(1e5),"Workspace","model8_train");
    siminput = setVariable(siminput,"seed_z",randi(1e5),"Workspace","model8_train");
    siminput = setVariable(siminput,"seed_solar",randi(1e5),"Workspace","model8_train");
    siminput = setVariable(siminput,"seed_radiation",randi(1e5),"Workspace","model8_train");
    siminput = setVariable(siminput,"bat_inicial",randi([1 100]),"Workspace","model8_train");
    %siminput = setVariable(siminput,"bat_deseado",normrnd(0,5),"Workspace","model8_train"); ORIGINAL
    siminput = setVariable(siminput,"bat_deseado",normrnd(0, 3),"Workspace","model8_train");
    siminput = setVariable(siminput,"e_inicial",randn/3.162,"Workspace","model8_train");
    siminput = setVariable(siminput,"n_inicial",randn/3.162,"Workspace","model8_train");
end
