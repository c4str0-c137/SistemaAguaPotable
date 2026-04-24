<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ViviendaController extends Controller
{
    public function index()
    {
        return \App\Models\Vivienda::with(['socio', 'zona', 'tarifa'])->get();
    }

    public function show($id)
    {
        return \App\Models\Vivienda::with(['socio', 'zona', 'tarifa'])->findOrFail($id);
    }

    public function update(Request $request, $id)
    {
        $vivienda = \App\Models\Vivienda::findOrFail($id);

        $fields = $request->validate([
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'direccion' => 'nullable|string',
        ]);

        $vivienda->update($fields);

        return $vivienda;
    }
}
