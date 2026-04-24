<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\RoleController;
use App\Http\Controllers\Api\ZoneController;
use App\Http\Controllers\Api\TarifaController;

use App\Http\Controllers\Api\ViviendaController;

Route::apiResource('viviendas', ViviendaController::class)->middleware('auth:sanctum');

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

Route::get('/roles', [RoleController::class, 'index']);
Route::get('/zones', [ZoneController::class, 'index']);
Route::get('/tarifas', [TarifaController::class, 'index']);
