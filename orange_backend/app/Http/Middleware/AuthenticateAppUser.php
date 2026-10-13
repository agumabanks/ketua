<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * K01 — Per-user authentication for the mobile API.
 *
 * Resolves the acting user from a Sanctum bearer token (guard `app_users`).
 * Controllers must read the identity from `auth('app_users')->user()` and MUST
 * NOT trust a client-supplied `user_id` for ownership/balance decisions.
 *
 * Returns 401 JSON when the token is missing/invalid, and 403 when the
 * account is blocked.
 */
class AuthenticateAppUser
{
    public function handle(Request $request, Closure $next)
    {
        $user = auth('app_users')->user();

        if (!$user) {
            return new JsonResponse([
                'status'  => false,
                'message' => 'Unauthenticated. A valid bearer token is required.',
            ], 401);
        }

        // Blocked accounts cannot use the API.
        if ((int) $user->is_block === 1) {
            return new JsonResponse([
                'status'  => false,
                'message' => 'Your account has been blocked.',
            ], 403);
        }

        // Make the authenticated user's id available to controllers via a
        // request attribute as a convenience (still prefer the guard).
        $request->attributes->set('auth_user_id', $user->id);

        return $next($request);
    }
}
