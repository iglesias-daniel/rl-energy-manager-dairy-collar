%SETUP Prepare the MATLAB workspace for training / evaluating the agents.
%
%   Run this script from matlab/masters before train_agents.m,
%   evaluate_agents.m or evaluate_best_worst_week.m.
%
%   It loads:
%     - hourly solar radiation and wind for Maquehue (Explorador Solar)
%     - the Sun position vectors for Maquehue
%     - the collar orientation data (g_30dias, m_30dias) obtained from
%       collars worn by dairy cows at Predio Maquehue (April 2024)
%   and defines `comb`, the observation subsets used by agents 1..15.
%
%   Requires: MATLAB R2024b+, Simulink, Reinforcement Learning Toolbox,
%             Deep Learning Toolbox.

here = fileparts(mfilename("fullpath"));
addpath(here);
addpath(fullfile(here, "..", "common", "sun-position"));
addpath(fullfile(here, "..", "common", "orientation"));

import_weather_data;
load(fullfile(here, "..", "..", "data", "orientation", "magne_aceler_better.mat"));

%% Combinaciones
comb = cell(16, 1);

comb{1}  = [4];
comb{2}  = [3];
comb{3}  = [3 4];
comb{4}  = [2];
comb{5}  = [2 4];
comb{6}  = [2 3];
comb{7}  = [2 3 4];
comb{8}  = [1];
comb{9}  = [1 4];
comb{10} = [1 3];
comb{11} = [1 3 4];
comb{12} = [1 2];
comb{13} = [1 2 4];
comb{14} = [1 2 3];
comb{15} = [1 2 3 4];
comb{16} = [];

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

disp("Setup listo :D")
