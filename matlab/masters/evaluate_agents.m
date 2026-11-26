
% Cargar el modelo de evaluacion
load_system('model8_agente');
set_param('model8_agente', 'StopTime', num2str(24*30-1));

mov_g = [g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias;g_30dias];
mov_g = mov_g(:,2:4);
mov_m = [m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias;m_30dias];
mov_m = mov_m(:,2:4);
col = (1:length(mov_g))';
mov_g = [col mov_g];
mov_m = [col mov_m];


arr_bat_inicial = [5 25 50 75 95];
dias_de_inicio = [1:365];
bat_deseado = 0;

quantity_of_zero = 3*5*365;
autonomia_data = zeros(quantity_of_zero, 6);
duty_cycle_data = zeros(quantity_of_zero, 6);
num_trans_data = zeros(quantity_of_zero, 6);
num_gps_data = zeros(quantity_of_zero, 6);
cum_rew_data = zeros(quantity_of_zero, 6);
dif_bat_data = zeros(quantity_of_zero, 6);
ene_dep_data = zeros(quantity_of_zero, 6);
is_dead = zeros(quantity_of_zero, 6);

k = 1;

for n_ag = 15

    % Cargar agente entrenado (ver load_agent.m)
    agent = load_agent(n_ag);
    selection = comb{n_ag};

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

            %Se descargó?
            is_dead(k,1) = n_ag;
            is_dead(k,2) = estacion;
            is_dead(k,3) = bat_inicial;

            %Tiempo de trabajo (horas):

            duty_cycle_data(k,1) = n_ag;
            duty_cycle_data(k,2) = estacion;
            duty_cycle_data(k,3) = bat_inicial;
            %Numero de transmisiones
            
            num_trans_data(k,1) = n_ag;
            num_trans_data(k,2) = estacion;
            num_trans_data(k,3) = bat_inicial;
            %Numero de ejecuciones GPS
            
            num_gps_data(k,1) = n_ag;
            num_gps_data(k,2) = estacion;
            num_gps_data(k,3) = bat_inicial;
            %Cumulative reward
            
            cum_rew_data(k,1) = n_ag;
            cum_rew_data(k,2) = estacion;
            cum_rew_data(k,3) = bat_inicial;
            %Diferencia de bateria
            
            dif_bat_data(k,1) = n_ag;
            dif_bat_data(k,2) = estacion;
            dif_bat_data(k,3) = bat_inicial;
            %Diferencia de energía
            
            ene_dep_data(k,1) = n_ag;
            ene_dep_data(k,2) = estacion;
            ene_dep_data(k,3) = bat_inicial;

            duty_cycle_data(k,4:6) = NaN;
            num_trans_data(k,4:6) = NaN;
            num_gps_data(k,4:6) = NaN;
            cum_rew_data(k,4:6) = NaN;
            dif_bat_data(k,4:6) = NaN;
            ene_dep_data(k,4:6) = NaN;
            is_dead(k,4:6) = 1;

            try
                % Código que puede generar un error
                simOut = sim('model8_agente');
            catch ME
                % Código para manejar el error
                disp(['Error encontrado: ', ME.message]);
                continue
            end

            duty_cycle = simOut.get('duty_cycle');
            num_trans = simOut.get('num_trans');
            num_gps = simOut.get('num_gps');
            cum_rew = simOut.get('cumulative_reward');
            dif_bat = simOut.get('diferencia_bat');
            ene_dep = simOut.get('energia_desperdiciada');


            if length(duty_cycle.Data) >= 24
                duty_cycle_data(k,6) = sum(duty_cycle.Data(1:23));
                num_trans_data(k,6) = sum(num_trans.Data(1:23));
                num_gps_data(k,6) = sum(num_gps.Data(1:23));
                cum_rew_data(k,6) = cum_rew.Data(23);
                dif_bat_data(k,6) = dif_bat.Data(23);
                ene_dep_data(k,6) = ene_dep.Data(23);

                duty_cycle_data(k,5) = sum(duty_cycle.Data(1:end));
                num_trans_data(k,5) = sum(num_trans.Data(1:end));
                num_gps_data(k,5) = sum(num_gps.Data(1:end));
                cum_rew_data(k,5) = cum_rew.Data(end);
                dif_bat_data(k,5) = dif_bat.Data(end);
                ene_dep_data(k,5) = ene_dep.Data(end);

                duty_cycle_data(k,4) = sum(duty_cycle.Data);
                num_trans_data(k,4) = sum(num_trans.Data);
                num_gps_data(k,4) = sum(num_gps.Data);
                cum_rew_data(k,4) = cum_rew.Data(end);
                dif_bat_data(k,4) = dif_bat.Data(end);
                ene_dep_data(k,4) = ene_dep.Data(end);

                is_dead(k,6) = 0;
             end

            if length(duty_cycle.Data) >= 24*7
                duty_cycle_data(k,5) = sum(duty_cycle.Data(1:(24*7-1)));
                num_trans_data(k,5) = sum(num_trans.Data(1:(24*7-1)));
                num_gps_data(k,5) = sum(num_gps.Data(1:(24*7-1)));
                cum_rew_data(k,5) = cum_rew.Data(24*7-1);
                dif_bat_data(k,5) = dif_bat.Data(24*7-1);
                ene_dep_data(k,5) = ene_dep.Data(24*7-1);

                is_dead(k,5) = 0;
            end

            if length(duty_cycle.Data) >= 24*30
                duty_cycle_data(k,4) = sum(duty_cycle.Data);
                num_trans_data(k,4) = sum(num_trans.Data);
                num_gps_data(k,4) = sum(num_gps.Data);
                cum_rew_data(k,4) = cum_rew.Data(24*30-1);
                dif_bat_data(k,4) = dif_bat.Data(24*30-1);
                ene_dep_data(k,4) = ene_dep.Data(24*30-1);
                
                is_dead(k,4) = 0;
            end


            % duty_cycle_data(k,4) = sum(duty_cycle.Data);
            % duty_cycle_data(k,5) = sum(duty_cycle.Data(1:(24*7-1)));
            % duty_cycle_data(k,6) = sum(duty_cycle.Data(1:23));
            % num_trans_data(k,4) = sum(num_trans.Data);
            % num_trans_data(k,5) = sum(num_trans.Data(1:(24*7-1)));
            % num_trans_data(k,6) = sum(num_trans.Data(1:23));
            % num_gps_data(k,4) = sum(num_gps.Data);
            % num_gps_data(k,5) = sum(num_gps.Data(1:(24*7-1)));
            % num_gps_data(k,6) = sum(num_gps.Data(1:23));
            % cum_rew_data(k,4) = cum_rew.Data(24*30-1);
            % cum_rew_data(k,5) = cum_rew.Data(24*7-1);
            % cum_rew_data(k,6) = cum_rew.Data(23);
            % dif_bat_data(k,4) = dif_bat.Data(24*30-1);
            % dif_bat_data(k,5) = dif_bat.Data(24*7-1);
            % dif_bat_data(k,6) = dif_bat.Data(23);
            % ene_dep_data(k,4) = ene_dep.Data(24*30-1);
            % ene_dep_data(k,5) = ene_dep.Data(24*7-1);
            % ene_dep_data(k,6) = ene_dep.Data(23);
    
            k = k+1;
        end
    end
    
    time = toc/60;
    fprintf('Agente %d evaluado :D en %d minutos\n', n_ag, time);

end



