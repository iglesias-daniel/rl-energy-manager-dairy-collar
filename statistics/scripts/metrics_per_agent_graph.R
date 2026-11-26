# Crear columna con las diferencias
#preresultados_bat$diff <- preresultados_bat$final_month - preresultados_bat$battery_initial

# Obtener los agentes únicos
agentes <- unique(data$Agent)

# Crear un data frame vacío para guardar resultados
resumen <- data.frame(
  agent = character(),
  media = numeric(),
  sd = numeric(),
  min = numeric(),
  max = numeric(),
  n = integer(),
  stringsAsFactors = FALSE
)

# Calcular métricas por agente
for (a in agentes) {
  subset_data <- subset(data, Agent == a)
  diffs <- na.omit(subset_data$ai_month)
  
  resumen <- rbind(resumen, data.frame(
    agent = a,
    media = mean(diffs),
    sd = sd(diffs),
    min = min(diffs),
    max = max(diffs),
    n = length(diffs)
  ))
}

# Mostrar la tabla
print(resumen)

resumen <- subset(resumen, !(agent %in% c("3", "4", "7", "8")))

library(ggplot2)

ggplot(resumen, aes(x = factor(agent), y = media)) +
  scale_y_continuous(breaks = seq(-0.05, 0.1, by = 0.005)) +
  geom_point(color = "blue", size = 3, shape = 16) +   # barra con la media
  geom_errorbar(aes(ymin = media - sd, ymax = media + sd),
                width = 0.2, color = "blue") +  # desviación estándar
  geom_point(aes(y = min), color = "red", shape = 17, size = 2) +  # mínimo
  geom_point(aes(y = max), color = "darkgreen", shape = 18, size = 2) +  # máximo
  labs(title = "Battery Difference",
       x = "Agent", y = "Battery difference (month)") +
  theme_minimal()

