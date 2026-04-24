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
            $table->foreignId('tarifa_id')->nullable()->constrained('tarifas')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('viviendas', function (Blueprint $table) {
            $table->dropForeign(['tarifa_id']);
            $table->dropColumn('tarifa_id');
        });
    }
};
