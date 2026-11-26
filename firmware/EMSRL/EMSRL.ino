#include <Wire.h>
#include <math.h>
#include "HT_TinyGPS++.h"
#include "LoRaWan_APP.h"
#include "Arduino.h"
#include "esp_task_wdt.h"

#define FACTOR_MULTIPLICADOR 0.004116

/* ****** Configuración de LoRaWAN ****** */
#define LORAWAN_DEVEUI_AUTO 1
uint8_t devEui[8];

// Las credenciales LoRaWAN (appEui, appKey, nwkSKey, appSKey, devAddr)
// se definen en secrets.h, que no se sube al repositorio.
// Copiar secrets.example.h -> secrets.h y completar con los valores
// de su servidor de red (ChirpStack, TTN, etc.).
#include "secrets.h"
uint16_t userChannelsMask[6]={ 0x00FF,0x0000,0x0000,0x0000,0x0000,0x0000 };
LoRaMacRegion_t loraWanRegion = ACTIVE_REGION;
DeviceClass_t  loraWanClass = CLASS_A;
//uint32_t appTxDutyCycle = 15000;
//uint32_t appTxDutyCycle = 5000;
uint32_t appTxDutyCycle = 10000;

bool overTheAirActivation = true;
bool loraWanAdr = false; // Esto es para que cambie la potencia dinámicamente
bool isTxConfirmed = true; 
uint8_t appPort = 2;
uint8_t confirmedNbTrials = 100;

RTC_DATA_ATTR bool send_mode = false;
RTC_DATA_ATTR int send_message = 0;
RTC_DATA_ATTR int8_t contador = 0;
RTC_DATA_ATTR bool first_communication = true;
RTC_DATA_ATTR bool first_ejecution = true;

/* ****** Configuración del ICM ****** */
#define SDA_PIN 26 // PIN SDA con el ICM
#define SCL_PIN 21 // PIN SCL con el ICM
#define GPIO_INT1_PIN 48 // Pin de interrupción del ICM
#define ICM42670_ADDR 0x69 // Dirección I2C del ICM
#define WHO_AM_I_REG  0x75 // Registro con el Chip ID
#define ACCEL_DATA_START 0x0B // Registro con datos acelerómetro
#define GYRO_DATA_START 0x11 // Registro con datos giroscopio
#define MADDR_W 0x7A // 7-0: MADDR_W
#define M_W 0x7B // 7-0: M_W
#define FIFO_CONFIG1 0x28 // 1: FIFO_MODE | 0: FIFO_BYPASS
#define FIFO_CONFIG2 0x29 // 7-0: FIFO_WM[7:0]
#define FIFO_CONFIG3 0x2A // 3-0: FIFO_WM[11:8]
#define FIFO_CONFIG5 0x01 // 5: FIFO_WM_GT_TH | 4: FIFO_RESUME_PARTIAL_RD | 3: FIFO_HIRES_EN | 2: FIFO_TMST_FSYNC_EN | 1: FIFO_GYRO_EN | 0: FIFO_ACCEL_EN
#define SENSOR_CONFIG3 0x06 // 6: APEX_DISABLE
#define INT_SOURCE0 0x2B // 7: ST_INT1_EN | 6: FSYNC_INT1_EN | 5: PLL_RDY_INT1_EN | 4: RESET_DONE_INT1_EN | 3: DRDY_INT1_EN | 2: FIFO_THS_INT1_EN | 1: FIFO_FULL_INT1_EN | 0: AGC_RDY_INT1_EN
#define INT_CONFIG 0x06 // 5: INT2_MODE | 4: INT2_DRIVE_CIRCUIT | 3: INT2_POLARITY | 2: INT1_MODE | 1: INT1_DRIVE_CIRCUIT | 0: INT1_POLARITY 
#define INT_CONFIG1 0x05 // 6: INT_TPULSE_DURATION | 4: INT_ASYNC_RESET
#define PWR_MGMTO 0x1F // 7: ACCEL_LP_CLK_SEL | 4: IDLE | 3-2: GYRO_MODE | 1-0: ACCEL_MODE
#define GYRO_CONFIG0 0x20 // 6-5: GYRO_UI_FS_SEL | 2-0: GYRO_ODR
#define ACCEL_CONFIG0 0x21 // 6-5: ACCEL_UI_FS_SEL | 2-0: ACCEL_ODR
#define FIFO_DATA 0X3F
#define CONFIG_250dps_12_5HZ 0x0C
#define GYRO_AND_ACCE_CONFIG 0x0F // 0000_1111

