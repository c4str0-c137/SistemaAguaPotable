<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Periodo;
use Illuminate\Http\Request;

class PeriodoController extends Controller
{
    public function index()
    {
        return response()->json(Periodo::orderBy('fecha_inicio', 'desc')->get());
    }

    public function store(Request $request)
    {
        $fields = $request->validate([
            'nombre'        => 'required|string',
            'fecha_inicio'  => 'required|date',
            'fecha_fin'     => 'required|date|after:fecha_inicio',
            'estado'        => 'in:abierto,cerrado',
        ]);

        $fields['estado'] = $fields['estado'] ?? 'abierto';

        if ($fields['estado'] === 'abierto') {
            // Cerramos cualquier período previo abierto para permitir la transición secuencial
            Periodo::where('estado', 'abierto')->update(['estado' => 'cerrado']);
        }

        $periodo = Periodo::create($fields);
        return response()->json($periodo, 201);
    }

    public function show($id)
    {
        return response()->json(Periodo::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $periodo = Periodo::findOrFail($id);

        if ($periodo->estado === 'cerrado' && !$request->has('estado')) {
            return response()->json(['error' => 'No se puede modificar un período cerrado.'], 422);
        }

        $fields = $request->validate([
            'nombre'       => 'sometimes|string',
            'fecha_inicio' => 'sometimes|date',
            'fecha_fin'    => 'sometimes|date',
            'estado'       => 'sometimes|in:abierto,cerrado',
        ]);

        if (isset($fields['estado']) && $fields['estado'] === 'abierto' && $periodo->estado !== 'abierto') {
            $existeAbierto = Periodo::where('estado', 'abierto')->where('id', '!=', $id)->exists();
            if ($existeAbierto) {
                return response()->json(['error' => 'Ya existe otro período abierto.'], 422);
            }
        }

        $periodo->update($fields);
        return response()->json($periodo);
    }

    public function activo()
    {
        $periodo = Periodo::where('estado', 'abierto')
            ->orderBy('fecha_inicio', 'desc')
            ->first();
        return response()->json($periodo);
    }
}
