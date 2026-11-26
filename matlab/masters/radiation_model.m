function [power_out] = radiation_model(normal_vector,sun_vector,DNI,DIFH,GHI,wind)

%   By: Daniel Iglesias - UFRO - 2024

%   Modelo basado en "Modelo de Generación Fotovoltaica" de Alejandra
%   Molina Monje y Francisco martínez (Marzo 2017)
%   Disponible en: https://solar.minenergia.cl/downloads/fotovoltaico.pdf
%   [Consultado el 25-11-2024]

% Normal vector:
% Vector normal al panel solar, en formato:
% [Este, Norte, Zenith]
% 
% Sun vector:
% Vector de posición del sol, en formato:
% [Este, Norte, Zenith]

%% Parametros
efficiency = 0.34;
panel_power = 0.3; % Potencia nominal de la instalación
coef_temp = -0.002; % Coeficiencte de temperatura de la celda para su potencia máxima
I_o = 1000; % Radiación de referencia
T_o = 25; % Temperatura de referencia
dT = -0.0471;
a = -2.98;
b = -0.0471;
albedo = 0.24;

%% Módulo de Radiación

% Radiación directa:
dir_inc = max(0,DNI*dot(normal_vector,sun_vector));

% Radiación difusa del cielo
dif_inc = DIFH*0.5*(1 + dot(normal_vector,[0 0 1]));

% Radiación difusa del suelo
dif_suelo = GHI*0.5*albedo*(1 + dot(normal_vector,[0 0 1]));

% Radiación total que incide en un plano inclinado:
incident_rad = dir_inc + dif_inc + dif_suelo;

%% Módulo de reflexión

% El panel utilizado no presenta una cubierta, por lo que no se consideró
% el uso de este módulo.


%% Módulo de Temperatura

% Temperatura de celda:
T_c = dT*incident_rad/1000 + incident_rad*exp(a + b*wind);

%% Módulo de Operación

% Potencia generada
high_power = incident_rad/I_o*panel_power*(1 + coef_temp*(T_c-T_o));
low_power = 0.008*incident_rad^2/I_o * panel_power*(1 + coef_temp*(T_c-T_o));

if incident_rad >= 125
    power_generated = high_power;
else
    power_generated = low_power;
end

%% Módulo de Inversor & Módulo de Pérdidas

%power_out = efficiency*power_generated;
power_out = 1.4327*power_generated^3 - 1.5697*power_generated^2 + 0.6165*power_generated - 0.0005;

end

% glb [W/m2]: Radiación Global
% dir [W/m2]: Radiación Directa
% dif [W/m2]: Radiación Difusa
% sct [W/m2]: Radiación Difusa Relejada
% ghi [W/m2]: Radiación Global Horizontal
% dirh [W/m2]: Radiación Directa
% difh [W/m2]: Radiación Difusa
% dni [W/m2]: Radiación Directa Normal
% temp [C]: Temperatura en 2 metros (correjida)
% vel [m/s]: Velocidad de Viento
% shadow [0: sin, 1: con]: Sobra debido a topografía
% cloud [1: si, 0: no]: Presencia de nubes