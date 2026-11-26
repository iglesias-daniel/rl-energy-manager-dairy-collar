
    orientacion_collar = 1;
    orientacion_solar = 1;
    radiacion_por_hora = 1200;
    radiacion_promedio = 1200;
    hora = 12;
    bateria_actual = 0.49;
    bateria_deseada = 0.5;



    entradas = zeros(1, 6); % Inicializar vector de entradas

    entradas(1) = orientacion_collar * orientacion_solar;
    entradas(2) = radiacion_por_hora / 1200;
    entradas(3) = radiacion_promedio / 1200;
    entradas(4) = ((hora - 12) / 12 + 1) / 2;
    entradas(5) = bateria_actual;
    entradas(6) = bateria_deseada;



    salidas = predict(neuralnetwork,entradas);



    if length(salidas) ~= 3
        error('El vector de entradas "salidas" debe tener exactamente 3 elementos.');
    end

    display(salidas)
    % Transformaciones
    w_int = round(salidas(1) * 36);   % Interrupciones de trabajo
    tx_max = round(salidas(2) * 10);  % Máximo de transmisiones
    gps_max = round(salidas(3) * 10); % Máximo de ejecuciones GPS

    % Ajustar límites si es necesario
    w_int = max(4, min(36, w_int)) % Limitar entre 4 y 36
    tx_max = max(0, min(10, tx_max)) % Limitar entre 0 y 10
    gps_max = max(0, min(10, gps_max)) % Limitar entre 0 y 10