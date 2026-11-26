%% Entrenamiento

%Definición de las observaciones
obs_info = rlNumericSpec([6 1]);

%Definición de la acción
act_info = rlNumericSpec([3 1]); 

act_info.LowerLimit = 0.1;
act_info.UpperLimit = 1;

env = rlSimulinkEnv("model6_train","model6_train/CowBoy",obs_info,act_info);

env.ResetFcn = @randomstart;

function siminput = randomstart(siminput)
    siminput = setVariable(siminput,"seed_x",randi(1e5),"Workspace","model6_train");
    siminput = setVariable(siminput,"seed_y",randi(1e5),"Workspace","model6_train");
    siminput = setVariable(siminput,"seed_z",randi(1e5),"Workspace","model6_train");
    siminput = setVariable(siminput,"seed_solar",randi(1e5),"Workspace","model6_train");
    siminput = setVariable(siminput,"seed_radiation",randi(1e5),"Workspace","model6_train");
    siminput = setVariable(siminput,"bat_inicial",randi([20 100]),"Workspace","model6_train");
    siminput = setVariable(siminput,"bat_deseado",randi([-10 10]),"Workspace","model6_train");
    siminput = setVariable(siminput,"e_inicial",randn/3.162,"Workspace","model6_train");
    siminput = setVariable(siminput,"n_inicial",randn/3.162,"Workspace","model6_train");
end

disp("Ambiente creado :D")

initOpts = rlAgentInitializationOptions(NumHiddenUnit=32);

agent_TD3 = rlTD3Agent(obs_info,act_info,initOpts);
agent_TD3.AgentOptions.DiscountFactor = 0.9;
agent_PPO = rlPPOAgent(obs_info,act_info,initOpts);
agent_PPO.AgentOptions.DiscountFactor = 0.9;
agent_SAC = rlSACAgent(obs_info,act_info,initOpts);
agent_SAC.AgentOptions.DiscountFactor = 0.9;
disp("Agentes creados :D")

n = 10000;

opt = rlTrainingOptions(...
    MaxEpisodes=n,...
    MaxStepsPerEpisode=24,...
    StopTrainingCriteria="None", ...
    SaveAgentCriteria="EpisodeCount", ...
    SaveAgentValue=n, ...
    SaveAgentDirectory = pwd + "\AgentTD3", ...
    Plots = "none");

tic
trainResults_TD3 = train(agent_TD3,env,opt);
toc

disp("TD3 Entrenado :D")

opt = rlTrainingOptions(...
    MaxEpisodes=n,...
    MaxStepsPerEpisode=24,...
    StopTrainingCriteria="None", ...
    SaveAgentCriteria="EpisodeCount", ...
    SaveAgentValue=n, ...
    SaveAgentDirectory = pwd + "\AgentPPO", ...
    Plots = "none");

tic
trainResults_PPO = train(agent_PPO,env,opt);
toc

disp("PPO Entrenado :D")

opt = rlTrainingOptions(...
    MaxEpisodes=n,...
    MaxStepsPerEpisode=24,...
    StopTrainingCriteria="None", ...
    SaveAgentCriteria="EpisodeCount", ...
    SaveAgentValue=n, ...
    SaveAgentDirectory = pwd + "\AgentSAC", ...
    Plots = "none");

tic
trainResults_SAC = train(agent_SAC,env,opt);
toc

disp("SAC Entrenado :D")

%% Evaluación

data_verano_solar = 1:79;
data_otono_solar = 80:171;
data_invierno_solar = 172:265;
data_primavera_solar = 266:355;

total_dias = length(data_verano_solar) + length(data_otono_solar) + length(data_invierno_solar) + length(data_primavera_solar);

% Cargar el modelo de evaluacion
load_system('model6_agente');

%agentePPO, agenteTD3, agenteSAC
load("AgentPPO/Agent10000.mat");
agent_PPO_Trained = saved_agent;
load("AgentTD3/Agent10000.mat");
agent_TD3_Trained = saved_agent;
load("AgentSAC/Agent10000.mat");
agent_SAC_Trained = saved_agent;

agentes_a_evaluar = [agent_PPO_Trained, agent_TD3_Trained, agent_SAC_Trained];

mov_g = [g_1; g_2; g_1; g_2; g_1; g_2; g_1; g_2; g_1; g_2];
mov_g = mov_g(:,2:4);
mov_m = [m_1; m_2; m_1; m_2; m_1; m_2; m_1; m_2; m_1; m_2];
mov_m = mov_m(:,2:4);
col = (1:length(mov_g))';

mov_g = [col mov_g];
mov_m = [col mov_m];


arr_bat_inicial = [10 20 30 40 50 60 70 80 90];
bat_deseado = 0;

k = 1;
n_ag = 1;

