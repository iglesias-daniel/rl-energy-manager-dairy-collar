clc

% Coordenadas del Campo Experimental Maquehue
Lat = -38.84;         % [degrees]
Long = -72.70;       % [degrees]

% Time-stamp en UT [Year, Month, Day, Hour, Minute, Second]

%Horas del dia
hour = (1:24)';

%Dias por mes
day28 = (1:28)';
day28 = repelem(day28,24); %Dia por hora
day30 = (1:30)';
day30 = repelem(day30,24);
day31 = (1:31)';
day31 = repelem(day31,24);

%Dias del año
day = [day31;day28;day31;
    day30;day31;day30;
    day31;day31;day30;
    day31;day30;day31];

%Meses del año
month = [repmat([1],31,1);repmat([2],28,1);repmat([3],31,1);
    repmat([4],30,1);repmat([5],31,1);repmat([6],30,1);
    repmat([7],31,1);repmat([8],31,1);repmat([9],30,1);
    repmat([10],31,1);repmat([11],30,1);repmat([12],31,1)];

%Meses por hora
month = repelem(month,24);

temp = ones(size(day));

%Time stamp para 2023
TS = [2023*temp, month, day, repmat(hour,365,1), 0*temp, 0*temp];

% Example 1: call function to evaluate sun position - using default coefficients
SP = sunpos(TS, Lat, Long);

%Vector solar (apunta hacia el sol)
SP.SunVec