<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TarifaController extends Controller
{
    public function index()
    {
        return response()->json(\App\Models\Tarifa::with('rangos')->get());
    }
}
