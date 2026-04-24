<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lectura extends Model
{
    protected $fillable = ['vivienda_id', 'periodo_id', 'lectura_anterior', 'lectura_actual', 'consumo', 'observaciones'];

    public function vivienda()
    {
        return $this->belongsTo(Vivienda::class);
    }

    public function periodo()
    {
        return $this->belongsTo(Periodo::class);
    }
}
