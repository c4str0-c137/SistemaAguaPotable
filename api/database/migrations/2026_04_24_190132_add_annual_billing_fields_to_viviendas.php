<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('viviendas', function (Blueprint $table) {
            $table->string('tipo_lectura')->default('mensual'); // mensual, anual
            $table->double('lectura_inicial')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('viviendas', function (Blueprint $table) {
            //
        });
    }
};
