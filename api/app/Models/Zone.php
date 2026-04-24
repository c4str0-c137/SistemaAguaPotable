<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    protected $fillable = ['name', 'description'];

    public function viviendas()
    {
        return $this->hasMany(Vivienda::class);
    }
}
