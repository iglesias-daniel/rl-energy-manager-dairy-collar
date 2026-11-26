%% Iteraciones

%Parametros entrenamiento
%n = 400000 % Número de episodios
n = 10000

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

ea_desperdiciada = 0;

%% Entrenamiento

t = 0;

%Valores internos del gestor
theta = 0; 
psi = 0; 
sigma = 0.1;
gamma = 0.9; 
lambda = 0.9; 
alpha = 0.1; %0.01
beta = 0.01;
phiPrev = 0;
value = 0;

actionPrev = 0.1; % Acción inicial
action = 0.1; % Acción inicial
x_g = 0.1; % Acción inicial
reward = 0; % Recompensa inicial
    
action_array = zeros(365*24, 1);
battery_level = zeros(365*24, 1);
k = 1;

e_r = 1;

for steps = 1:10000*24

    if t == 0 || t == 24
        %e_r = 0.5; % Energía inicial
        %e_r = 1;

        e_inicial = randn / 3.162;
        n_inicial = randn / 3.162;

        n_fecha_inicial_radiacion = (randi([1 365])-1)*24 + 1;
        n_fecha_inicial = (randi([1, 4384]) - 1)*24 + 1;

        normal_vector = [e_inicial n_inicial 1];
        normal_vector = normal_vector/norm(normal_vector);

        t = 0;
    end

    %% Funcion recompensa
    E_max = 1;
    E_fail = 0;

    phi = (e_r-E_fail)/(E_max-E_fail);
    reward = phi*x_g;

    %% Algoritmo RLman

    % Cálculo del error TD (Temporal Difference Error)
    delta = reward + gamma * (theta * phi) - (theta * phiPrev);

    % Actualización del Crítico (valor del estado)
    value = gamma * lambda * value + phi;
    theta = theta + alpha * delta * value;

    % Actualización del Actor (parámetros de la política)
    psi = psi + beta * delta * (action - (psi * phiPrev)) / sigma^2 * phiPrev;

    % Política Gaussiana para seleccionar acción (tasa de paquetes)
    mu = clip(psi * phi,0.1,1);

    action = mu + sigma * randn;

    % Restricción de acción al rango permitido
    X_min = 0.1; % Tasa mínima (modificar según configuración)
    X_max = 1.0; % Tasa máxima
    action = max(min(action, X_max), X_min);

    % Actualizar estado previo
    phiPrev = phi;

    %% Calcular consumo

    duty_cycle = clip(action,0.1,1);

    frec_LoRAWAN = duty_cycle;
    frec_GPS = duty_cycle;

    % Parametros JouleScope

    modo_activo = 0; % CPU
    modo_lightsleep = 0; % ULP
    modo_deepsleep = 0; % Sleep
    processing_time = 0;
    consumo_WT = 0;
    icm42670_activo = 0.00872307;
    icm42670_sleep = 0.00156235;
    transmision_power = 0.366;
    transmision_time = 10.31/3600;
    GPS_power = 0.49475;
    GPS_time = 8.81/3600;

    modo_activo_time = (duty_cycle*3600/10)*processing_time;
    modo_deepsleep_time = 1 - modo_activo_time;
    consumo_sensor = duty_cycle*icm42670_activo + (1-duty_cycle)*icm42670_sleep + modo_activo_time*modo_activo + modo_deepsleep_time*modo_deepsleep + consumo_WT;

    if frec_LoRAWAN >= 1
        n_t = 10;
    elseif frec_LoRAWAN >= 0.1
        n_t = fix(frec_LoRAWAN*10);
    else
        n_t = 1;
    end

    if frec_GPS >= 1
        n_g = 10;
    elseif frec_GPS >= 0.1
        n_g = fix(frec_GPS*10);
    else
        n_g = 1;
    end

    consumo_gps = transmision_power*transmision_time*n_t;

    consumo_transmision = GPS_power*GPS_time*n_g;

    consumption = consumo_sensor + consumo_gps + consumo_transmision;

    %% Calcular generacion

    e_sun = sun_vector(n_fecha_inicial_radiacion+t,1);
    n_sun = sun_vector(n_fecha_inicial_radiacion+t,2);
    z_sun = sun_vector(n_fecha_inicial_radiacion+t,3);
    sun_vector_m = [e_sun n_sun z_sun];

    normal_vector = normal_vector + [sqrt(0.05)*randn() sqrt(0.05)*randn() sqrt(0.05)*randn()];
    normal_vector = normal_vector/norm(normal_vector);

    efficiency = 0.34;
    panel_power = 0.3; 
    coef_temp = -0.002; 
    I_o = 1000; 
    T_o = 25; 
    dT = -0.0471;
    a = -2.98;
    b = -0.0471;
    albedo = 0.24;

    dir_inc = max(0,dni(n_fecha_inicial+t,2)*dot(normal_vector,sun_vector_m));

    dif_inc = difh(n_fecha_inicial+t,2)*0.5*(1 + dot(normal_vector,[0 0 1]));

    dif_suelo = ghi(n_fecha_inicial+t,2)*0.5*albedo*(1 + dot(normal_vector,[0 0 1]));

    incident_rad = dir_inc + dif_inc + dif_suelo;

    T_c = dT*incident_rad/1000 + incident_rad*exp(a + b*viento(n_fecha_inicial+t,2));

    high_power = incident_rad/I_o*panel_power*(1 + coef_temp*(T_c-T_o));
    low_power = 0.008*incident_rad^2/I_o * panel_power*(1 + coef_temp*(T_c-T_o));

    if incident_rad >= 125
        power_generated = high_power;
    else
        power_generated = low_power;
    end

    power_out = 1.4327*power_generated^3 - 1.5697*power_generated^2 + 0.6165*power_generated - 0.0005;

    dif_energia = power_out - consumption;

    e_r = e_r + dif_energia/(12.25*2);

    if (e_r>1)
        ea_desperdiciada = ea_desperdiciada + e_r - 1;
    end

    e_r = clip(e_r,0,1);

    t = t + 1;
