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

class LegacyDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Roles
        $adminRole = Role::firstOrCreate(['name' => 'Admin']);
        $lectorRole = Role::firstOrCreate(['name' => 'Lector']);
        $socioRole = Role::firstOrCreate(['name' => 'Socio']);

        // 1.5 Métodos de Pago
        $efectivo = \App\Models\PaymentMethod::firstOrCreate(['name' => 'Efectivo'], ['description' => 'Pago en efectivo']);

        // 2. Administrador Principal
        User::updateOrCreate(
            ['email' => 'admin@agua.com'],
            [
                'name' => 'ADMINISTRADOR',
                'password' => Hash::make('password'),
                'role_id' => $adminRole->id,
            ]
        );

        // 3. Zonas
        $zonaTR = Zone::updateOrCreate(['name' => 'Tojlu Rancho'], ['description' => 'Sector Tojlu Rancho']);
        $zonaVR = Zone::updateOrCreate(['name' => 'Villa Rosario'], ['description' => 'Sector Villa Rosario']);
        $zonaSI = Zone::updateOrCreate(['name' => 'San Isidro'], ['description' => 'Sector San Isidro']);

        // 4. Tarifa General
        $tarifa = Tarifa::updateOrCreate(['nombre' => 'Tarifa General'], ['monto_fijo' => 8.00]);
        $rangos = [];
        // Base range 0-20 at 1.50
        $rangos[] = ['desde' => 0, 'hasta' => 20, 'precio_metro' => 1.50];
        
        $precio = 1.50;
        // Escalones de 10m3: 21-30, 31-40, etc.
        for ($i = 21; $i <= 500; $i += 10) {
            $precio += 1.50;
            $rangos[] = [
                'desde' => $i,
                'hasta' => $i + 9,
                'precio_metro' => $precio
            ];
        }
        // Last one till null
        $rangos[count($rangos)-1]['hasta'] = null;
        foreach ($rangos as $rango) {
            TarifaRango::updateOrCreate(['tarifa_id' => $tarifa->id, 'desde' => $rango['desde']], $rango);
        }

        // 5. Ajustes
        Ajuste::updateOrCreate(['clave' => 'multa_mora'], ['valor' => '5.00', 'descripcion' => 'Monto de multa por mora']);
        Ajuste::updateOrCreate(['clave' => 'meses_mora_deudor'], ['valor' => '3', 'descripcion' => 'Meses para ser considerado deudor']);
        Ajuste::updateOrCreate(['clave' => 'dia_vencimiento'], ['valor' => '15', 'descripcion' => 'Día del mes de vencimiento']);

        // 6. Socios y Viviendas
        $nombresTR = ["CLAUDIO VARGAS", "CRISTOBAL JALDIN", "FELIPE VELIZ", "ISABEL JALDIN", "SOFIA QUIROZ", "LUIS TAPIA", "ISABEL VASQUEZ", "HILARIA COLQUE", "MIRTHA TAPIA", "GENARO CASTRO", "FACUNDO CASTRO", "NATIVIDAD QUIROZ", "EDILBERTO TAPIA", "GIOVANA ALVAREZ", "GUMERCINDO ALVAREZ", "HORTENCIA CLAROS", "GERARDO JORDAN", "NIVARDO CALUSTRO", "ALICIA CAMARA", "ANDREA SOTO", "ROBERT CASTRO", "EMETERIO ZAPATA", "EDMUNDO TAPIA", "CLAUDINA CALUSTRO", "SABINA CALUSTRO", "ROXANA CRUZ", "PASTOR MONTAÑO", "FOTUNATO MONTAÑO", "LILIANA SAUSA VEIZAGA", "EVARISTO PLATA", "ORLANDO JORDAN", "MARTHA ROJAS", "CASIANO PANIAGUA", "JOSE BARRIENTOS", "CELIA JORDAN", "LEONORA VARGAS", "WILDER CRUZ", "EDELMIRA FERRUFINO", "RUBEN MONTAÑO", "CRISTINA JORDAN", "RENE SAGARDIA", "FRANCISCA MONTAÑO", "ROSA TAPIA", "FRANCISCO SAGARDIA", "MODESTA CALUSTRO", "OLGA TAPIA", "EFRAIN TAPIA", "VILMA MONTAÑO", "MARIA REA", "BRYAN PANIAGUA", "LUCIA CALUSTRO", "MOISE TAPIA", "VALENTIN CLAURE", "PRIMITIVA CASTRO", "LIMBER CASTRO", "CONSTANTINO BARRIENTOS", "ROSMERY MONTAÑO", "LUCIA DE SAGARDIA", "LUISA FERRUFINO", "JULIO CAMACHO", "ANGELINA BARRIENTOS", "JULIA BARRIENTOS", "EMETERIO GUTIERREZ", "SONIA CASTRO", "SABINA CASTRO", "MIGUELINA VARGAS", "EUSEBIO VILLCA", "APOLONIA VARGAS", "MARIA DE VARGAS", "PANFILO CHOQUE", "EDWIN CASTRO", "ROMULO FUENTES", "CONCEPCION CALUSTRO", "CASIANO CALUSTRO", "ADELAIDA CALUSTRO", "ANDREA REA", "MARCO MERINO", "EMILIA BARRIENTOS", "ESTEBAN BARRIENTOS", "MELICIA LEDEZMA", "VALERIO RAMIREZ"];
        $nombresVR = ['BENEDICTA FERRUFINO', 'CRISTINA FERREL', 'GERARDO ZAPATA', 'ROGELIO CASTRO', 'RUFINO VERDUGUEZ', 'MARCIAL FERRUFINO', 'FELICIDAD SAGARDIA', 'FAQUINA VILLARROEL', 'LEONARDA CALUSTRO', 'MARTA GIMENEZ', 'CONSTANTINO ZURITA', 'KARMINIA ZAPATA', 'ROLANDO TERCEROS', 'SANTIAGO REA', 'MACARIO CASTRO', 'VILMA TERCEROS', 'ISMAEL JALDIN', 'JAIME JALDIN', 'INDALICIO CASTRO', 'SERAFINA QUIROS', 'PEDRO VILLARROEL', 'PEPE ZURITA', 'LUSBERT CLAROS', 'EDWIN CASTRO'];
        $nombresSI = ['ANTONIO SAGARDIA', 'INDALICIO CASTRO', 'INOCENCIA CASTRO', 'ISIDRO JALDIN', 'ISMAEL CASTRO', 'INOCENTE TAPIA', 'INOCENCIA CASTRO', 'IVAN CASTRO', 'INOCENCIO CASTRO', 'ISABEL CASTRO', 'INDALECIO CASTRO'];

        $zonasMap = [
            'TR' => ['zona' => $zonaTR, 'nombres' => $nombresTR],
            'VR' => ['zona' => $zonaVR, 'nombres' => $nombresVR],
            'SI' => ['zona' => $zonaSI, 'nombres' => $nombresSI],
        ];

        foreach ($zonasMap as $prefijo => $data) {
            foreach ($data['nombres'] as $index => $nombre) {
                $email = Str::slug($nombre) . '-' . $prefijo . '@ejemplo.com';
                $usuario = User::updateOrCreate(
                    ['email' => $email],
                    [
                        'name' => $nombre,
                        'password' => Hash::make('password'),
                        'role_id' => $socioRole->id,
                    ]
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

        // 7. Periodos (Starting from 2026 only)
        $periodoEne = Periodo::updateOrCreate(
            ['nombre' => 'Enero 2026'],
            ['fecha_inicio' => '2026-01-01', 'fecha_fin' => '2026-01-31', 'estado' => 'abierto', 'gestion' => '2026']
        );

        // 8. Initial Readings for Jan (Minimum consumption 5m3)
        foreach (Vivienda::all() as $vivienda) {
            Lectura::updateOrCreate(
                ['vivienda_id' => $vivienda->id, 'periodo_id' => $periodoEne->id],
                ['lectura_anterior' => 0, 'lectura_actual' => 5, 'consumo' => 5, 'createdAt' => now()]
            );
        }
    }
}
