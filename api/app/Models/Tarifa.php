<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tarifa extends Model
{
    protected $fillable = ['nombre', 'monto_fijo'];

    public function rangos()
    {
        return $this->hasMany(TarifaRango::class);
    }

    public function viviendas()
    {
        return $this->hasMany(Vivienda::class);
    }
}
