<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lectura;
use App\Models\Vivienda;
use Illuminate\Http\Request;

class LecturaController extends Controller
{
    public function index(Request $request)
    {
        $query = Lectura::with(['vivienda.socio', 'vivienda.zona', 'periodo']);

        if ($request->filled('periodo_id')) {
            $query->where('lecturas.periodo_id', $request->periodo_id);
        }

        if ($request->filled('vivienda_id')) {
            $query->where('lecturas.vivienda_id', $request->vivienda_id);
        }

        if ($request->filled('zona_id')) {
            $query->whereHas('vivienda', function ($q) use ($request) {
                $q->where('zone_id', $request->zona_id);
            });
        }

        return response()->json($query->join('periodos', 'lecturas.periodo_id', '=', 'periodos.id')
            ->orderBy('periodos.fecha_inicio', 'desc')
            ->select('lecturas.*')
            ->get());
    }

    public function store(Request $request)
    {
        $fields = $request->validate([
            'vivienda_id'     => 'required|exists:viviendas,id',
            'periodo_id'      => 'required|exists:periodos,id',
            'lectura_anterior'=> 'required|numeric|min:0',
            'lectura_actual'  => 'required|numeric|min:0',
            'observaciones'   => 'nullable|string',
        ]);

        $periodo = \App\Models\Periodo::findOrFail($fields['periodo_id']);
        $existeLectura = Lectura::where('vivienda_id', $fields['vivienda_id'])
            ->where('periodo_id', $fields['periodo_id'])
            ->exists();

        // Se permite registrar lecturas incluso en periodos cerrados para facilitar carga histórica
        // $if ($periodo->estado === 'cerrado' && !$existeLectura) { ... }

        $consumo = max(0, $fields['lectura_actual'] - $fields['lectura_anterior']);
        $fields['consumo'] = $consumo;

        $lectura = Lectura::updateOrCreate(
            ['vivienda_id' => $fields['vivienda_id'], 'periodo_id' => $fields['periodo_id']],
            $fields
        );

        return response()->json($lectura->load(['vivienda.socio', 'periodo']), 201);
    }

    public function show($id)
    {
        return response()->json(
            Lectura::with(['vivienda.socio', 'vivienda.zona', 'periodo'])->findOrFail($id)
        );
    }

    public function byVivienda($viviendaId)
    {
        $lecturas = Lectura::with(['periodo'])
            ->join('periodos', 'lecturas.periodo_id', '=', 'periodos.id')
            ->where('vivienda_id', $viviendaId)
            ->orderBy('periodos.fecha_inicio', 'desc')
            ->select('lecturas.*')
            ->get();
        return response()->json($lecturas);
    }
}
