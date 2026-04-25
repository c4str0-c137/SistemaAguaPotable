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
        // SQLite doesn't support MODIFY COLUMN, so we recreate the table
        Schema::rename('detalle_pagos', 'detalle_pagos_old');

        Schema::create('detalle_pagos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pago_id')->constrained('pagos')->onDelete('cascade');
            $table->string('tipo'); 
            $table->decimal('monto', 10, 2);
            $table->string('descripcion');
            $table->timestamps();
        });

        DB::statement("INSERT INTO detalle_pagos (id, pago_id, tipo, monto, descripcion, created_at, updated_at) 
                       SELECT id, pago_id, tipo, monto, descripcion, created_at, updated_at FROM detalle_pagos_old");

        Schema::dropIfExists('detalle_pagos_old');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('detalle_pagos');
    }
};
