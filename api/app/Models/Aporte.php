<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Aporte extends Model
{
    protected $fillable = ['vivienda_id', 'monto', 'motivo', 'pagado'];

    public function vivienda()
    {
        return $this->belongsTo(Vivienda::class);
    }
}
