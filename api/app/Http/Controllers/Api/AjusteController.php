<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ajuste;
use Illuminate\Http\Request;

class AjusteController extends Controller
{
    public function index()
    {
        return response()->json(Ajuste::all());
    }

    public function update(Request $request, $clave)
    {
        $ajuste = Ajuste::where('clave', $clave)->firstOrFail();
        $ajuste->update(['valor' => $request->valor]);
        return response()->json($ajuste);
    }
}
