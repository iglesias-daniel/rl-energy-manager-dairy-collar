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

% Ejecutar setup.m antes de este script (carga datos y define `comb`).

%% Iteraciones

%Parametros entrenamiento
n = 10000 % Número de episodios

%Parametros evaluacion
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


for i = 1:15
    selection = comb{i}';

    obs_info = rlNumericSpec(size(selection) + [2 0]); %El [2 0] es por las dos entradas que siempre están
    act_info = rlNumericSpec([3 1]); 
    act_info.LowerLimit = 0.1;
    act_info.UpperLimit = 1;

    env = rlSimulinkEnv("model8_train","model8_train/CowBoy",obs_info,act_info);
    env.ResetFcn = @randomstart;

    fprintf('Ambiente %d creado :D\n', i);

    initOpts = rlAgentInitializationOptions(NumHiddenUnit=32);

    % Los 16 agentes entrenados son con el algoritmo TD3
    agent = rlTD3Agent(obs_info,act_info,initOpts);

    critic = getCritic(agent);

    layers = [
    featureInputLayer((size(selection,1) + 2), 'Name', 'state')
    fullyConnectedLayer(11, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(11, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(3, 'Name', 'action')
    SaturationLayer('saturation')
    scalingLayer('Name', 'scale', 'Scale', 0.45, 'Bias', 0.55)
    ];

    actorNetwork = layerGraph(layers);

    actorOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', Inf);

    actor = rlDeterministicActorRepresentation(...
    actorNetwork, obs_info, act_info, ...
    'Observation', {'state'}, ...
    'Action', {'saturation'}, ...
    actorOptions);

    %agentOptions = rlTD3AgentOptions('SampleTime', 1, 'TargetSmoothFactor', 0.005, 'ExperienceBufferLength', 1e5);

    agentOptions = rlTD3AgentOptions('SampleTime', 1, 'TargetSmoothFactor', 0.005, 'MiniBatchSize', 128);

    agent = rlTD3Agent(actor, critic, agentOptions);
    
    agent.AgentOptions.DiscountFactor = 0.9;

    fprintf('Agente %d creado :D\n', i);
    nombreCarpeta = sprintf('\\Agente%d_245learn_6input_try2_1e5', i); %modificado

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
    %UseParallel = true

    tic
    trainResults = train(agent,env,opt);
    time = toc/60;

    fprintf('Agente %d entrenado :D en %d minutos\n', i, time);

    %% Evaluación
    
    tic
    for dia_solar = dias_de_inicio
    
        dia_radiacion = dia_solar + 4383;

        if (dia_solar <= 79 || dia_solar >=356)
            estacion = 1;
        elseif (dia_solar <= 171)
            estacion = 2;
        elseif (dia_solar <= 265)
            estacion = 3;
        else
            estacion = 4;
        end

        for bat_inicial = arr_bat_inicial
            simOut = sim('model8_agente');

            %Autonomia (horas):
            autonomia = simOut.get('autonomia');
            autonomia_data(k,1) = n_ag;
            autonomia_data(k,2) = estacion;
            autonomia_data(k,3) = bat_inicial;
            autonomia_data(k,4) = autonomia.Data(end);
    
            %Tiempo de trabajo (horas):
            duty_cycle = simOut.get('duty_cycle');
            duty_cycle_data(k,1) = n_ag;
            duty_cycle_data(k,2) = estacion;
            duty_cycle_data(k,3) = bat_inicial;
            duty_cycle_data(k,4) = sum(duty_cycle.Data);
    
            %Numero de transmisiones
            num_trans = simOut.get('num_trans');
            num_trans_data(k,1) = n_ag;
            num_trans_data(k,2) = estacion;
            num_trans_data(k,3) = bat_inicial;
            num_trans_data(k,4) = sum(num_trans.Data);
    
            %Numero de ejecuciones GPS
            num_gps = simOut.get('num_gps');
            num_gps_data(k,1) = n_ag;
            num_gps_data(k,2) = estacion;
            num_gps_data(k,3) = bat_inicial;
            num_gps_data(k,4) = sum(num_gps.Data);
    
            k = k+1;
        end
    end
    
    time = toc/60;
    fprintf('Agente %d evaluado :D en %d minutos\n', i, time);
    n_ag = n_ag+1;

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
    siminput = setVariable(siminput,"bat_deseado",normrnd(0, 5),"Workspace","model8_train");
    siminput = setVariable(siminput,"e_inicial",randn/3.162,"Workspace","model8_train");
    siminput = setVariable(siminput,"n_inicial",randn/3.162,"Workspace","model8_train");
end
