%% Import data of solar position
dataDir = fullfile(fileparts(mfilename("fullpath")), "..", "..", "data", "weather");
sol = load(fullfile(dataDir, "SP_Maquehue_2023_vector.mat"));

%% Import data from text file (radiation)
opts = delimitedTextImportOptions("NumVariables", 13);
opts.DataLines = [43, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["FechaHora", "glb", "dir", "dif", "sct", "ghi", "dirh", "difh", "dni", "temp", "vel", "shadow", "cloud"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "FechaHora", "InputFormat", "yyyy-MM-dd HH:mm:ss", "DatetimeFormat", "preserveinput");
radiation = readtable(fullfile(dataDir, "explorador_solar_maquehue_hourly_2004-2016.csv"), opts);
clear opts

%% Extract variables

n = 113952; % Number of hours
hora = [1:n]';
m = 8760; % Number of hours


glb = radiation.glb(1:n);
glb = [hora, glb];
dni = radiation.dni(1:n);
dni = [hora, dni];
difh = radiation.difh(1:n);
difh = [hora, difh];
ghi = radiation.ghi(1:n);
ghi = [hora, ghi];
viento = radiation.vel(1:n);
viento = [hora, viento];

% g = [collar.MPU9250_ax(1:n), collar.MPU9250_ay(1:n), collar.MPU9250_az(1:n)];
% g = [hora, g];
% m = [collar.MPU9250_mx(1:n), collar.MPU9250_my(1:n), collar.MPU9250_mz(1:n)];
% m = [hora, m];

sun_vector = circshift(sol.SunVec2023,-3); %Correccion horaria
% 1 -> 00:00:00 hora Chile UTC-4

sun_vector = vertcat(sun_vector, sun_vector(1,:)); 
%Se añadió un dato más para evitar errores en la simulación

%sun_vector = sol.SunVec2023(4:m+3,1:3);
%sun_vector = [hora, sun_vector];

disp("Datos cargados :D")
