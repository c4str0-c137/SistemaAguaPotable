<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class SocioController extends Controller
{
    public function index()
    {
        return response()->json(
            User::with(['role', 'viviendas.zona'])
                ->whereHas('role', fn($q) => $q->where('name', 'Socio')->orWhere('name', 'socio'))
                ->withCount('viviendas')
                ->orderBy('name')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $fields = $request->validate([
            'name'  => 'required|string',
            'email' => 'required|email|unique:users,email',
            'password' => 'nullable|string|min:6',
        ]);

        $roleId = \App\Models\Role::where('name', 'Socio')->value('id');

        $user = User::create([
            'name'     => $fields['name'],
            'email'    => $fields['email'],
            'password' => \Illuminate\Support\Facades\Hash::make($fields['password'] ?? 'password'),
            'role_id'  => $roleId,
        ]);

        return response()->json($user, 201);
    }

    public function show($id)
    {
        return response()->json(User::with(['viviendas.zona', 'role'])->findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $fields = $request->validate([
            'name'  => 'sometimes|string',
            'email' => 'sometimes|email|unique:users,email,' . $id,
            'password' => 'nullable|string|min:6',
        ]);

        if (isset($fields['password'])) {
            $fields['password'] = \Illuminate\Support\Facades\Hash::make($fields['password']);
        }

        $user->update($fields);
        return response()->json($user);
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);
        // Podríamos restringir borrado si tiene viviendas
        if ($user->viviendas()->exists()) {
            return response()->json(['error' => 'No se puede borrar un socio con viviendas registradas.'], 422);
        }
        $user->delete();
        return response()->json(null, 204);
    }
}
