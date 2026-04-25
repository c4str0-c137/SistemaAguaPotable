<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AnnualTarifaSeeder extends Seeder
{
    public function run(): void
    {
        // Upsert tarifa anual
        $tarifaId = DB::table('tarifas')->where('tipo', 'anual')->value('id');

        if (!$tarifaId) {
            $tarifaId = DB::table('tarifas')->insertGetId([
                'nombre'     => 'Anual',
                'tipo'       => 'anual',
                'monto_fijo' => 60,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } else {
            DB::table('tarifas')->where('id', $tarifaId)->update([
                'monto_fijo' => 60,
                'updated_at' => now(),
            ]);
        }

        // Clear existing ranges for this tarifa
        DB::table('tarifa_rangos')->where('tarifa_id', $tarifaId)->delete();

        // First 60 m3 are included in the fixed fee (price = 0)
        DB::table('tarifa_rangos')->insert([
            'tarifa_id'    => $tarifaId,
            'desde'        => 0,
            'hasta'        => 60,
            'precio_metro' => 0,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        // Above 60 m3: extra charge per m3 (use same price as residential tier)
        DB::table('tarifa_rangos')->insert([
            'tarifa_id'    => $tarifaId,
            'desde'        => 61,
            'hasta'        => null,
            'precio_metro' => 1.5, // adjustable from settings
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);
    }
}
