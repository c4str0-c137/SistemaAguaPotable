<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AjusteController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LecturaController;
use App\Http\Controllers\Api\PagoController;
use App\Http\Controllers\Api\PaymentMethodController;
use App\Http\Controllers\Api\PeriodoController;
use App\Http\Controllers\Api\RoleController;
use App\Http\Controllers\Api\SocioController;
use App\Http\Controllers\Api\TarifaController;
use App\Http\Controllers\Api\TarifaRangoController;
use App\Http\Controllers\Api\ViviendaController;
use App\Http\Controllers\Api\ZoneController;

// ─── Auth (sin middleware) ────────────────────────────────────────────────────
Route::post('/login',  [AuthController::class, 'login']);

// ─── Rutas protegidas ─────────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', fn(Request $r) => $r->user());

    // Socios / Usuarios
    Route::apiResource('socios', SocioController::class);

    // Catálogos de solo lectura
    Route::get('/roles',   [RoleController::class, 'index']);
    Route::get('/zones',   [ZoneController::class, 'index']);
    Route::apiResource('tarifas', TarifaController::class);
    Route::apiResource('tarifa-rangos', TarifaRangoController::class);
    Route::get('/payment-methods', PaymentMethodController::class);

    // Ajustes del sistema
    Route::get('/ajustes',          [AjusteController::class, 'index']);
    Route::put('/ajustes/{clave}',  [AjusteController::class, 'update']);

    // Viviendas
    Route::apiResource('viviendas', ViviendaController::class);

    // Períodos
    Route::get('/periodos/activo', [PeriodoController::class, 'activo']);
    Route::apiResource('periodos', PeriodoController::class);

    // Lecturas
    Route::get('/lecturas/vivienda/{vivienda}', [LecturaController::class, 'byVivienda']);
    Route::apiResource('lecturas', LecturaController::class)->only(['index', 'store', 'show']);

    // Pagos
    Route::get('/pagos/resumen',   [PagoController::class, 'resumen']);
    Route::post('/pagos/calcular', [PagoController::class, 'calcularDeuda']);
    Route::get('/pagos/pagados-en-periodo', [PagoController::class, 'pagadosEnPeriodo']);
    Route::apiResource('pagos', PagoController::class)->only(['index', 'store', 'show', 'destroy']);
});