for agente = agentes_a_evaluar
    disp("Inicio agente")
    for estacion = 1:4
        switch estacion %Elección de estación
            case 1
                dias_solar = data_verano_solar;
                set_param('model6_agente', 'StopTime', num2str(24*length(data_verano_solar)));
                disp("  Inicio verano");
            case 2
                dias_solar = data_otono_solar;
                set_param('model6_agente', 'StopTime', num2str(24*length(data_otono_solar)));
                disp("  Inicio otoño");
            case 3
                dias_solar = data_invierno_solar;
                set_param('model6_agente', 'StopTime', num2str(24*length(data_invierno_solar)));
                disp("  Inicio invierno");
            case 4
                dias_solar = data_primavera_solar;
                set_param('model6_agente', 'StopTime', num2str(24*length(data_primavera_solar)));
                disp("  Inicio primavera");
            otherwise
                disp("  Error en la estación :C")
        end
        
        dias_radiacion = dias_solar + 4383;

        dia_radiacion = dias_radiacion(1);
        dia_solar = dias_solar(1);

        for bat_inicial = arr_bat_inicial
            simOut = sim('model6_agente');

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
    
            %Energia cosechada
            cosechada = simOut.get('cosechada');
            cosechada_data(k,1) = n_ag;
            cosechada_data(k,2) = estacion;
            cosechada_data(k,3) = bat_inicial;
            cosechada_data(k,4) = sum(cosechada.Data);
    
            %Energia consumida
            consumida = simOut.get('consumida');
            consumida_data(k,1) = n_ag;
            consumida_data(k,2) = estacion;
            consumida_data(k,3) = bat_inicial;
            consumida_data(k,4) = sum(consumida.Data);
    
            %Porcentaje bateria final
            carga_bateria = simOut.get('carga_bateria');
            carga_bateria_data(k,1) = n_ag;
            carga_bateria_data(k,2) = estacion;
            carga_bateria_data(k,3) = bat_inicial;
            carga_bateria_data(k,4) = carga_bateria.Data(end);
    
            k = k+1;
        end

        
    end
    disp("Fin agente")
    n_ag = n_ag+1;
end

%% Políticas estáticas
%Optimista, moderado, pesimista

load_system('model6_estatico');

for agente = 1:3
    disp("Inicio estatico")

    switch agente
        case 1
            D = 1;
            F_tx = 1;
            F_gps = 1;
            disp("Optimista")
        case 2
            D = 0.5;
            F_tx = 0.5;
            F_gps = 0.5;
            disp("Moderado")
        case 3
            D = 0.1;
            F_tx = 0.1;
            F_gps = 0.1;
            disp("Pesimista")
    end

    for estacion = 1:4
        switch estacion %Elección de estación
            case 1
                dias_solar = data_verano_solar;
                set_param('model6_estatico', 'StopTime', num2str(24*length(data_verano_solar)));
                disp("  Inicio verano");
            case 2
                dias_solar = data_otono_solar;
                set_param('model6_estatico', 'StopTime', num2str(24*length(data_otono_solar)));
                disp("  Inicio otoño");
            case 3
                dias_solar = data_invierno_solar;
                set_param('model6_estatico', 'StopTime', num2str(24*length(data_invierno_solar)));
                disp("  Inicio invierno");
            case 4
                dias_solar = data_primavera_solar;
                set_param('model6_estatico', 'StopTime', num2str(24*length(data_primavera_solar)));
                disp("  Inicio primavera");
            otherwise
                disp("  Error en la estación :C")
        end
        
        dias_radiacion = dias_solar + 4383;

        dia_radiacion = dias_radiacion(1);
        dia_solar = dias_solar(1);

        for bat_inicial = arr_bat_inicial
            simOut = sim('model6_estatico');

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
    
            %Energia cosechada
            cosechada = simOut.get('cosechada');
            cosechada_data(k,1) = n_ag;
            cosechada_data(k,2) = estacion;
            cosechada_data(k,3) = bat_inicial;
            cosechada_data(k,4) = sum(cosechada.Data);
    
            %Energia consumida
            consumida = simOut.get('consumida');
            consumida_data(k,1) = n_ag;
            consumida_data(k,2) = estacion;
            consumida_data(k,3) = bat_inicial;
            consumida_data(k,4) = sum(consumida.Data);
    
            %Porcentaje bateria final
            carga_bateria = simOut.get('carga_bateria');
            carga_bateria_data(k,1) = n_ag;
            carga_bateria_data(k,2) = estacion;
            carga_bateria_data(k,3) = bat_inicial;
            carga_bateria_data(k,4) = carga_bateria.Data(end);
    
            k = k+1;
        end

    end
    n_ag = n_ag + 1;
    disp("Fin estatico")
end