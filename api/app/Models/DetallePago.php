<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DetallePago extends Model
{
    protected $fillable = ['pago_id', 'tipo', 'monto', 'descripcion'];

    public function pago()
    {
        return $this->belongsTo(Pago::class);
    }
}
