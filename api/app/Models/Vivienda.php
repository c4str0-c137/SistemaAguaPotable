<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vivienda extends Model
{
    protected $fillable = [
        'user_id', 
        'zone_id', 
        'tarifa_id', 
        'direccion', 
        'codigo',
        'latitude',
        'longitude',
        'alcantarillado',
        'tipo_lectura',
        'lectura_inicial'
    ];

    public function socio()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function zona()
    {
        return $this->belongsTo(Zone::class, 'zone_id');
    }

    public function tarifa()
    {
        return $this->belongsTo(Tarifa::class);
    }

    public function lecturas()
    {
        return $this->hasMany(Lectura::class);
    }

    public function pagos()
    {
        return $this->hasMany(Pago::class);
    }

    public function multas()
    {
        return $this->hasMany(Multa::class);
    }

    public function aportes()
    {
        return $this->hasMany(Aporte::class);
    }
}
