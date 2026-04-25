<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TarifaController extends Controller
{
    public function index()
    {
        return response()->json(\App\Models\Tarifa::with('rangos')->orderBy('id')->get());
    }

    public function store(Request $request)
    {
        $fields = $request->validate([
            'nombre'     => 'required|string',
            'monto_fijo' => 'required|numeric|min:0',
        ]);
        $tarifa = \App\Models\Tarifa::create($fields);
        return response()->json($tarifa, 201);
    }

    public function update(Request $request, $id)
    {
        $tarifa = \App\Models\Tarifa::findOrFail($id);
        $fields = $request->validate([
            'nombre'     => 'sometimes|string',
            'monto_fijo' => 'sometimes|numeric|min:0',
        ]);
        $tarifa->update($fields);
        return response()->json($tarifa);
    }

    public function destroy($id)
    {
        $tarifa = \App\Models\Tarifa::findOrFail($id);
        if ($tarifa->viviendas()->exists()) {
            return response()->json(['error' => 'No se puede borrar una tarifa en uso por viviendas.'], 422);
        }
        $tarifa->delete();
        return response()->json(null, 204);
    }
}
