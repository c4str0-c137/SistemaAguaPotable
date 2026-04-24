<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Roles
        $adminRole = \App\Models\Role::create(['name' => 'Admin']);
        $lectorRole = \App\Models\Role::create(['name' => 'Lector']);

        // 2. Usuario Administrador
        \App\Models\User::factory()->create([
            'name' => 'Administrador',
            'email' => 'admin@agua.com',
            'password' => bcrypt('password'),
            'role_id' => $adminRole->id,
        ]);

        // 3. Zona
        $zonaNorte = \App\Models\Zone::create([
            'name' => 'Zona Norte',
            'description' => 'Sector norte de la ciudad'
        ]);

        // 4. Métodos de Pago
        \App\Models\PaymentMethod::create(['name' => 'Efectivo']);
        \App\Models\PaymentMethod::create(['name' => 'Transferencia']);

        // 5. Tarifas y Rangos
        $tarifaResidencial = \App\Models\Tarifa::create([
            'nombre' => 'Residencial',
            'monto_fijo' => 10.00
        ]);

        \App\Models\TarifaRango::create([
            'tarifa_id' => $tarifaResidencial->id,
            'desde' => 0,
            'hasta' => 20,
            'precio_metro' => 0.50
        ]);

        \App\Models\TarifaRango::create([
            'tarifa_id' => $tarifaResidencial->id,
            'desde' => 21,
            'hasta' => 50,
            'precio_metro' => 1.00
        ]);
    }
}
