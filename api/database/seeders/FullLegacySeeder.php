<?php

namespace Database\Seeders;

use App\Models\Ajuste;
use App\Models\Lectura;
use App\Models\Periodo;
use App\Models\Role;
use App\Models\Tarifa;
use App\Models\TarifaRango;
use App\Models\User;
use App\Models\Vivienda;
use App\Models\Zone;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class FullLegacySeeder extends Seeder
{
    public function run(): void
    {
        // 1. Roles
        $adminRole = Role::firstOrCreate(['name' => 'Admin']);
        $lectorRole = Role::firstOrCreate(['name' => 'Lector']);
        $socioRole = Role::firstOrCreate(['name' => 'Socio']);

        // 1.5 Métodos de Pago
        \App\Models\PaymentMethod::firstOrCreate(['name' => 'Efectivo'], ['description' => 'Pago en efectivo']);

        // 2. Administrador Principal
        User::updateOrCreate(
            ['email' => 'admin@agua.com'],
            ['name' => 'ADMINISTRADOR', 'password' => Hash::make('password'), 'role_id' => $adminRole->id]
        );

        // 3. Zonas
        $zonaTR = Zone::updateOrCreate(['name' => 'Tojlu Rancho'], ['description' => 'Sector Tojlu Rancho']);
        $zonaVR = Zone::updateOrCreate(['name' => 'Villa Rosario'], ['description' => 'Sector Villa Rosario']);
        $zonaSI = Zone::updateOrCreate(['name' => 'San Isidro'], ['description' => 'Sector San Isidro']);

        // 4. Tarifa General
        $tarifa = Tarifa::updateOrCreate(['nombre' => 'Tarifa General'], ['monto_fijo' => 8.00]);
        $rangos = [['desde' => 0, 'hasta' => 20, 'precio_metro' => 1.50]];
        $precio = 1.50;
        for ($i = 21; $i <= 500; $i += 10) {
            $precio += 1.50;
            $rangos[] = ['desde' => $i, 'hasta' => $i + 9, 'precio_metro' => $precio];
        }
        $rangos[count($rangos)-1]['hasta'] = null;
        foreach ($rangos as $rango) {
            TarifaRango::updateOrCreate(['tarifa_id' => $tarifa->id, 'desde' => $rango['desde']], $rango);
        }

        // 5. Ajustes
        Ajuste::updateOrCreate(['clave' => 'multa_mora'], ['valor' => '5.00', 'descripcion' => 'Monto de multa por mora']);
        Ajuste::updateOrCreate(['clave' => 'meses_mora_deudor'], ['valor' => '3', 'descripcion' => 'Meses para ser considerado deudor']);
        Ajuste::updateOrCreate(['clave' => 'dia_vencimiento'], ['valor' => '15', 'descripcion' => 'Día del mes de vencimiento']);
        Ajuste::updateOrCreate(['clave' => 'monto_fijo_anual'], ['valor' => '150.00', 'descripcion' => 'Monto fijo pago anual (hasta 60m3/año)']);
        Ajuste::updateOrCreate(['clave' => 'monto_conexion'], ['valor' => '1500.00', 'descripcion' => 'Monto predeterminado por nueva conexión']);

        // ======================== SOCIOS COMPLETOS ========================

        $nombresTR = [
            "CLAUDIO VARGAS", "CRISTOBAL JALDIN", "FELIPE VELIZ", "ISABEL JALDIN", "SOFIA QUIROZ",
            "LUIS TAPIA", "ISABEL VASQUEZ", "SOFIA QUIROZ", "HILARIA COLQUE", "MIRTHA TAPIA",
            "GENARO CASTRO", "FACUNDO CASTRO", "NATIVIDAD QUIROZ", "EDILBERTO TAPIA", "GIOVANA ALVAREZ",
            "GUMERCINDO ALVAREZ", "HORTENCIA CLAROS", "GERARDO JORDAN", "NIVARDO CALUSTRO", "ALICIA CAMARA",
            "ANDREA SOTO", "ROBERT CASTRO", "EMETERIO ZAPATA", "EDMUNDO TAPIA", "CLAUDINA CALUSTRO",
            "SABINA CALUSTRO", "ROXANA CRUZ", "PASTOR MONTAÑO", "FOTUNATO MONTAÑO", "LILIANA SAUSA VEIZAGA",
            "EVARISTO PLATA", "ORLANDO JORDAN", "MARTHA ROJAS", "CASIANO PANIAGUA", "JOSE BARRIENTOS",
            "CELIA JORDAN", "LEONORA VARGAS", "WILDER CRUZ", "EDELMIRA FERRUFINO", "RUBEN MONTAÑO",
            "CRISTINA JORDAN", "EDELMIRA FERRUFINO", "RENE SAGARDIA", "FRANCISCA MONTAÑO", "ROSA TAPIA",
            "FRANCISCO SAGARDIA", "MODESTA CALUSTRO", "OLGA TAPIA", "EFRAIN TAPIA", "VILMA MONTAÑO",
            "MARIA REA", "BRYAN PANIAGUA", "LUCIA CALUSTRO", "MOISE TAPIA", "VALENTIN CLAURE",
            "PRIMITIVA CASTRO", "LIMBER CASTRO", "CONSTANTINO BARRIENTOS", "CONSTANTINO BARRIENTOS", "ROSMERY MONTAÑO",
            "LUCIA DE SAGARDIA", "LUISA FERRUFINO", "JULIO CAMACHO", "ANGELINA BARRIENTOS", "JULIA BARRIENTOS",
            "EMETERIO GUTIERREZ", "SONIA CASTRO", "SABINA CASTRO", "MIGUELINA VARGAS", "EUSEBIO VILLCA",
            "APOLONIA VARGAS", "MARIA DE VARGAS", "PANFILO CHOQUE", "EDWIN CASTRO", "ROMULO FUENTES",
            "ROMULO FUENTES", "CONCEPCION CALUSTRO", "CASIANO CALUSTRO", "ADELAIDA CALUSTRO", "ANDREA REA",
            "MARCO MERINO", "EMILIA BARRIENTOS", "ESTEBAN BARRIENTOS", "MELICIA LEDEZMA", "VALERIO RAMIREZ"
        ];

        $nombresVR = [
            'BENEDICTA FERRUFINO', 'CRISTINA FERREL', 'GERARDO ZAPATA', 'ROGELIO CASTRO', 'RUFINO VERDUGUEZ',
            'MARCIAL FERRUFINO', 'FELICIDAD SAGARDIA', 'FAQUINA VILLARROEL', 'LEONARDA CALUSTRO', 'MARTA GIMENEZ',
            'CONSTANTINO ZURITA', 'KARMINIA ZAPATA', 'ROLANDO TERCEROS', 'SANTIAGO REA', 'MACARIO CASTRO',
            'VILMA TERCEROS', 'ISMAEL JALDIN', 'JAIME JALDIN', 'SIN NOMBRE 19', 'INES ORELLANA',
            'INDALICIO CASTRO', 'SERAFINA QUIROS', 'SIN NOMBRE 23', 'PEDRO VILLARROEL', 'PEPE ZURITA',
            'SIN NOMBRE 26', 'LUSBERT CLAROS', 'EDWIN CASTRO'
        ];

        $nombresSI = [
            'ANTONIO SAGARDIA', 'VALERIO JALDIN', 'FELICIANA CALUSTRO', 'ANICETA CASTRO', 'LUCRECIO JORDAN',
            'JUAN CASTRO', 'KARINA OROSCO', 'MARCELINA CALUSTRO', 'JUSTINA CASTRO', 'LIZBETH JORDAN',
            'ALBINA CALUSTRO', 'PABLO QUIROZ', 'RICHAR CLAROS', 'VIRGINIA TAPIA', 'FAUSTINO CLAROS',
            'IRINE QUIROZ', 'ANTINOR QUIROZ', 'FANOR ELIAS JORDAN', 'TOMASA SOLIZ', 'ALCIRA TAPIA',
            'DOROTEA TAPIA', 'EMETERIO ARICOMA', 'JOSE ALVAREZ', 'GILVER JORDAN', 'EPIFANIA CLAROS',
            'GREGORIA FUENTES', 'ANA MARIA FLORES', 'ALICIA CLAROS', 'ISMAEL JALDIN', 'BERNARDINA LEDEZMA',
            'FREDDY TAPIA', 'FREDDY UREÑA', 'CLAUDIO LEDEZMA', 'ARMANDO OROSCO', 'TOMASA SOLIZ',
            'LITZI PONCE', 'NATIVIDAD QUIROZ', 'EDILBERTO TAPIA', 'MACARIA SAGARDIA', 'NICOLAZA LEDEZMA',
            'FELIX TAPIA', 'VALERIO TAPIA', 'LUCRECIO TAPIA', 'APOLONIA JALDIN', 'GREGORIA FUENTES',
            'DEMETRIO CARDOZO', 'SIMON CLAROS', 'CRISPIN CALUSTRO', 'EMMA CLAURE', 'MIRIAM MONTAÑO',
            'ENCARNACION TAPIA', 'ELMER TAPIA', 'HERMINIA  LEDEZMA', 'DELICIA TAPIA', 'GUMERCINDO TERCEROS',
            'EINAR TERCEROS', 'EMILIO ALMENDRAS', 'MELICIA LEDEZMA', 'LUCHA VARGAS', 'ROGER JALDIN',
            'WILFREDO LEDEZMA', 'FERMIN REQUE', 'BLANCA OCHOA', 'CRISTOBAL TAPIA', 'NICACIA DE FERRUFINO',
            'LEANDRO FERRUFINO', 'VIRGINIA TAPIA', 'FORTUNATA FUENTES', 'WILLIAM TERCEROS', 'LUCIO FERREL',
            'JUAN TAPIA', 'MARIA TAPIA', 'SABINO ALVARES', 'EDMUNDO TAPIA', 'BLADIMIR TAPIA',
            'SEVERINA RODRIGUEZ', 'LEANDRA MONTAÑO', 'FLORINDA JORDAN', 'SANDRA SAGARDIA', 'BENEDICTA ROCHA',
            'MACARIA SAGARDIA', 'FELICIDAD SAGARDIA', 'CECILIO CALUSTRO', 'CARLOS CASTRO', 'VALENTIN ROCHA',
            'JORGE LEDEZMA', 'MARCELINA CRUZ', 'FRANCISCA ALVAREZ', 'VALENTIN CLAURE', 'EUGENIA VEIZAGA',
            'HERMOGENES FUENTES', 'ELOTERIA TERCEROS', 'ELOTERIA DE FERRUFINO', 'ORLANDO VASQUEZ', 'DARIO FERRUFINO',
            'DANIEL FERRUFINO', 'PRIMITIVO MONTAÑO', 'CONSTANCIA SOTO', 'ERVER TAPIA', 'IRINEO CRUZ',
            'CELIA CRUZ', 'BACILIA JORDAN', 'LEON VALLEJOS', 'ERASMO JIMENEZ', 'PEDRO MONTAÑO',
            'PILAR AREVALO', 'NELIDA QUIROZ', 'ALBINA CALUSTRO', 'JUAN CASTRO', 'ROLANDO TERCEROS',
            'JULIO CAMACHO', 'SUSI QUIROZ', 'RAMIRO OROSCO', 'CIPRIANA TAPIA', 'CRISPIN TAPIA',
            'SONIA VASQUEZ', 'AURELIA QUIROZ', 'RIMER FUENTES', 'WILSON CASTRO', 'CLAUDIO LEDEZMA',
            'NELGI TAPIA', 'PEPE CALUSTRO', 'JAIME CLAURE', 'ESPERANZA CASTRO', 'SUSI JORDAN',
            'RAFAEL TAPIA', 'ADELA CRUZ', 'WILLY WALDO FUENTES', 'GUIDO FUENTES', 'ISABEL FUENTES',
            'ALFREDO SAGARDIA', 'FRANCISCO SAGARDIA', 'MARIO CLAROS', 'MARTHA CRUZ', 'PALMIRA FERRUFINO',
            'PEDRO CAMARA', 'MARIA REA', 'KARINA CARDOZO', 'DENIS CARDOZO', 'EUSEBIO LEDEZMA',
            'JUAN JOSE TAPIA', 'PATROCINIO TAPIA', 'BORIS TAPIA', 'ALICIA CLAROS', 'PATROCINIO TAPIA',
            'ELVIS QUIROZ', 'LUIS CALUSTRO', 'RENE TAPIA', 'AQUILINO VERDUGUEZ', 'JUAN CARLOS CANO',
            'WILLIAM VASQUEZ', 'SANTIAGO QUIROZ', 'NOLVERTA QUIROZ', 'LUCIA LEDEZMA', 'CRISTINA TORRICO',
            'ISABEL MONTANO', 'MELQUIADES CASTRO', 'JULIA FERRUFINO', 'CASIMIRO CRUZ', 'ORLANDO BARRIOS',
            'EMETERIO CAMARA', 'MAXIMO CASTRO', 'PILAR CASTRO', 'AURORA CLAURE', 'GUIDO JUAREZ',
            'NELIDA CASTRO', 'FORTUNATA CLAURE', 'ELMER GUTIERREZ', 'FLORENCIA CHOQUE', 'POLICARPIO FERRUFINO',
            'NESTOR VARGAS', 'JUANA VILLARROEL', 'CASIANA TAPIA', 'ANDREA REA', 'ILDA ROCHA',
            'SEGUNDINA TORRICO', 'AURORA TAPIA', 'HERMOGENES TORRICO', 'JESUS SALAZAR', 'AURORA TAPIA',
            'DENIS TAPIA', 'VALERIO TERCEROS', 'SAN ISIDRO (TRANSP 15 MAYO)', 'VALERIO FLORES', 'EDWIN CASTRO',
            'LETICIA JORDAN', 'ROSA TAPIA', 'BETHY CASTRO', 'WILFREDO FUENTES', 'LUCRECIO TAPIA',
            'PRIMITIVA MIRANDA', 'WILLIAN VASQUEZ', 'HERNAN TERCEROS'
        ];

        // Crear socios y viviendas
        $zonasMap = [
            'TR' => ['zona' => $zonaTR, 'nombres' => $nombresTR],
            'VR' => ['zona' => $zonaVR, 'nombres' => $nombresVR],
            'SI' => ['zona' => $zonaSI, 'nombres' => $nombresSI],
        ];

        foreach ($zonasMap as $prefijo => $data) {
            foreach ($data['nombres'] as $index => $nombre) {
                $email = Str::slug($nombre) . '-' . $prefijo . '-' . ($index+1) . '@ejemplo.com';
                $usuario = User::updateOrCreate(
                    ['email' => $email],
                    ['name' => $nombre, 'password' => Hash::make('password'), 'role_id' => $socioRole->id]
                );

                $codigo = $prefijo . '-' . str_pad($index + 1, 3, '0', STR_PAD_LEFT);
                Vivienda::updateOrCreate(
                    ['codigo' => $codigo],
                    [
                        'user_id' => $usuario->id,
                        'zone_id' => $data['zona']->id,
                        'tarifa_id' => $tarifa->id,
                        'direccion' => "Sector {$data['zona']->name}, Conexión {$codigo}",
                    ]
                );
            }
        }

        // ======================== LECTURAS ENERO 2026 ========================

        $periodoEne = Periodo::updateOrCreate(
            ['nombre' => 'Enero 2026'],
            ['fecha_inicio' => '2026-01-01', 'fecha_fin' => '2026-01-31', 'estado' => 'abierto', 'gestion' => '2026']
        );

        $readingsTR = [
            [3047,3057],[1541,1543],[1390,1390],[337,338],[894,894],
            [63,63],[593,598],[149,149],[1708,1729],[975,979],
            [1051,1051],[1788,1790],[477,480],[3460,3466],[3455,3481],
            [307,307],[69,96],[2917,2994],[53,573],[2301,3203],
            [0,1454],[3335,3360],[1182,1194],[130,130],[2573,2576],
            [3115,3119],[208,212],[1530,1531],[4948,4962],[2325,2326],
            [1778,1793],[3636,3640],[1289,1299],[1561,1531],[587,593],
            [55,4],[3771,3778],[521,525],[418,420],[1819,1819],
            [2939,2949],[2265,2265],[5876,5902],[1513,1517],[1178,1180],
            [5232,5241],[4073,4110],[129,130],[2677,2688],[1,1],
            [1662,2112],[2238,2238],[560,560],[381,399],[739,739],
            [874,874],[251,0],[1,1],[1810,1813],[3041,3048],
            [3083,3086],[2138,2160],[1327,1336],[1198,1198],[2065,2070],
            [1356,1356],[987,987],[3939,3951],[1815,1823],[221,224],
            [3119,3124],[3381,3386],[2654,2655],[1500,2747],[1179,1187],
            [5792,5813],[2317,2326],[2640,2649],[161,163],[1015,1015],
            [4768,4794],[3084,3094],[1245,1251],[219,219],[348,367]
        ];

        $readingsVR = [
            [4192,4198],[1987,1990],[1447,1452],[1052,1061],[505,4341],[564,567],
            [1665,1665],[1519,1519],[112,112],[2633,2640],[7233,7252],[290,290],
            [462,1870],[1032,1032],[1485,1493],[5275,5289],[723,724],[3575,3589],
            [0,573],[3772,3801],[6673,6688],[0,474],[0,4478],[121,0],
            [0,0],[0,0],[365,374],[1370,1376]
        ];

        $readingsSI = [
            [2322,2329],[1712,1716],[433,435],[59,61],[4638,4649],[1704,1713],
            [533,534],[2354,2355],[3089,3095],[1236,1239],[841,841],[2227,2235],
            [9,9],[1083,1084],[1598,1598],[1427,1428],[3265,3265],[2301,2310],
            [770,770],[310,8310],[1488,1490],[567,568],[4707,4716],[121,0],
            [0,0],[0,0],[455,466],[6544,6552],[255,255],[656,656],
            [894,894],[416,422],[144,25],[5456,5487],[22,394],[156,163],
            [5,5],[9,9],[79,79],[2019,2029],[1552,1557],[5098,5111],
            [3905,3911],[5311,5391],[2546,2552],[4783,4810],[9939,9952],[3244,3253],
            [2270,2271],[702,705],[2230,2232],[1876,1877],[1670,1676],[2720,2732],
            [698,698],[394,0],[0,0],[0,9992],[1894,1908],[840,840],
            [1519,1542],[2886,2896],[288,289],[2105,2110],[185,186],[0,90],
            [270,273],[1010,1016],[559,559],[331,331],[1798,1802],[429,435],
            [3155,3164],[2809,2810],[265,266],[1242,1244],[2147,2150],[152,152],
            [138,38],[106,105],[230,235],[193,198],[334,334],[986,987],
            [1936,1938],[1428,1432],[1342,1352],[945,945],[62,65],[306,309],
            [1392,1397],[16,716],[16,22],[3198,3222],[916,916],[1428,1428],
            [40,40],[151,153],[1039,1039],[427,450],[1658,1659],[410,422],
            [287,287],[1031,1031],[0,0],[212,213],[177,177],[1229,1232],
            [158,159],[19,19],[305,346],[5,0],[52,55],[904,910],
            [165,165],[3588,3593],[1433,1427],[1233,1237],[0,0],[2540,2540],
            [1696,1701],[392,0],[1138,1140],[1507,1511],[1201,1201],[0,1427],
            [928,929],[637,639],[1286,1293],[82,88],[127,127],[0,1],
            [367,367],[174,174],[847,847],[882,882],[55,55],[0,0],
            [1344,1346],[3381,3382],[3395,3399],[2022,2024],[2038,2038],[3913,3935],
            [108,108],[45,45],[3757,3773],[0,0],[0,0],[1362,1371],
            [4549,4568],[1533,1535],[2680,2691],[689,696],[13,16],[1596,1596],
            [218,2197],[1056,1056],[1598,1600],[328,329],[125,125],[46,51],
            [1033,1034],[1433,1436],[1242,1251],[709,705],[943,947],[725,728],
            [3558,3562],[1067,1067],[3355,3361],[442,457],[1300,1302],[472,472],
            [2108,2116],[469,469],[930,932],[1729,1739],[136,0],[1338,1344],
            [409,434],[5505,5517],[0,0],[0,0],[0,0],[0,0],
            [0,0],[0,0],[241,248],[385,392],[0,0],[353,364],
            [140,145]
        ];

        $allReadings = [
            'TR' => $readingsTR,
            'VR' => $readingsVR,
            'SI' => $readingsSI,
        ];

        foreach ($allReadings as $prefix => $readings) {
            foreach ($readings as $index => $reading) {
                $codigo = $prefix . '-' . str_pad($index + 1, 3, '0', STR_PAD_LEFT);
                $vivienda = Vivienda::where('codigo', $codigo)->first();
                if (!$vivienda) continue;

                $prev = $reading[0];
                $curr = $reading[1];
                $consumo = max(0, $curr - $prev);

                Lectura::updateOrCreate(
                    ['vivienda_id' => $vivienda->id, 'periodo_id' => $periodoEne->id],
                    ['lectura_anterior' => $prev, 'lectura_actual' => $curr, 'consumo' => $consumo]
                );
            }
        }

        $this->command->info("✅ Seeded: " . count($nombresTR) . " TR + " . count($nombresVR) . " VR + " . count($nombresSI) . " SI socios/viviendas");
        $this->command->info("✅ Seeded: " . count($readingsTR) . " TR + " . count($readingsVR) . " VR + " . count($readingsSI) . " SI lecturas Enero 2026");
    }
}
