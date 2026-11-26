library(TOSTER)

#TOSTER

delta <- 0.01 # Diferencia de 1% en la batería

subset_data <- preresultados_bat_agente15

res <- wilcox_TOST(
  x = subset_data$battery_initial,
  y = subset_data$final_month,
  paired = TRUE,
  eqb = delta,
  eqbound_type = "raw",
  conf.level = 0.90
)

print(res)

#IC

print(boot_ci)

library(boot)

median_boot <- function(data, indices) {
  median(data[indices], na.rm = TRUE)
}

set.seed(123)
boot_results <- boot(subset_data$diff_month, statistic = median_boot, R = 10000)
boot_ci <- boot.ci(boot_results, conf = 0.90, type = "bca")
print(boot_ci$bca[4:5])  # Límites BCa del 90%