end


ea_desperdiciada = ea_desperdiciada*(12.25*2);


%Evaluacion


ea_desperdiciada = 0;
e_r = 1;

for power_cosechada = cosecha'

    phi = (e_r-E_fail)/(E_max-E_fail);
    reward = phi*x_g;

    %% Algoritmo RLman

    % Cálculo del error TD (Temporal Difference Error)
    delta = reward + gamma * (theta * phi) - (theta * phiPrev);

    % Actualización del Crítico (valor del estado)
    value = gamma * lambda * value + phi;
    theta = theta + alpha * delta * value;

    % Actualización del Actor (parámetros de la política)
    psi = psi + beta * delta * (action - (psi * phiPrev)) / sigma^2 * phiPrev;

    % Política Gaussiana para seleccionar acción (tasa de paquetes)
    mu = clip(psi * phi,0.1,1);

    action = mu + sigma * randn;

    % Restricción de acción al rango permitido
    X_min = 0.1; % Tasa mínima (modificar según configuración)
    X_max = 1.0; % Tasa máxima
    action = max(min(action, X_max), X_min);

    disp(action);

    % Actualizar estado previo
    phiPrev = phi;

    action_array(k) = action;
    battery_level(k) = e_r;
    k = k + 1;

    %% Calcular consumo

    duty_cycle = action;

    if (duty_cycle < 0.1)
        duty_cycle = 0.1;
    end

    if (duty_cycle > 1)
        duty_cycle = 1;
    end

    frec_LoRAWAN = duty_cycle;
    frec_GPS = duty_cycle;

    % Parametros JouleScope

    modo_activo = 0; % CPU
    modo_lightsleep = 0; % ULP
    modo_deepsleep = 0; % Sleep

    processing_time = 0;

    consumo_WT = 0;

    icm42670_activo = 0.00872307;
    icm42670_sleep = 0.00156235;

    %transmision_power = 0.17865;
    transmision_power = 0.366;
    transmision_time = 10.31/3600;

    GPS_power = 0.49475;
    GPS_time = 8.81/3600;

    % Ecuacion consumo

    modo_activo_time = (duty_cycle*3600/10)*processing_time;
    modo_deepsleep_time = 1 - modo_activo_time;

    consumo_sensor = duty_cycle*icm42670_activo + (1-duty_cycle)*icm42670_sleep + modo_activo_time*modo_activo + modo_deepsleep_time*modo_deepsleep + consumo_WT;

    if frec_LoRAWAN >= 1
        n_t = 10;
    elseif frec_LoRAWAN >= 0.1
        n_t = fix(frec_LoRAWAN*10);
    else
        n_t = 1;
    end

    if frec_GPS >= 1
        n_g = 10;
    elseif frec_GPS >= 0.1
        n_g = fix(frec_GPS*10);
    else
        n_g = 1;
    end

    consumo_gps = transmision_power*transmision_time*n_t;

    consumo_transmision = GPS_power*GPS_time*n_g;

    consumption = consumo_sensor + consumo_gps + consumo_transmision;


    dif_energia = power_cosechada - consumption;

    e_r = e_r + dif_energia/(12.25*2);

    

    if (e_r>1)

        ea_desperdiciada = ea_desperdiciada + e_r - 1;

    end

    e_r = clip(e_r,0,1);

end

ea_desperdiciada = ea_desperdiciada*(12.25*2);


