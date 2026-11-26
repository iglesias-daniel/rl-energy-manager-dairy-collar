recortado = glb(1 : floor(n/168)*168,2);
bloques = reshape(recortado, 168, []);  % Cada columna es una semana
suma_semanal = sum(bloques);           % Suma por columna (una por semana)
suma_semanal = suma_semanal';          % Lo pasás a columna si querés
