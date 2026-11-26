# Reinforcement Learning Energy Manager for a Low-Power IoT Collar Worn by Dairy Cows

Code, models, data and documents from my undergraduate and master's theses
(Universidad de La Frontera, Temuco, Chile, 2024–2025). Both theses cover the
same topic: an **energy manager (EM) based on reinforcement learning** for a
wearable IoT collar with **solar energy harvesting**, used in Precision
Livestock Farming.

The EM looks at the battery level, the orientation of the collar, the weather
forecast and the time of day. From these it sets three things every hour: the
monitoring duty cycle, the number of LoRaWAN transmissions and the number of
GPS fixes. The goal is **Energy Neutral Operation (ENO)**. The agent is trained
with **TD3** in MATLAB/Simulink, and its actor network (2 × 11 neurons,
≤ 256 learnables) runs on an **ESP32-S3** (Heltec Wireless Tracker) worn by
dairy cows at Predio Maquehue.

> 🇪🇸 **Resumen:** Repositorio de mi trabajo de título (pregrado) y tesis de
> magíster: un gestor de energía basado en aprendizaje por refuerzo (TD3) para
> un collar IoT con panel solar para vacas de lechería. Incluye el entorno de
> simulación en Simulink, los agentes entrenados, el firmware para ESP32-S3,
> el análisis estadístico (TOST) en R y la presentación de defensa.

## Publications

