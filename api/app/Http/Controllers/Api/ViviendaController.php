<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ViviendaController extends Controller
{
    public function index()
    {
        $query = \App\Models\Vivienda::with(['socio', 'zona', 'tarifa']);
        if (request()->has('user_id')) {
            $query->where('user_id', request()->integer('user_id'));
        }
        return $query->get();
    }

    public function show($id)
    {
        return \App\Models\Vivienda::with(['socio', 'zona', 'tarifa'])->findOrFail($id);
    }

    public function store(Request $request)
    {
        $fields = $request->validate([
            'user_id'   => 'required|exists:users,id',
            'zone_id'   => 'required|exists:zones,id',
            'tarifa_id' => 'required|exists:tarifas,id',
            'codigo'    => 'required|string|unique:viviendas,codigo',
            'direccion' => 'required|string',
            'latitude'  => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'alcantarillado' => 'sometimes|string|in:ninguno,activo,inactivo',
            'tipo_lectura' => 'sometimes|string|in:mensual,anual',
            'lectura_inicial' => 'nullable|numeric',
        ]);

        $vivienda = \App\Models\Vivienda::create($fields);

        return response()->json($vivienda->load(['socio', 'zona', 'tarifa']), 201);
    }

    public function update(Request $request, $id)
    {
        $vivienda = \App\Models\Vivienda::findOrFail($id);

        $fields = $request->validate([
            'user_id'   => 'sometimes|exists:users,id',
            'zone_id'   => 'sometimes|exists:zones,id',
            'tarifa_id' => 'sometimes|exists:tarifas,id',
            'codigo'    => 'sometimes|string|unique:viviendas,codigo,' . $id,
            'direccion' => 'sometimes|string',
            'latitude'  => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'alcantarillado' => 'sometimes|string|in:ninguno,activo,inactivo',
            'tipo_lectura' => 'sometimes|string|in:mensual,anual',
            'lectura_inicial' => 'nullable|numeric',
        ]);

        $vivienda->update($fields);

        return response()->json($vivienda->load(['socio', 'zona', 'tarifa']));
    }

    public function destroy($id)
    {
        $vivienda = \App\Models\Vivienda::findOrFail($id);
        // Podríamos restringir borrado si tiene lecturas/pagos
        if ($vivienda->lecturas()->exists() || $vivienda->pagos()->exists()) {
             return response()->json(['error' => 'No se puede borrar una vivienda con historial de lecturas o pagos.'], 422);
        }
        $vivienda->delete();
        return response()->json(null, 204);
    }
}
