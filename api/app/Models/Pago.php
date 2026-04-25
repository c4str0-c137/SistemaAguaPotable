<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pago extends Model
{
    protected $fillable = [
        'vivienda_id', 
        'periodo_id', 
        'payment_method_id', 
        'monto_total', 
        'fecha_pago', 
        'referencia',
        'lectura_anterior',
        'lectura_actual',
        'consumo',
        'desgloce_rangos'
    ];

    protected $casts = [
        'fecha_pago' => 'datetime',
        'desgloce_rangos' => 'array',
    ];

    public function vivienda()
    {
        return $this->belongsTo(Vivienda::class);
    }

    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function periodo()
    {
        return $this->belongsTo(Periodo::class);
    }

    public function detalles()
    {
        return $this->hasMany(DetallePago::class);
    }
}