/* ****** Configuración del GPS ****** */
#define VGNSS_CTRL 3
TinyGPSPlus GPS;
RTC_DATA_ATTR int8_t gps_hour[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
RTC_DATA_ATTR int8_t gps_minute[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
RTC_DATA_ATTR int8_t gps_second[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
RTC_DATA_ATTR float gps_latitud[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
RTC_DATA_ATTR float gps_longitud[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
RTC_DATA_ATTR int8_t cgps_buffer = 0;

/* ****** Configuracion del clasificador SVM ****** */
#define CANTIDAD_MUESTRAS 50
#define NUM_VARIABLES 6
#define NUM_FEATURES 15
#define NUM_CLASSES 4
float ax[CANTIDAD_MUESTRAS], ay[CANTIDAD_MUESTRAS], az[CANTIDAD_MUESTRAS];
float gx[CANTIDAD_MUESTRAS], gy[CANTIDAD_MUESTRAS], gz[CANTIDAD_MUESTRAS];
float acc_vec[CANTIDAD_MUESTRAS], gyro_vec[CANTIDAD_MUESTRAS];
float caracteristicas[NUM_FEATURES];
RTC_DATA_ATTR int8_t clasificacion[NUM_CLASSES] = {0,0,0,0};
RTC_DATA_ATTR float coeficientes[NUM_CLASSES][NUM_FEATURES] = {
    {2.05527632, -0.87719323, -0.86180532, 0.325443, 0.65772962, 
     -1.29883846, -1.5782774, 3.7219453, -3.19157424, 0.635154,
     -0.35145158, -0.21372065, 0.16585798, 0.01509077, 0.15399717},
    {0.17706689, 0.00916506, -0.7038753, -0.71650515, -0.82321324, 
     2.95084197, 2.7852281, -0.9473913, 1.77176526, -1.35230943,
     0.06459088, -0.0024537, 0.05486796, 0.05395042, -0.15786159},
    {4.244685, -4.1010386, 0.19362461, 1.40402108, 3.09615629, 
     0.07292275, -0.86671172, -11.5162979, 3.07995049, -2.13315979,
     0.12165819, -1.40919359, -0.7767148, -1.71532326, 0.46703865},
    {-2.47065241, 2.14839084, 0.2245637, -0.82932846, -0.48946635, 
     -2.94888505, -0.19026128, -2.58038259, 2.60971736, 0.64415658,
     -0.11535092, 0.78178481, 0.65805897, 0.49921102, -0.76840732}
};
RTC_DATA_ATTR float interceptos[NUM_CLASSES] = {
    -1.5037309586352434,
    -1.9603461533867783,
    -6.774951004932157,
    -2.7798724667875794
};

/* ****** Configuración del EMS ****** */
RTC_DATA_ATTR float orientacion_collar = 1; // eje cenit

#define ADC_Ctrl 2
#define ADC_IN 1

//RTC_DATA_ATTR 
float orientacion_solar[15][24] = {
  {-0.141570704, -0.283151533, -0.388486411, -0.450402829, -0.464684890, -0.430360185, -0.349765917, -0.228389797, -0.074496515, 0.101434836, 0.287424141, 0.470805955, 0.639091989, 0.780821676, 0.886342872, 0.948469440, 0.962970885, 0.928860602, 0.848463072, 0.727255416, 0.573494123, 0.397652449, 0.211706872, 0.028321281},
  {-0.140015501, -0.281840105, -0.387495032, -0.449786026, -0.464471691, -0.430552125, -0.350336925, -0.229287984, -0.075647730, 0.100121916, 0.286051743, 0.469480187, 0.637915551, 0.779886806, 0.885724999, 0.948222001, 0.963121646, 0.929409745, 0.849383181, 0.728493355, 0.574974686, 0.399283526, 0.213385777, 0.029941807},
  {-0.138555788, -0.280632825, -0.386614703, -0.449284938, -0.464376319, -0.430861303, -0.351021924, -0.230294480, -0.076899530, 0.098717643, 0.284598093, 0.468083444, 0.636677881, 0.778899237, 0.885061167, 0.947933080, 0.963232833, 0.929918523, 0.850259486, 0.729681643, 0.576397745, 0.400847784, 0.214987727, 0.031475121},
  {-0.137192957, -0.279530846, -0.385846260, -0.448900036, -0.464398849, -0.431287399, -0.351820226, -0.231408281, -0.078250671, 0.097223411, 0.283064640, 0.466617120, 0.635380218, 0.777859968, 0.884352056, 0.947602992, 0.963304368, 0.930386464, 0.851091153, 0.730819135, 0.577761923, 0.402343701, 0.216511160, 0.032919722},
  {-0.135928347, -0.278535256, -0.385190468, -0.448631712, -0.464539279, -0.431830018, -0.352731073, -0.232628322, -0.079699855, 0.095640660, 0.281452857, 0.465082626, 0.634023807, 0.776769988, 0.883598332, 0.947232029, 0.963336150, 0.930813077, 0.851877332, 0.731904682, 0.579065844, 0.403769773, 0.217954540, 0.034274151},
  {-0.134763246, -0.277647081, -0.384648025, -0.448480287, -0.464797529, -0.432488691, -0.353753636, -0.233953476, -0.081245734, 0.093970864, 0.279764249, 0.463481384, 0.632609895, 0.775630280, 0.882800648, 0.946820467, 0.963328057, 0.931197855, 0.852617163, 0.732937130, 0.580308141, 0.405124512, 0.219316362, 0.035536989},
  {-0.133698886, -0.276867283, -0.384219553, -0.448446002, -0.465173445, -0.433262873, -0.354887021, -0.235382554, -0.082886908, 0.092215539, 0.278000340, 0.461814830, 0.631139727, 0.774441819, 0.881959639, 0.946368562, 0.963279949, 0.931540271, 0.853309773, 0.733915320, 0.581487454, 0.406406449, 0.220595156, 0.036706865},
  {-0.132736441, -0.276196756, -0.383905605, -0.448529026, -0.465666794, -0.434151946, -0.356130264, -0.236914312, -0.084621932, 0.090376234, 0.276162682, 0.460084410, 0.629614551, 0.773205569, 0.881075924, 0.945876548, 0.963191665, 0.931839783, 0.853954279, 0.734838093, 0.582602430, 0.407614139, 0.221789482, 0.037782452},
  {-0.131877030, -0.275636331, -0.383706659, -0.448729448, -0.466277269, -0.435155221, -0.357482335, -0.238547444, -0.086449314, 0.088454533, 0.274252843, 0.458291580, 0.628035611, 0.771922483, 0.880150106, 0.945344640, 0.963063023, 0.932095830, 0.854549787, 0.735704290, 0.583651729, 0.408746157, 0.222897941, 0.038762475},
  {-0.131121712, -0.275186769, -0.383623121, -0.449047284, -0.467004486, -0.436271935, -0.358942138, -0.240280592, -0.088367516, 0.086452050, 0.272272415, 0.456437801, 0.626404147, 0.770593503, 0.879182769, 0.944773034, 0.962893822, 0.932307838, 0.855095395, 0.736512752, 0.584634023, 0.409801108, 0.223919168, 0.039645705},
  {-0.130471486, -0.274848762, -0.383655320, -0.449482470, -0.467847984, -0.437501253, -0.360508514, -0.242112342, -0.090374960, 0.084370431, 0.270223005, 0.454524541, 0.624721397, 0.769219557, 0.878174479, 0.944161904, 0.962683843, 0.932475218, 0.855590195, 0.737262322, 0.585547998, 0.410777618, 0.224851839, 0.040430966},
  {-0.129927288, -0.274622933, -0.383803513, -0.450034868, -0.468807230, -0.438842273, -0.362180240, -0.244041227, -0.092470023, 0.082211352, 0.268106237, 0.452553271, 0.622988589, 0.767801559, 0.877125784, 0.943511404, 0.962432847, 0.932597365, 0.856033271, 0.737951850, 0.586392357, 0.411674346, 0.225694671, 0.041117135},
  {-0.129489992, -0.274509834, -0.384067881, -0.450704262, -0.469881613, -0.440294018, -0.363956034, -0.246065729, -0.094651046, 0.079976512, 0.265923746, 0.450525467, 0.621206945, 0.766340409, 0.876037212, 0.942821667, 0.962140577, 0.932673665, 0.856423705, 0.738580188, 0.587165820, 0.412489980, 0.226446424, 0.041703145},
  {-0.129096469, -0.274527968, -0.384560627, -0.451702245, -0.471381032, -0.442256914, -0.366312902, -0.248720296, -0.097486886, 0.077087984, 0.263114436, 0.447921546, 0.618920182, 0.764460495, 0.874625597, 0.941907346, 0.961718100, 0.932703520, 0.856835036, 0.739275673, 0.588028363, 0.413390761, 0.227253754, 0.042291507},
  {-0.128901732, -0.274669286, -0.385085754, -0.452632787, -0.472710970, -0.443953025, -0.368317043, -0.250953402, -0.099854403, 0.074689601, 0.260790614, 0.445772349, 0.617033443, 0.762905776, 0.873449419, 0.941129996, 0.961332237, 0.932674689, 0.857104041, 0.739762651, 0.588638276, 0.414019931, 0.227796985, 0.042649318}
}; // eje cenit

//RTC_DATA_ATTR 
float radiacion_por_hora[15][24] = {
 //0, 0, 0, 0, 0, 0, 6,  7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,21,22,23
  {0, 0, 0, 0, 0, 0, 0,  0,  67, 266, 476, 663, 810, 904, 939, 913, 827, 688, 505, 297,  92, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  53, 262, 473, 660, 806, 901, 936, 910, 824, 684, 502, 287,  88, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  61, 253, 448, 635, 803, 898, 933, 907, 821, 672, 492, 288,  85, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  58, 255, 466, 653, 800, 894, 929, 900, 817, 678, 495, 286,  82, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  55, 251, 462, 649, 797, 891, 927, 901, 814, 674, 491, 283,  79, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  52, 248, 458, 646, 793, 888, 924, 897, 811, 671, 488, 279,  76, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  50, 244, 455, 642, 790, 885, 920, 894, 807, 667, 484, 275,  73, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  46, 240, 451, 639, 786, 881, 917, 890, 803, 663, 480, 271,  69, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  44, 237, 448, 636, 783, 877, 908, 867, 792, 657, 476, 267,  66, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  22, 120, 341, 574, 759, 772, 604, 243, 219, 181, 130, 66,   16, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  10, 58, 132, 219, 305, 525, 685, 758, 580, 348, 117,  65,   15, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,   9, 57, 142, 259, 368, 564, 703, 768, 726, 619, 454, 226,   38, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  11, 73, 130, 172, 193, 281, 354, 399, 434, 409, 331, 199,   46, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  14, 92, 246, 437, 613, 793, 878, 868, 783, 642, 458, 248,   51, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0,  0,  31, 218, 428, 617, 765, 860, 895, 867, 752, 496, 113, 73,   17, 0, 0, 0}
};
//radiacion_por_hora[dia_actual-dia_del_mes_inicio][(int)hora]/1200;

RTC_DATA_ATTR int8_t dia_del_mes_inicio = 7;
RTC_DATA_ATTR int8_t dia_actual = -1;
RTC_DATA_ATTR int8_t max_dia_mes = 28;

RTC_DATA_ATTR float radiacion_promedio = 0;
RTC_DATA_ATTR float hora = 0;
RTC_DATA_ATTR float bateria_actual = 0.75;
RTC_DATA_ATTR float bateria_deseada = 0.75;
RTC_DATA_ATTR int8_t w_int = 5;   // Número de interrupciones de trabajo (entre 4 (11%) y 36 (100%))
RTC_DATA_ATTR int8_t gps_max = 2;  // Número máximo de ejecuciones GPS
RTC_DATA_ATTR int8_t tx_max = 2;   // Número máximo de transmisiones

RTC_DATA_ATTR float pesos_capa1[11][6] = {
    {-4.9069268e-41,	4.9391567e-41,	4.9292075e-41,	-4.9447619e-41,	-4.9077676e-41,	-4.9547111e-41},
    {-4.9223411e-41,	-4.9394370e-41,	-4.9470040e-41,	-4.9080479e-41,	-4.9510677e-41,	-4.9226214e-41},
    {0.32725134,	0.44185665,	-4.3219829,	-1.2036245,	-1.0597597,	0.61855060},
    {-0.068568431,	-0.043764781,	-0.089690179,	0.13079689,	-9.5388393,	9.5494480},
    {-4.9119715e-41,	-4.9380357e-41,	-4.9419593e-41,	-4.9423797e-41,	-4.9311693e-41,	-4.9207997e-41},
    {-4.9045446e-41,	-4.9177168e-41,	-4.9213602e-41,	-4.9324305e-41,	-4.9402777e-41,	-4.9303285e-41},
    {-4.9397172e-41,	4.9341120e-41,	4.9367745e-41,	-4.9357936e-41,	-4.9147741e-41,	-4.9258444e-41},
    {-4.9279463e-41,	-4.9311693e-41,	-4.9512079e-41,	-4.9433606e-41,	-4.9051051e-41,	-4.9311693e-41},
    {-4.9450422e-41,	5.8401916e-41,	4.9052453e-41,	-4.9293476e-41,	-4.9327107e-41,	-4.9160353e-41},
    {-4.9121116e-41,	-4.9189780e-41,	-4.9451823e-41,	-4.9262648e-41,	-4.9363541e-41,	-4.9465836e-41},
    {-4.9056657e-41,	-4.9262648e-41,	-4.9423797e-41,	-4.9168761e-41,	4.9121116e-41,	-4.9336916e-41}
};

RTC_DATA_ATTR float bias_capa1[11] = {
    -4.9503671e-41,
    -4.9367745e-41,
    1.0523243,
    0.084373511,
    -4.9430803e-41,
    -4.9236023e-41,
    -4.9349528e-41,
    -4.9184175e-41,
    -4.9230418e-41,
    -4.9233220e-41,
    -4.9164557e-41
};

RTC_DATA_ATTR float pesos_capa2[11][11] = {
    {4.9376153e-41,	4.9269654e-41,	4.8971177e-41,	1.6698513e-38,	-4.9104301e-41,	-4.9086084e-41,	4.9486855e-41,	-4.9045446e-41,	4.9254240e-41,	4.9450422e-41,	-4.9182774e-41},
    {-4.9111307e-41,	-4.9238825e-41,	-4.9266851e-41,	-4.9458829e-41,	-4.9121116e-41,	-4.9286470e-41,	-4.9472842e-41,	-4.9149142e-41,	-4.9520486e-41,	-4.9177168e-41,	-4.9149142e-41},
    {-5.7858212e-41,	-4.9467237e-41,	-7.1072457e-41,	-5.0864332e-41,	-4.9095893e-41,	4.9342522e-41,	4.9415389e-41,	-4.9094492e-41,	-4.9444816e-41,	-4.9935271e-41,	-4.9053854e-41},
    {4.9084683e-41,	-5.2512259e-41,	-4.9219207e-41,	-5.0355660e-41,	6.7183854e-41,	-7.2955802e-41,	4.9073472e-41,	-6.8075079e-41,	-5.0379482e-41,	-5.3938780e-41,	-5.4436241e-41},
    {4.9287871e-41,	4.9118314e-41,	-4.9115511e-41,	-7.4630354e-41,	-4.9240227e-41,	4.9188379e-41,	4.9419593e-41,	4.9331311e-41,	4.9076275e-41,	-5.9747163e-41,	-4.9273858e-41},
    {-4.9496664e-41,	4.9409784e-41,	-5.1838234e-41,	-4.9310292e-41,	-4.9514881e-41,	-4.9463033e-41,	-4.9369146e-41,	-4.9308890e-41,	4.9189780e-41,	-4.9130925e-41,	4.9237424e-41},
    {-4.9360738e-41,	-4.9535901e-41,	-5.1304339e-41,	-6.2761356e-41,	4.9108505e-41,	4.9591953e-41,	-5.0984843e-41,	4.9426599e-41,	4.9428001e-41,	6.7570612e-41,	4.9519085e-41},
    {-4.9953488e-41,	4.9348127e-41, -7.4259010e-41,	-5.9061928e-41,	6.7925140e-41,	4.9526092e-41,	-5.0354259e-41,	-4.9676031e-41,	-4.9430803e-41,	-5.0326233e-41,	4.9114110e-41},
    {-4.9461632e-41,	4.9279463e-41,	-4.9398573e-41,	-5.4716501e-41,	4.9143537e-41,	5.1656065e-41,	-4.9415389e-41,	-4.9343923e-41,	4.9095893e-41,	-4.9409784e-41,	4.9353732e-41},
    {4.9380357e-41,	4.9392968e-41,	-0.82055348,	-8.7855148,	6.3518057e-41,	-4.9165958e-41,	4.9285068e-41,	4.9088887e-41,	4.9048249e-41,	-4.9073472e-41,	-4.9154748e-41},
    {4.9230418e-41,	-4.9273858e-41,	-4.9377554e-41,	-4.9250036e-41,	-4.9121116e-41,	-4.9460231e-41,	-4.9185576e-41,	-4.9498066e-41,	-4.9512079e-41,	-4.9200990e-41,	4.9387363e-41}
};

RTC_DATA_ATTR float bias_capa2[11] = {
   2.1940161e-38,
  -4.9301884e-41,
  -4.9053854e-41,
  -4.9349528e-41,
  -4.9350929e-41,
  -1.4237192e-41,
  -4.9231819e-41,
  -5.3095199e-41,
  -6.8349734e-41,
  1.5329268,
  -4.9467237e-41
};

RTC_DATA_ATTR float pesos_salida[3][11] = {
    {8.5236459e-39,	4.9570933e-41,	4.9590551e-41,	5.0179097e-41,	-4.9093090e-41,	4.9233220e-41,	-4.9924060e-41,	5.0141262e-41,	-5.1003060e-41,	4.1735907,	-4.9058058e-41},
    {3.5623157e-38,	4.9600360e-41,	3.1829093e-41,	4.9388764e-41,	6.6438363e-41,	4.9736286e-41,	-5.5725436e-41,	5.0478975e-41,	-4.9911449e-41,	4.5347962,	-4.9297680e-41},
    {3.8189335e-38,	-4.9296279e-41,	-4.9889028e-41,	5.1322556e-41,	-4.9397172e-41,	6.2539950e-41,	-5.5061221e-41,	-4.9474244e-41,	-4.9751701e-41,	4.5568275,	4.9189780e-41}
};

RTC_DATA_ATTR float bias_salida[3] = {
    -1.0622495,
    -1.0299305,
    -1.0681856
};


float multiplicador = 0.45;
float bias_escalado = 0.55;

/* ****** Variables de control del programa ****** */
RTC_DATA_ATTR int8_t c_scycle = 0;     // Contador de 10 segundos
RTC_DATA_ATTR int8_t cdata = 0;    // Contado de monitorizaciones
RTC_DATA_ATTR int8_t c6m = 0;      // Contador de los 6 minutos
RTC_DATA_ATTR int8_t cgps = 0;     // Contador de ejecuciones GPS
RTC_DATA_ATTR int8_t ctx = 0;      // Contador de transmisiones
RTC_DATA_ATTR bool icm42670_active = false;
RTC_DATA_ATTR int8_t prueba = 0; 

void setup() 
{
  //esp_task_wdt_init(600, true);
  //esp_task_wdt_add(NULL);

  //delay(1000);
  //Serial.begin(115200);
  //Serial.println("Hola");

  int64_t last_execution_time = esp_timer_get_time();
  const int64_t interval_us = 10000000;

  esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();

  if (send_mode == true) {
        goto transmitir;
  }

  Mcu.begin(HELTEC_BOARD,SLOW_CLK_TPYE);

  
  //Serial.begin(115200);
  // //Serial.println("Dispositivo despertado");
  //Serial.print("Causa: ");
  //Serial.print(cause);
  // Serial.print(" c_scycle: ");
  // Serial.print(c_scycle);
  // Serial.print(" ctx: ");
  // Serial.print(ctx);
  // Serial.print(" tx_max: ");
  // Serial.print(tx_max);
  // Serial.print(" tx_max: ");

  //delay(1000);
  Serial.print("Causa: ");
  Serial.print(cause);
  Serial.print("c_scycle: ");
  Serial.print(c_scycle);
  Serial.print(" cdata: ");
  Serial.print(cdata);
  Serial.print(" c6m: ");
  Serial.print(c6m);
  Serial.print(" cgps: ");
  Serial.print(cgps);
  Serial.print(" ctx: ");
  Serial.print(ctx);
  Serial.print(" icm42670_active: ");
  Serial.print(icm42670_active);
  Serial.print(" prueba: ");
  Serial.print(prueba);
  Serial.print(" dia_del_mes_inicio: ");
  Serial.print(dia_del_mes_inicio);
  Serial.print(" dia_actual: ");
  Serial.print(dia_actual);
  Serial.print(" max_dia_mes: ");
  Serial.print(max_dia_mes);
  Serial.print(" radiacion_promedio: ");
  Serial.print(radiacion_promedio);
  Serial.print(" hora: ");
  Serial.print(hora);
  Serial.print(" bateria_actual: ");
  Serial.print(bateria_actual);
  Serial.print(" bateria_deseada: ");
  Serial.print(bateria_deseada);
  Serial.print(" w_int: ");
  Serial.print(w_int);
  Serial.print(" gps_max: ");
  Serial.print(gps_max);
  Serial.print(" tx_max: ");
  Serial.print(tx_max);
  Serial.print(" send_mode: ");
  Serial.print(send_mode);
  Serial.print(" send_message: ");
  Serial.print(send_message);
  Serial.print(" contador: ");
  Serial.print(contador);
  Serial.print(" first_communication: ");
  Serial.print(first_communication);
  Serial.print(" first_ejecution: ");
  Serial.println(first_ejecution);

  int64_t current_time;
  int64_t elapsed_time;
  int64_t remaining_time_us;

  Wire.begin(SDA_PIN, SCL_PIN);
  //Serial.println("Configurado I2C");
  
  //if (cause != ESP_SLEEP_WAKEUP_TIMER) {
  if (first_ejecution){
    //Serial.println("Entrando a configuracion inicial");
    first_ejecution = false;
    first_configuration();
    //Serial.println("Configuracion inicial");
    //delay(1000);
  }

  if (icm42670_active != true) {
    icm42670_active = activar_ICM();
    //Serial.println("Activando ICM");
    c6m++;
  }

  if ((c_scycle == 0) && (cgps < gps_max) && (cause == ESP_SLEEP_WAKEUP_TIMER)) gps_function(false);

  // En el primer ciclo, se espera hasta los 10 (s) para tener datos en la ICM
  if (c_scycle == 0){
    //Serial.println("Durmiendo por fin de GPS");
    current_time = esp_timer_get_time();
    elapsed_time = current_time - last_execution_time;
    remaining_time_us = interval_us - (esp_timer_get_time() - last_execution_time);

    if (remaining_time_us > 0) {
      c_scycle++;
      esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
      esp_sleep_enable_timer_wakeup(remaining_time_us);
      esp_deep_sleep_start();
    } else {
      c_scycle++;
      esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
      esp_sleep_enable_timer_wakeup(500);
      esp_deep_sleep_start();
    }
  }
  
  extract_data();
  //Serial.println("Extrayendo datos");

  send_mode = (((c_scycle == 1) && (ctx < tx_max)) || first_communication);
  
  //Serial.print("Send mode= ");
  //Serial.println(send_mode);

  //delay(1000);
  //Serial.print("Preparandose para transmitir:");
  //Serial.print("...")

  deviceState = DEVICE_STATE_INIT;

  transmitir:

  while (send_mode){
    switch( deviceState )
    {
      case DEVICE_STATE_INIT:
      {
      #if(LORAWAN_DEVEUI_AUTO)
            LoRaWAN.generateDeveuiByChipID();
      #endif
        LoRaWAN.init(loraWanClass,loraWanRegion);
        //both set join DR and DR when ADR off 
        LoRaWAN.setDefaultDR(0);
        break;
      }
      case DEVICE_STATE_JOIN:
      {
        LoRaWAN.join();
        break;
      }
      case DEVICE_STATE_SEND:
      {
        send_message++;
        if(send_message == 2)
        {
          delay(500);
          send_message = 0;
          send_mode = false;
          break;
        }
        prepareTxFrame( appPort );
        LoRaWAN.send();
        deviceState = DEVICE_STATE_CYCLE;
        break;
      }
      case DEVICE_STATE_CYCLE:
      {
        // Schedule next packet transmission
        //txDutyCycleTime = appTxDutyCycle + randr( -APP_TX_DUTYCYCLE_RND, APP_TX_DUTYCYCLE_RND );
        txDutyCycleTime = appTxDutyCycle + randr( -1000, 1000 );
        //txDutyCycleTime = 5000;
        LoRaWAN.cycle(txDutyCycleTime);
        deviceState = DEVICE_STATE_SLEEP;
        break;
      }
      case DEVICE_STATE_SLEEP:
      {
        LoRaWAN.sleep(loraWanClass);
        //Mcu.timerhandler();
        //Radio.IrqProcess();
        break;
      }
      default:
      {
        deviceState = DEVICE_STATE_INIT;
        break;
      }
    }
  }

  //Aqui podría haber un error, ya que nunca queda en INIT, hay que asegurarse que la primera
  //ejecucion si sea con INIT para que se una a la red
  first_communication = false;
  deviceState = DEVICE_STATE_INIT;
  //DEVICE_STATE_SEND;
  
  // Cambiar el >= 10, ya que esta modificado para que sea cada 3*6 min
  if ((c_scycle == 2) && (c6m >= 10)) ems_function(); 

  if (cdata >= w_int) icm42670_go_to_sleep((36-w_int)*10); //ESTO HAY QUE CAMBIARLO POR 36-w_int

  current_time = esp_timer_get_time();
  elapsed_time = current_time - last_execution_time;
  remaining_time_us = interval_us - (esp_timer_get_time() - last_execution_time);
  
  //esp_task_wdt_reset();

  if (remaining_time_us > 0) {
    c_scycle++;
    esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
    esp_sleep_enable_timer_wakeup(remaining_time_us);
    esp_deep_sleep_start();
  } else {
    c_scycle++;
    esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
    esp_sleep_enable_timer_wakeup(500);
    esp_deep_sleep_start();
  }
  

}

void loop()
{

}

/* ****** FUNCIONES PARA LORAWAN ****** */

static void prepareTxFrame( uint8_t port )
{

      appDataSize = 13 + 11*cgps_buffer;

      appData[0] = contador;
      appData[1] = (uint8_t)(bateria_actual * 100);
      appData[2] = (uint8_t)(bateria_deseada * 100);
      appData[3] = cgps_buffer;
      appData[4] = clasificacion[0];
      appData[5] = clasificacion[1];
      appData[6] = clasificacion[2];
      appData[7] = clasificacion[3];
      appData[8] = (int8_t)(orientacion_collar*127);
      appData[9] = dia_actual;
      appData[10] = w_int;
      appData[11] = gps_max;
      appData[12] = tx_max;

      int index = 13;

      while (cgps_buffer > 0){
        int bufferIndex = cgps_buffer - 1;

        appData[index++] = gps_hour[bufferIndex];
        appData[index++] = gps_minute[bufferIndex];
        appData[index++] = gps_second[bufferIndex];

        memcpy(&appData[index], &gps_latitud[bufferIndex], sizeof(float));
        index += sizeof(float);

        memcpy(&appData[index], &gps_longitud[bufferIndex], sizeof(float));
        index += sizeof(float);

        cgps_buffer--;
      }
      
      clasificacion[0] = 0;
      clasificacion[1] = 0;
      clasificacion[2] = 0;
      clasificacion[3] = 0;

      ctx++;
      contador++;
}

/* ****** FUNCIONES PARA EL ICM ****** */

bool activar_ICM()
{
  writeI2C(PWR_MGMTO, GYRO_AND_ACCE_CONFIG);
  return true;
}

bool desactivar_ICM()
{
  writeI2C(PWR_MGMTO,0x00);
  return false;
}

void init_icm42670()
{
  writeI2C(PWR_MGMTO,GYRO_AND_ACCE_CONFIG);
  delay(5);
  writeI2C(GYRO_CONFIG0,CONFIG_250dps_12_5HZ);
  delay(5);
  writeI2C(ACCEL_CONFIG0,CONFIG_250dps_12_5HZ);
  delay(5);
}

void configure_fifo()
{
  writeI2C(FIFO_CONFIG1, 0x01);
  delay(50);
  writeI2C(MADDR_W,FIFO_CONFIG5);
  delay(50);
  writeI2C(M_W,0x23);
  delay(50);
  writeI2C(FIFO_CONFIG2,0xD0);
  delay(50);
  writeI2C(FIFO_CONFIG3,0x07);
  delay(50);
  writeI2C(MADDR_W,SENSOR_CONFIG3);
  delay(50);
  writeI2C(M_W,0x40);
  delay(50);
  writeI2C(INT_SOURCE0,0x00);
  delay(50);
  writeI2C(INT_CONFIG,0x02);
  delay(50);
  writeI2C(MADDR_W,INT_CONFIG1);
  delay(50);
  writeI2C(M_W,0x50);
  delay(50);
  writeI2C(FIFO_CONFIG1,0x00);
  delay(50);
}

void icm42670_go_to_sleep(uint16_t time)
{
  icm42670_active = desactivar_ICM();
  c_scycle = 0;
  cdata = 0;

  esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
  esp_sleep_enable_timer_wakeup(time*1000000); //light sleep
  esp_deep_sleep_start();
}

bool extract_data()
{
    uint8_t counter_good = 0;
    uint8_t counter_bad = 0;
    uint8_t packet[16] = {0};
    int clase_predicha = -1;
    cdata++;

    for (int i=0; i < 2; i++){
      while (counter_good < CANTIDAD_MUESTRAS) {
        if (read_icm42670_registers(FIFO_DATA, packet, 16)) {
            int16_t accel_x = bytes_to_int16(packet[1], packet[2]);
            int16_t accel_y = bytes_to_int16(packet[3], packet[4]);
            int16_t accel_z = bytes_to_int16(packet[5], packet[6]);

            int16_t gyro_x = bytes_to_int16(packet[7], packet[8]);
            int16_t gyro_y = bytes_to_int16(packet[9], packet[10]);
            int16_t gyro_z = bytes_to_int16(packet[11], packet[12]);

            ax[counter_good] = (float) accel_x*9.8/2048;
            ay[counter_good] = (float) accel_y*9.8/2048;
            az[counter_good] = (float) accel_z*9.8/2048;
            gx[counter_good] = (float) gyro_x/16.4;
            gy[counter_good] = (float) gyro_y/16.4;
            gz[counter_good] = (float) gyro_z/16.4;
            acc_vec[counter_good] = (float) sqrt(ax[counter_good] * ax[counter_good] + ay[counter_good] * ay[counter_good] + az[counter_good] * az[counter_good]);
            gyro_vec[counter_good] = (float) sqrt(gx[counter_good] * gx[counter_good] + gy[counter_good] * gy[counter_good] + gz[counter_good] * gz[counter_good]);

            counter_good++;
        } else {
            counter_bad++;
        }
      }
      
      calcularCaracteristicas();

      // Clasificar con el SVM
      clase_predicha = clasificar();
      
      delay(10);  // Reemplaza vTaskDelay
      delay(1);  // Reemplaza vTaskDelay
      counter_good = 0;
      counter_bad = 0;
    }

    orientacion_collar = calcularMediana(az, CANTIDAD_MUESTRAS)/9.8;
    if (orientacion_collar > 1) orientacion_collar = 1;
    if (orientacion_collar < -1) orientacion_collar = -1;

    return true;  // Retorna éxito
}

/* ****** FUNCIONES DE CONFIGURACION ****** */

void first_configuration()
{
  //Serial.println("Iniciando ");
  
  init_icm42670();
  //Serial.println("Iniciado ICM");
  configure_fifo();
  //Serial.println("Configurado FIFO");

  gps_function(true);
  //Serial.println("Ejecutado GPS");

  ems_function();
  //Serial.println("Ejecutado EMS");
  icm42670_active = true;
}

/* ****** FUNCIONES DE PROTOCOLO I2C ****** */

bool writeI2C(uint8_t memoryAddress, uint8_t data)
{
    bool success = false;

    while (!success) {
        Wire.beginTransmission(ICM42670_ADDR);      // Inicia la comunicación con el dispositivo
        Wire.write(memoryAddress);                       // Dirección del registro
        Wire.write(data);                          // Valor a escribir
        uint8_t error = Wire.endTransmission();     // Finaliza la transmisión

        if (error == 0) {
            success = true;
        } else {
            delay(100); // Retardo antes de reintentar
        }
    }
    return success;
}

int readI2C(uint8_t memoryAddress)
{
  Wire.beginTransmission(ICM42670_ADDR);
    Wire.write(memoryAddress); // Dirección interna del registro/memoria
    Wire.endTransmission(false); // Mantener la conexión abierta
    Wire.requestFrom(ICM42670_ADDR, (uint8_t)1); // Solicitar 1 byte al dispositivo

    if (Wire.available()) {
        return Wire.read(); // Retorna el dato leído
    } else {
        return -1; // Indica error
    }
}

int16_t bytes_to_int16(uint8_t msb, uint8_t lsb)
{
    return (int16_t)((msb << 8) | lsb);
}

bool read_icm42670_registers(uint8_t reg, uint8_t* buffer, size_t len)
{
    Wire.beginTransmission(ICM42670_ADDR);
    Wire.write(reg);  // Especifica el registro desde donde leer
    if (Wire.endTransmission(false) != 0) {  // Mantén el bus abierto
        return false;  // Error en la escritura
    }
    Wire.requestFrom(ICM42670_ADDR, len);
    for (size_t i = 0; i < len; i++) {
        if (Wire.available()) {
            buffer[i] = Wire.read();
        } else {
            return false;  // Error al leer datos
        }
    }
    return true;
}

/* ****** FUNCIONES DE GPS ****** */

void gps_function(bool primera_ejecucion)
{
  uint32_t max_wait;

  pinMode(VGNSS_CTRL,OUTPUT);
	digitalWrite(VGNSS_CTRL,HIGH);

  if(primera_ejecucion){
    max_wait = 60000*5;
  } else {
    max_wait = 8730;
  }
	Serial1.begin(115200,SERIAL_8N1,33,34);

  //unsigned long start = millis();
  uint32_t start_time = millis();

  while (!GPS.location.isValid() && (millis() - start_time) < max_wait){

    while (Serial1.available() > 0) {
            GPS.encode(Serial1.read());
            //Serial.print("Pasado transcurrido: ");
            //Serial.println(millis() - start_time);
    }

    //Serial.print("Tiempo transcurrido: ");
    //Serial.println(millis() - start_time);


    // do{
    //   if (Serial1.available()){
    //     GPS.encode(Serial1.read());
    //   }
    // } 
    
    // while((GPS.charsProcessed() < 10 ) && ((millis() - start) < max_wait)); //((millis() + start) <5000); 

    // if ((millis() - start) > max_wait)// && GPS.charsProcessed() < 10) 
    // {
    //  break;
    // }
  }

  if (GPS.time.isValid()) {
        gps_hour[cgps_buffer] = GPS.time.hour();
        gps_minute[cgps_buffer] = GPS.time.minute();
        gps_second[cgps_buffer] = GPS.time.second();
        gps_latitud[cgps_buffer] = GPS.location.lat();
        gps_longitud[cgps_buffer] = GPS.location.lng();
        cgps_buffer++;

        hora = (float) (GPS.time.hour() - 3);
        dia_actual = GPS.date.day();
        if (hora < 0 ) {
          hora+=24;
          dia_actual-=1;
        }
        if (dia_actual < dia_del_mes_inicio){
          dia_actual += max_dia_mes;
        }

  }

  

  cgps++;
  digitalWrite(VGNSS_CTRL,LOW);
}

/* ****** FUNCIONES DE EMS ****** */

void ems_function()
{
  float entradas[6];
  float salidas[3];

  radiacion_promedio = 0;

  pinMode(ADC_IN, INPUT);
  pinMode(ADC_Ctrl, INPUT);
  analogReadResolution(12);

  int indice_datos = dia_actual-dia_del_mes_inicio;

  if (indice_datos > 14 || indice_datos < 0) {
    indice_datos = 0;
  }

  int indice_hora = hora;

  if (hora >= 24 || hora < 0){
    indice_hora = 0;
  }

  for (int i = 0; i < 24; i++) {
    radiacion_promedio += radiacion_por_hora[indice_datos][i];
  }

  radiacion_promedio = radiacion_promedio/24;

  pinMode(ADC_Ctrl, INPUT_PULLUP);
  delay(10);

  float voltajeBat = (float)(analogRead(ADC_IN)*FACTOR_MULTIPLICADOR);

  delay(10);
  pinMode(ADC_Ctrl, INPUT_PULLDOWN);
  

  bateria_actual = calcularCarga(voltajeBat);

  entradas[0] = ((orientacion_collar*orientacion_solar[indice_datos][(int)indice_hora])+1)/2;
  entradas[1] = radiacion_por_hora[indice_datos][(int)indice_hora]/1200;
  entradas[2] = radiacion_promedio/1200;
  entradas[3] = ((indice_hora-12)/12 + 1)/2;
  entradas[4] = bateria_actual;
  entradas[5] = bateria_deseada;

  red_neuronal(entradas, salidas);
  transformacion(salidas);

  c6m = 0;
  cgps = 0;
  ctx = 0;
}

/* ****** FUNCIONES DE SVM ****** */

float calcularRMS(float datos[], int tam)
{
    float suma = 0.0;
    for (int i = 0; i < tam; i++) {
        suma += datos[i] * datos[i];
    }
    return sqrt(suma / tam);
}

float calcularPeakToPeak(float datos[], int tam)
{
    float max_val = datos[0], min_val = datos[0];
    for (int i = 1; i < tam; i++) {
        if (datos[i] > max_val) max_val = datos[i];
        if (datos[i] < min_val) min_val = datos[i];
    }
    return max_val - min_val;
}

float calcularDesviacionEstandar(float datos[], int tam, float media)
{
    float suma = 0.0;
    for (int i = 0; i < tam; i++) {
        suma += (datos[i] - media) * (datos[i] - media);
    }
    return sqrt(suma / tam);
}

float calcularMediana(float datos[], int tam)
{
    // Ordenamiento simple por inserción (mejor usar un algoritmo más eficiente si hay más datos)
    for (int i = 0; i < tam - 1; i++) {
        for (int j = i + 1; j < tam; j++) {
            if (datos[j] < datos[i]) {
                float temp = datos[i];
                datos[i] = datos[j];
                datos[j] = temp;
            }
        }
    }
    return tam % 2 == 0 ? (datos[tam / 2 - 1] + datos[tam / 2]) / 2 : datos[tam / 2];
}

void calcularCaracteristicas()
{

    // Calcular características
    float suma_ax = 0, suma_gy = 0, suma_gx = 0;

    for (int i = 0; i < CANTIDAD_MUESTRAS; i++) {
        suma_ax += ax[i];
        suma_gx += gx[i];
        suma_gy += gy[i];
    }

    caracteristicas[0] = calcularDesviacionEstandar(ax, CANTIDAD_MUESTRAS, suma_ax / CANTIDAD_MUESTRAS); // Desviación estándar de ax
    caracteristicas[1] = calcularPeakToPeak(ax, CANTIDAD_MUESTRAS);                                // Peak to peak de ax
    caracteristicas[2] = calcularRMS(ax, CANTIDAD_MUESTRAS);                                       // RMS de ax
    caracteristicas[3] = calcularMediana(ay, CANTIDAD_MUESTRAS);                                   // Mediana de ay
    caracteristicas[4] = calcularPeakToPeak(ay, CANTIDAD_MUESTRAS);                                // Peak to peak de ay
    caracteristicas[5] = calcularPeakToPeak(ay, CANTIDAD_MUESTRAS) / CANTIDAD_MUESTRAS;                 // Promedio absoluto derivada de ay
    caracteristicas[6] = calcularMediana(az, CANTIDAD_MUESTRAS);                                   // Mediana de az
    caracteristicas[7] = calcularDesviacionEstandar(acc_vec, CANTIDAD_MUESTRAS, 0);               // Desviación estándar acc_vec
    caracteristicas[8] = calcularPeakToPeak(acc_vec, CANTIDAD_MUESTRAS);                           // Peak to peak acc_vec
    caracteristicas[9] = suma_ax;                                                            // gx.
    
    caracteristicas[9] = 0; // Suma de los valores absolutos de acc_vec
    for (int i = 0; i < CANTIDAD_MUESTRAS; i++) {
        caracteristicas[9] += fabs(acc_vec[i]);
    }
    caracteristicas[10] = suma_gx;                                   // Suma de gx
    caracteristicas[11] = calcularPeakToPeak(gy, CANTIDAD_MUESTRAS);      // Peak to peak de gy
    caracteristicas[12] = suma_gy;                                   // Suma de gy
    caracteristicas[13] = calcularRMS(gz, CANTIDAD_MUESTRAS);             // RMS de gz
    caracteristicas[14] = calcularRMS(gyro_vec, CANTIDAD_MUESTRAS);       // RMS de gyro_vec
}

int clasificar()
{
    float scores[NUM_CLASSES] = {0,0,0,0};
    int clase_predicha = 0;

    // Calcular las puntuaciones (scores) para cada clase
    for (int i = 0; i < NUM_CLASSES; i++) {
        scores[i] = interceptos[i];
        for (int j = 0; j < NUM_FEATURES; j++) {
            scores[i] += coeficientes[i][j] * caracteristicas[j];
        }
        if (i == 0 || scores[i] > scores[clase_predicha]) {
            clase_predicha = i;
        }
    }

    // Incrementar el conteo en la variable global
    clasificacion[clase_predicha]++;

    return clase_predicha;
}

/* ****** FUNCIONES PARA EJECUTAR EMS ****** */

float relu(float x)
{
    return x > 0 ? x : 0;
}

float saturar(float x)
{
    if (x > 1.0) return 1.0;
    if (x < -1.0) return -1.0;
    return x;
}

void densa(const float entrada[], float salida[], const float *pesos, const float bias[], int tam_entrada, int tam_salida)
{
    for (int i = 0; i < tam_salida; i++) {
        salida[i] = bias[i]; // Inicializar con el bias
        for (int j = 0; j < tam_entrada; j++) {
            salida[i] += entrada[j] * pesos[i * tam_entrada + j]; // Producto entrada * peso
        }
    }
}

void aplicar_relu(float vector[], int tam)
{
    for (int i = 0; i < tam; i++) {
        vector[i] = relu(vector[i]);
    }
}

void aplicar_saturacion(float vector[], int tam)
{
    for (int i = 0; i < tam; i++) {
        vector[i] = saturar(vector[i]);
    }
}

void aplicar_escalado(float vector[], int tam, float multiplicador, float bias)
{
    for (int i = 0; i < tam; i++) {
        vector[i] = vector[i] * multiplicador + bias;
    }
}

void red_neuronal(const float entradas[6], float salidas[3])
{
    float capa1[11], capa2[11];

    // Primera capa densa
    densa(entradas, capa1, &pesos_capa1[0][0], bias_capa1, 6, 11);
    aplicar_relu(capa1, 11);

    // Segunda capa densa
    densa(capa1, capa2, &pesos_capa2[0][0], bias_capa2, 11, 11);
    aplicar_relu(capa2, 11);

    // Capa de salida
    densa(capa2, salidas, &pesos_salida[0][0], bias_salida, 11, 3);
    aplicar_saturacion(salidas, 3);
    aplicar_escalado(salidas, 3, multiplicador, bias_escalado);
}

void transformacion(float salidas[3])
{
  w_int = (int) (salidas[0]*36);   // Número de interrupciones de trabajo (entre 4 (11%) y 36 (100%))
  tx_max = (int) (salidas[1]*10);   // Número máximo de transmisiones
  gps_max = (int) (salidas[2]*10);  // Número máximo de ejecuciones GPS
}

float calcularCarga(float voltaje) {
    float carga;

    if (voltaje >= 4.2) {
        carga = 1.0;
    } else if (voltaje > 3.0) {
        // Cálculo lineal entre voltaje 3.9 y 3.0
        carga = 1.0 - (1.0 - 0.1) * ((4.2 - voltaje) / (4.2 - 3.0));
    } else if (voltaje > 2.5) {
        // Cálculo lineal entre voltaje 3.0 y 2.5
        carga = 0.133 - (0.1 - 0.0) * ((3.0 - voltaje) / (3.0 - 2.5));
    } else {
        carga = 0.0;
    }

    return carga;
}