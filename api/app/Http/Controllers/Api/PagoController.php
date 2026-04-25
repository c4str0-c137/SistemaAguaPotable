<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DetallePago;
use App\Models\Lectura;
use App\Models\Pago;
use App\Models\Vivienda;
use App\Models\Ajuste;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PagoController extends Controller
{
    /**
     * Calcular la deuda pendiente de una vivienda en un período dado.
     */
    public function calcularDeuda(Request $request)
    {
        $request->validate([
            'vivienda_id' => 'required|exists:viviendas,id',
            'periodo_id'  => 'required|exists:periodos,id',
        ]);

        $vivienda = Vivienda::with(['tarifa.rangos'])->findOrFail($request->vivienda_id);
        $lectura  = Lectura::where('vivienda_id', $request->vivienda_id)
            ->where('periodo_id', $request->periodo_id)
            ->first();

        if (!$lectura) {
            return response()->json(['error' => 'No hay lectura para este período'], 404);
        }

        $tarifa     = $vivienda->tarifa;
        $consumo    = (float)$lectura->consumo;
        $costoConsumo = 0;
        $montoFijo  = 0;
        $desgloceRangos = [];

        $isAnual = ($vivienda->tipo_lectura === 'anual');

        if ($isAnual) {
            $montoFijoDefault = (float)(Ajuste::where('clave', 'monto_fijo_anual')->value('valor') ?? 150);
            $montoFijo = ($tarifa && $tarifa->monto_fijo > 0) ? (float)$tarifa->monto_fijo : $montoFijoDefault;
            if ($tarifa) {
                $rangos = $tarifa->rangos->sortBy('desde');
                $remaining = $consumo;
                foreach ($rangos as $rango) {
                    if ($remaining <= 0) break;
                    $hasta = $rango->hasta ?? PHP_INT_MAX;
                    $desde = (float)$rango->desde;
                    $tamañoRango = ($desde == 0) ? (float)$hasta : ($hasta - $desde);
                    $consumoEnRango = min($remaining, $tamañoRango);
                    $costoParcial = $consumoEnRango * (float)$rango->precio_metro;
                    $costoConsumo += $costoParcial;
                    if ($consumoEnRango > 0 && $costoParcial > 0) {
                        $desgloceRangos[] = [
                            'desde' => $desde,
                            'hasta' => $rango->hasta,
                            'precio_metro' => $rango->precio_metro,
                            'metros' => round($consumoEnRango, 2),
                            'subtotal' => round($costoParcial, 2),
                        ];
                    }
                    $remaining = max(0, $remaining - $consumoEnRango);
                }
            }
        } else {
            $montoFijo = $tarifa ? (float)$tarifa->monto_fijo : 0;
            if ($tarifa) {
                $rangos = $tarifa->rangos->sortBy('desde');
                $remaining = $consumo;
                foreach ($rangos as $rango) {
                    if ($remaining <= 0) break;
                    $hasta = $rango->hasta ?? PHP_INT_MAX;
                    $desde = (float)$rango->desde;
                    $tamañoRango = ($desde == 0) ? (float)$hasta : ($hasta - $desde + 1);
                    $consumoEnRango = min($remaining, $tamañoRango);
                    $costoParcial = $consumoEnRango * (float)$rango->precio_metro;
                    $costoConsumo += $costoParcial;
                    if ($consumoEnRango > 0) {
                        $desgloceRangos[] = [
                            'desde' => $desde,
                            'hasta' => $rango->hasta,
                            'precio_metro' => $rango->precio_metro,
                            'metros' => round($consumoEnRango, 2),
                            'subtotal' => round($costoParcial, 2),
                        ];
                    }
                    $remaining = max(0, $remaining - $consumoEnRango);
                }
            }
            $costoConsumo = max($montoFijo, $costoConsumo);
            $montoFijo = 0;
        }

        // Multa por mora
        $multaMonto = (float)Ajuste::where('clave', 'multa_mora')->value('valor') ?? 0;
        $mesesMora  = (int)(Ajuste::where('clave', 'meses_mora_deudor')->value('valor') ?? 3);
        $pagosRealizados = Pago::where('vivienda_id', $request->vivienda_id)->count();
        $totalPeriodosConLectura = Lectura::where('vivienda_id', $request->vivienda_id)->count();
        $hayMora = ($totalPeriodosConLectura - $pagosRealizados) >= $mesesMora;
        $multa   = $hayMora ? $multaMonto : 0;

        // Alcantarillado
        $costoAlcantarillado = match($vivienda->alcantarillado) {
            'activo'   => 8,
            'inactivo' => 5,
            default    => 0,
        };

        $montoTotal = $montoFijo + $costoConsumo + $multa + $costoAlcantarillado;

        return response()->json([
            'vivienda_id'          => $vivienda->id,
            'codigo'               => $vivienda->codigo,
            'periodo_id'           => $request->periodo_id,
            'lectura_anterior'     => $lectura->lectura_anterior,
            'lectura_actual'       => $lectura->lectura_actual,
            'consumo'              => $lectura->consumo,
            'monto_fijo'           => $montoFijo,
            'costo_consumo'        => round($costoConsumo, 2),
            'monto_alcantarillado' => $costoAlcantarillado,
            'multa'                => $multa,
            'monto_total'          => round($montoTotal, 2),
            'hay_mora'             => $hayMora,
            'is_anual'             => $isAnual,
            'desgloce_rangos'      => $desgloceRangos,
            'tarifa_nombre'        => $tarifa?->nombre ?? 'Sin tarifa',
        ]);
    }

    /**
     * Registrar un pago.
     */
    public function store(Request $request)
    {
        $fields = $request->validate([
            'vivienda_id'       => 'required|exists:viviendas,id',
            'periodo_id'        => 'required|exists:periodos,id',
            'payment_method_id' => 'nullable|exists:payment_methods,id',
            'monto_total'       => 'required|numeric|min:0',
            'costo_consumo'     => 'nullable|numeric',
            'monto_alcantarillado' => 'nullable|numeric',
            'multa'             => 'nullable|numeric',
            'referencia'        => 'nullable|string',
            'observaciones'     => 'nullable|string',
            'lectura_anterior'  => 'nullable|integer',
            'lectura_actual'    => 'nullable|integer',
            'consumo'           => 'nullable|integer',
            'desgloce_rangos'   => 'nullable|array',
            'otros_detalles'    => 'nullable|array',
            'otros_detalles.*.tipo'   => 'required|string',
            'otros_detalles.*.monto'  => 'required|numeric',
            'otros_detalles.*.descripcion' => 'required|string',
        ]);

        DB::beginTransaction();
        try {
            $pago = Pago::create([
                'vivienda_id'       => $fields['vivienda_id'],
                'periodo_id'        => $fields['periodo_id'],
                'payment_method_id' => $fields['payment_method_id'] ?? 1, 
                'monto_total'       => $fields['monto_total'],
                'fecha_pago'        => now(),
                'referencia'        => $fields['referencia'] ?? null,
                'lectura_anterior'  => $fields['lectura_anterior'] ?? null,
                'lectura_actual'    => $fields['lectura_actual'] ?? null,
                'consumo'           => $fields['consumo'] ?? null,
                'desgloce_rangos'   => $fields['desgloce_rangos'] ?? null,
            ]);

            // Crear detalles del pago
            if (!empty($fields['monto_fijo']) && $fields['monto_fijo'] > 0) {
                DetallePago::create([
                    'pago_id'     => $pago->id,
                    'tipo'        => 'cargo_fijo',
                    'monto'       => $fields['monto_fijo'],
                    'descripcion' => 'Cargo fijo mensual',
                ]);
            }
            if (!empty($fields['costo_consumo']) && $fields['costo_consumo'] > 0) {
                DetallePago::create([
                    'pago_id'     => $pago->id,
                    'tipo'        => 'consumo',
                    'monto'       => $fields['costo_consumo'],
                    'descripcion' => 'Consumo de agua',
                ]);
            }
            if (!empty($fields['multa']) && $fields['multa'] > 0) {
                DetallePago::create([
                    'pago_id'     => $pago->id,
                    'tipo'        => 'multa',
                    'monto'       => $fields['multa'],
                    'descripcion' => 'Multa por mora',
                ]);
            }
            if (!empty($fields['monto_alcantarillado']) && $fields['monto_alcantarillado'] > 0) {
                DetallePago::create([
                    'pago_id'     => $pago->id,
                    'tipo'        => 'alcantarillado',
                    'monto'       => $fields['monto_alcantarillado'],
                    'descripcion' => 'Servicio de alcantarillado',
                ]);
            }

            // Otros detalles opcionales (Aportes, Multas adicionales, etc)
            if (!empty($fields['otros_detalles'])) {
                foreach ($fields['otros_detalles'] as $detalle) {
                    if ($detalle['monto'] > 0) {
                        DetallePago::create([
                            'pago_id'     => $pago->id,
                            'tipo'        => $detalle['tipo'],
                            'monto'       => $detalle['monto'],
                            'descripcion' => $detalle['descripcion'],
                        ]);
                    }
                }
            }

            DB::commit();
            return response()->json($pago->load(['vivienda.socio', 'vivienda.zona', 'periodo', 'detalles']), 201);
        } catch (\Exception $e) {
            DB::rollback();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Listar pagos (con filtros opcionales).
     */
    public function index(Request $request)
    {
        $query = Pago::with(['vivienda.socio', 'vivienda.zona', 'detalles', 'paymentMethod']);

        if ($request->filled('vivienda_id')) {
            $query->where('vivienda_id', $request->vivienda_id);
        }

        return response()->json($query->orderBy('fecha_pago', 'desc')->get());
    }

    /**
     * Ver un pago en detalle.
     */
    public function show($id)
    {
        return response()->json(
            Pago::with(['vivienda.socio', 'vivienda.zona', 'detalles', 'paymentMethod'])->findOrFail($id)
        );
    }

    /**
     * Retorna los IDs de viviendas que ya tienen pago en un período.
     */
    public function pagadosEnPeriodo(Request $request)
    {
        $request->validate(['periodo_id' => 'required|exists:periodos,id']);

        $ids = Pago::where('periodo_id', $request->periodo_id)
            ->pluck('vivienda_id')
            ->unique()
            ->values();

        return response()->json($ids);
    }

    /**
     * Eliminar un pago (solo en caso de error).
     */
    public function destroy($id)
    {
        $pago = Pago::findOrFail($id);
        $pago->detalles()->delete();
        $pago->delete();
        return response()->json(['message' => 'Pago eliminado']);
    }

    /**
     * Resumen para el dashboard: estadísticas del mes activo.
     */
    public function resumen()
    {
        $totalPagos    = Pago::count();
        $totalMonto    = Pago::sum('monto_total');
        $pagosDelMes   = Pago::whereMonth('fecha_pago', now()->month)
                             ->whereYear('fecha_pago', now()->year)
                             ->count();
        $montoDelMes   = Pago::whereMonth('fecha_pago', now()->month)
                             ->whereYear('fecha_pago', now()->year)
                             ->sum('monto_total');
        $totalViviendas = Vivienda::count();
        $pagadas        = Pago::whereMonth('fecha_pago', now()->month)
                              ->whereYear('fecha_pago', now()->year)
                              ->distinct('vivienda_id')
                              ->count('vivienda_id');

        return response()->json([
            'total_pagos'       => $totalPagos,
            'total_monto'       => round($totalMonto, 2),
            'pagos_del_mes'     => $pagosDelMes,
            'monto_del_mes'     => round($montoDelMes, 2),
            'total_viviendas'   => $totalViviendas,
            'viviendas_pagadas' => $pagadas,
            'viviendas_pendientes' => $totalViviendas - $pagadas,
        ]);
    }
}
