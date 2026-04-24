<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pago extends Model
{
    protected $fillable = ['vivienda_id', 'payment_method_id', 'monto_total', 'fecha_pago', 'referencia'];

    protected $casts = [
        'fecha_pago' => 'datetime',
    ];

    public function vivienda()
    {
        return $this->belongsTo(Vivienda::class);
    }

    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function detalles()
    {
        return $this->hasMany(DetallePago::class);
    }
}
