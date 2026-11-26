library(TOSTER)
library(boot)

#TOSTER

delta <- 0.01 # Diferencia de 1% en la batería


agentes <- unique(data$Agent)

for (a in agentes) {
  # Filtrar datos del agente
  subset_data <- subset(data, Agent == a)
  diffs <- subset_data$Diff_day
  diffs <- na.omit(diffs)
  
  if (length(diffs) < 5) {
    cat("⚠️ Agente", a, "tiene pocos datos (n =", length(diffs), "), se omite.\n\n")
    next
  }
  
  cat("🔹 Agente:", a, "\n")
  
  tost_result <- wilcox_TOST(
    x = subset_data$Batt_initial,
    y = subset_data$Batt_end_day,
    paired = TRUE,
    eqb = delta,
    eqbound_type = "raw",
    alpha = 0.05
  )
  
  
  cat("  TOST Wilcoxon:\n")
  cat("    p (Lower):", round(tost_result$TOST$p.value[2], 4), "\n")
  cat("    p (Upper):", round(tost_result$TOST$p.value[3], 4), "\n")
  if (all(tost_result$TOST$p.value < 0.05)) {
    cat("    ✅ Equivalencia confirmada (Wilcoxon TOST)\n")
  } else {
    cat("    ❌ No se puede confirmar equivalencia (Wilcoxon TOST)\n")
  }
  
  ## --- 2. Bootstrap IC de la mediana ---
  median_boot <- function(data, indices) {
    median(data[indices], na.rm = TRUE)
  }
  
  set.seed(123 + as.integer(a))  # Para reproducibilidad individual por agente
  boot_results <- boot(diffs, statistic = median_boot, R = 10000)
  boot_ci <- boot.ci(boot_results, conf = 0.90, type = "bca")
  
  ic_low <- round(boot_ci$bca[4], 5)
  ic_high <- round(boot_ci$bca[5], 5)
  
  cat("  Bootstrap IC 90% (mediana de la diferencia):\n")
  cat("    [", ic_low, ",", ic_high, "]\n")
  if (ic_low > -delta && ic_high < delta) {
    cat("    ✅ Equivalencia confirmada (Bootstrap IC)\n\n")
  } else {
    cat("    ❌ No se puede confirmar equivalencia (Bootstrap IC)\n\n")
  }
  
  
}