# Collar firmware (EMSRL)

Arduino firmware deployed on the monitoring collar used in the paper.

## Hardware

- **MCU:** Heltec Automation Wireless Tracker (ESP32-S3, SX1262 LoRa, UC6580 GNSS)
- **IMU:** TDK ICM-42670-P on I2C (SDA = GPIO 26, SCL = GPIO 21, INT1 = GPIO 48, address 0x69)
- **Power:** Li-ion battery, flexible solar panel

## What it does

The device spends most of its time in deep sleep. Each 10 s work cycle wakes
the device, reads the IMU FIFO and classifies behaviour with a linear SVM into
4 classes (grazing, walking, resting and other). Once per hour it runs the
**energy manager**:

1. Builds the 6 observations: battery level, target battery level,
   panel–Sun alignment, forecast radiation for the hour, forecast mean daily
   radiation, and hour of day.
2. Evaluates the TD3 actor network (`pesos_capa1`, `bias_capa1`,
   `pesos_capa2`, `bias_capa2`, `pesos_salida`, `bias_salida`), using ReLU,
   saturation and scaling (`0.45·x + 0.55`).
3. Converts the 3 outputs into `w_int` (duty cycle, 4–36 work interrupts per
   hour), `tx_max` (LoRaWAN uplinks per hour) and `gps_max` (GNSS fixes per
   hour).

Each uplink is a 24-byte LoRaWAN frame. It carries the battery level, target
level, GPS count, behaviour counts, orientation, day, active policy, GPS date
and position.

## Building

1. Install Arduino IDE (2.3.4 was used) and the **Heltec ESP32** board package.
   It provides `LoRaWan_APP.h` and `HT_TinyGPS++.h`.
2. Select the board *Wireless Tracker* and the LoRaWAN region of your network
   (AU915 in Chile) in the *Tools* menu.
3. Copy `EMSRL/secrets.example.h` to `EMSRL/secrets.h` and fill in your
   LoRaWAN credentials. `secrets.h` is git-ignored.
4. Compile and upload.

## Per-deployment configuration

Some values are set by hand before each deployment:

| Variable | Meaning |
|---|---|
| `radiacion_por_hora[15][24]` | Hourly radiation forecast (W/m²) for the 15 days of the deployment |
| `orientacion_solar[15][24]` | Sun vertical component for those days (from `matlab/common/sun-position`) |
| `dia_del_mes_inicio`, `max_dia_mes` | Start day of the deployment and length of that month |
| `bateria_actual`, `bateria_deseada` | Initial and target battery level (0–1) |
| `FACTOR_MULTIPLICADOR` | ADC to battery-voltage factor, calibrated per board |

## Replacing the agent

Export the actor of a trained agent with `matlab/export_actors.m`. Then copy
the arrays from `agentNN_weights.json` into the six weight/bias arrays.
MATLAB stores fully-connected weights as `[outputs × inputs]`, which is the
same layout the firmware uses.
