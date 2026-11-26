% Generar datos de ejemplo
% FechaHora = [
%     "20/12/2024 23:21:00";
%     "20/12/2024 23:28:00";
%     "20/12/2024 23:34:00";
%     "20/12/2024 23:40:00";
%     "20/12/2024 23:46:00";
%     "20/12/2024 23:52:00";
%     "20/12/2024 23:58:00";
%     "21/12/2024 00:04:00"
% ];

FechaHora = [
    "21/12/2024 18:40:00";
    "21/12/2024 19:46:00";
    "21/12/2024 20:46:00";
    "21/12/2024 21:53:00";
    "21/12/2024 22:53:00";
    "21/12/2024 23:53:00";
    "22/12/2024 00:53:00";
    "22/12/2024 01:54:00";
    "22/12/2024 02:54:00";
    "22/12/2024 03:54:00";
    "22/12/2024 04:54:00";
    "22/12/2024 05:54:00";
    "22/12/2024 06:54:00"
];


% Convertir las fechas y horas a formato datetime
fecha = datetime(FechaHora, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');

var1 = [0.42, 0.44, 0.44, 0.41, 0.42, 0.42, 0.44, 0.44, 0.44, 0.44, 0.44, 0.44, 0.44]; % Variable 1
var2 = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];  % Variable 2
var3 = [1 1 1 1 1 1 1 1 1 1 1 1 1];  % Variable 3
var4 = [1 1 1 1 1 1 1 1 1 1 1 1 1];  % Variable 4
var5 = [3 3 3 3 3 3 3 3 3 3 3 3 3];  % Variable 5


% Crear layout
tiledlayout(2, 1); % Dos gráficos, uno encima del otro

% Gráfico superior
nexttile;
plot(fecha, var1, '-o', 'DisplayName', 'Current Battery Level'); hold on;
plot(fecha, var2, '-x', 'DisplayName', 'Target Battery Level');
ylabel('Battery Level');
xlabel('Date (UTC)');
ylim([0.4 0.6])
title('Gráfico superior: Variable 1 y Variable 2');
legend;
grid on;

% Gráfico inferior
nexttile;
yyaxis left;
plot(fecha, var3, '-s', 'DisplayName', 'n_{tx}'); hold on;
plot(fecha, var4, '-^', 'DisplayName', 'n_{GPS}');
ylabel('Variables 3 y 4');
ylim([0 3])
yyaxis right;
plot(fecha, var5, '-d', 'DisplayName', 'n_{D}');
ylabel('Variable 5');
ylim([1 6])
title('Gráfico inferior');
legend;
grid on;

% Ajustar el eje x compartido
xlabel('Fecha');
