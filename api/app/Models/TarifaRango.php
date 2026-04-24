<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TarifaRango extends Model
{
    protected $fillable = ['tarifa_id', 'desde', 'hasta', 'precio_metro'];

    public function tarifa()
    {
        return $this->belongsTo(Tarifa::class);
    }
}