- **D. Iglesias and C. Muñoz-Poblete**, "Energy Manager Based on Reinforcement
  Learning for a Low-Power IoT Collar Worn by Dairy Cows", *IEEE Internet of
  Things Journal*, vol. 12, no. 16, pp. 34374–34391, 2025.
  doi: [10.1109/JIOT.2025.3577898](https://doi.org/10.1109/JIOT.2025.3577898)
  · [IEEE Xplore](https://ieeexplore.ieee.org/document/11028906/)
  — *the master's thesis work (15 TD3 agents, TOST validation, real
  deployment).*
- **D. Iglesias and C. Muñoz**, "Reinforcement Learning Applied in Energy
  Management in Wearable IoT with Energy Harvesting", *2024 IEEE ICA-ACCA*,
  pp. 1–6, 2024. [IEEE Xplore](https://ieeexplore.ieee.org/document/10766823/)
  — *the undergraduate thesis work (TD3 vs PPO vs SAC).*

**If you use any part of this repository, you must cite the IEEE Internet of
Things Journal article above** (see [`LICENSE`](LICENSE) and
[`CITATION.cff`](CITATION.cff)).

```bibtex
@article{iglesias2025energy,
  author  = {Iglesias, Daniel and Mu{\~n}oz-Poblete, Carlos},
  title   = {Energy Manager Based on Reinforcement Learning for a Low-Power
             {IoT} Collar Worn by Dairy Cows},
  journal = {IEEE Internet of Things Journal},
  year    = {2025},
  volume  = {12},
  number  = {16},
  pages   = {34374--34391},
  doi     = {10.1109/JIOT.2025.3577898}
}
```

## Repository layout

```
├── docs/
│   └── presentations/      Master's thesis defense (2025, Spanish)
├── matlab/
│   ├── masters/            Paper code: setup, training, evaluation (model8)
│   │   ├── models/         Simulink environments (training / evaluation)
│   │   ├── agents/         Actor networks of the 15 trained TD3 agents
│   │   ├── baselines/      RLMan, tinyMAN and PPO comparisons
│   │   └── plots/          Figure scripts
│   ├── undergrad/          ICA-ACCA code: TD3 vs PPO vs SAC (model6)
│   ├── common/             Sun position algorithm and collar orientation
│   └── export_actors.m     Extracts actors / weights from trained agents
├── firmware/EMSRL/         Arduino firmware for the Heltec Wireless Tracker
├── statistics/             R scripts (TOST + bootstrap) and evaluation results
└── data/                   Weather data, orientation data, field measurements
```

## Quick start (simulation)

Requirements: MATLAB R2024b or newer, Simulink, Reinforcement Learning
Toolbox, and Deep Learning Toolbox. The paper used R2024b. The actors were
exported with R2025b.

```matlab
cd matlab/masters
setup                      % loads weather, Sun position and orientation data
evaluate_agents            % evaluates agent 15 (the deployed one) over 1 year of start days
```

- To evaluate another agent, change `for n_ag = 15` in `evaluate_agents.m`.
  `load_agent.m` rebuilds a full `rlTD3Agent` from the exported actor in
  `agents/agentNN_actor.mat`.
- To retrain the 15 agents from scratch, run `train_agents.m` after `setup`.
  This takes about 10 000 episodes per agent. The agents are saved in
  `Agente<i>_245learn_6input_try2_1e5/`, and `load_agent` uses those first
  when they are present.
- `agents/agentNN_weights.json` holds the weights and biases of each actor in
  plain numbers. This is how the network is moved into the firmware
  (`pesos_capa1`, `bias_capa1`, … in `EMSRL.ino`).

### Agents and observations

All agents observe the current battery level `BL` and the target battery level
`BT`. They differ in which of the following they also observe (Table III of
the paper): `Odot` (alignment between the solar panel and the Sun), `Gh`
(forecast radiation for the next hour), `Gday` (forecast mean daily
radiation) and `t` (hour of day). The subsets are defined in `comb` in
`setup.m`. **Agent 15** uses all six observations and got the best one-month
average reward.

The collars run `agents/agent15_deployed_*`. This is another training run of
the same agent 15 configuration (245 learnables). Its weights are the ones in
`firmware/EMSRL/EMSRL.ino`.

## Firmware

[`firmware/EMSRL/EMSRL.ino`](firmware/EMSRL/) is the Arduino program deployed
on the collar. It contains the energy manager (the TD3 actor running as plain
C), an SVM behaviour classifier fed by an ICM-42670-P IMU, LoRaWAN
communication and GNSS. See [`firmware/README.md`](firmware/README.md).

## Statistical analysis

[`statistics/`](statistics/) contains the R scripts for the Wilcoxon TOST
equivalence test and the bootstrap confidence intervals. They test whether
each agent keeps the battery within ±1 % of its target over one day, one week
and one month. The simulation results they read are in
`statistics/results/`.

## Data

See [`data/README.md`](data/README.md) for sources and licences. In short:
the hourly radiation data comes from the Explorador Solar of the Chilean
Ministry of Energy. The orientation data is the processed accelerometer data
from collars worn by three cows (April 2024). The solar harvesting and power
logs were measured with the prototype.

The raw IMU recordings and the LoRaWAN messages from the field deployment
are **not** included.

## Licence

Everything by the author is under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (see
[`LICENSE`](LICENSE)). You can use, modify and redistribute it for any
purpose, including commercially, **as long as you cite the article above**.

Third-party material:
- `matlab/common/sun-position/sunpos.m` is © A. Bonanos (BSD licence, see
  `license.txt`).
- Explorador Solar data: © Ministerio de Energía de Chile.

## About this repository

The material in this repository was gathered and organized from the original
thesis files with the help of **Claude Opus 5.5** (Anthropic). That includes
picking the final versions, extracting the actors, removing credentials and
writing the documentation. It **may contain errors**. If something does not
match the article, the published article is the reference. Please open an
issue if you find a problem.

## Acknowledgements

This research was funded by ANID – Fondecyt Regular Project 1220178 and Basal
funding for the Scientific and Technological Center of Excellence IMPACT,
#FB210024. The master's studies were funded by ANID Subdirección de Capital
Humano / Magíster Nacional / 202422241455. Supervisor: Dr. Carlos
Muñoz-Poblete, Departamento de Ingeniería Eléctrica, Universidad de La
Frontera.
