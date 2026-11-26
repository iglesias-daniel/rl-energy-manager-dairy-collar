function [consumption,n_t,n_g] = consume_model(duty_cycle,frec_LoRAWAN, frec_GPS)

%% Parametros
modo_activo = 0.095; % CPU
modo_lightsleep = 0.000792; % ULP
modo_deepsleep = 0.0000264; % Sleep

processing_time = 2/3600;

consumo_WT = 0.0000231;

icm42670_activo = 0.001814;
icm42670_sleep = 0.00001155;

transmision_power = 0.254;
transmision_time = 1.133/3600;

GPS_power = 0.437;
GPS_time = 48.520/3600;


%% Parametros JouleScope

modo_activo = 0; % CPU
modo_lightsleep = 0; % ULP
modo_deepsleep = 0; % Sleep

processing_time = 0;

consumo_WT = 0;

icm42670_activo = 0.009433816;
icm42670_sleep = 0.003735742;

transmision_power = 0.17865;
transmision_time = 1.47204/3600;

GPS_power = 0.37702;
GPS_time = 7.26796/3600;

%% Ecuacion consumo

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

end

