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
load_system('model6_agente');
set_param('model6_agente', 'StopTime', num2str(24*365));

%agentePPO, agenteTD3, agenteSAC
load("AgentPPO/Agent10000.mat");
agent_PPO_Trained = saved_agent;
load("AgentTD3/Agent10000.mat");
agent_TD3_Trained = saved_agent;
load("AgentSAC/Agent10000.mat");
agent_SAC_Trained = saved_agent;

agentes_a_evaluar = [agent_PPO_Trained, agent_TD3_Trained, agent_SAC_Trained];

mov_g = [g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias];
mov_g = mov_g(:,2:4);
mov_m = [m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias];
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
cosechada_data = zeros(25*9*6, 4);
consumida_data = zeros(25*9*6, 4);
carga_bateria_data = zeros(25*9*6, 4);


k = 1;
n_ag = 1;

for agente = agentes_a_evaluar
    disp("Inicio agente")
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
set_param('model6_estatico', 'StopTime', num2str(24*365));

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

%% ON-OFF

load_system('model6_onoff');
set_param('model6_onoff', 'StopTime', num2str(24*365));

    disp("Inicio onoff")

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
            simOut = sim('model6_onoff');

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
    disp("Fin onoff")