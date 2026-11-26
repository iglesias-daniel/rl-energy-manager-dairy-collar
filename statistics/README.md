# Statistical analysis

Tests whether each energy manager achieves Energy Neutral Operation. The test
checks that the battery level at the end of the deployment is **equivalent**
to the target level within ±1 % (δ = 0.01). Normality could not be assumed,
so two non-parametric methods are used:

- Paired **Wilcoxon TOST** ([TOSTER](https://cran.r-project.org/package=TOSTER)), α = 0.05
- **Bootstrap BCa 90 % CI** of the median difference ([boot](https://cran.r-project.org/package=boot)), 10 000 resamples

## Scripts (`scripts/`)

| Script | Horizon | Input columns |
|---|---|---|
| `TOST_boot_batt_day.R` | 1 day | `Batt_initial`, `Batt_end_day`, `Diff_day` |
| `TOST_boot_batt_week.R` | 1 week | `Batt_initial`, `Batt_end_week`, `Diff_week` |
| `TOST_boot_batt_month.R` | 1 month | `Batt_initial_ec`, `Batt_end_day`, `Diff_day_corre` |
| `una_var.R` | 1 month, agent 15 only | `preresultados_bat_agente15` |
| `metrics_per_agent_graph.R` | — | Mean/SD/min/max battery difference per agent |

The scripts expect a data frame called `data` to already be loaded, for
example:

```r
library(readxl)
data <- read_excel("results/Resultados_exp_219_correcto.xlsx")
source("scripts/TOST_boot_batt_day.R")
```

## Results (`results/`)

- `Resultados_exp_219_correcto.xlsx` and `Resultados_extendidos.xlsx`:
  per-run results of the model-based evaluation of all 15 agents. Columns
  give the agent, season, initial battery, cumulative reward, battery
  difference, and so on.
- `preresultados_bat_agente15.*`: battery results for agent 15.
- `*.mat`: raw outputs of `evaluate_agents.m`.
