<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $fields = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string'
        ]);

        $user = \App\Models\User::where('email', $fields['email'])->with('role')->first();

        if (!$user || !\Illuminate\Support\Facades\Hash::check($fields['password'], $user->password)) {
            return response([
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        $token = $user->createToken('myapptoken')->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response()->json($response, 201);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return [
            'message' => 'Sesión cerrada'
        ];
    }
}
