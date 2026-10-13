<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

/**
 * K11: defense-in-depth for admin routes.
 *
 * checkLogin proves *a* session exists; this additionally proves the session
 * belongs to an ADMIN (user_type). Applied to state-changing admin endpoints
 * (block/unblock, credits, deletes) so a lower-privilege session cannot drive
 * them, and so any future non-admin session type is denied by default.
 */
class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        if (!Session::get('user_name')) {
            return redirect(url('/admin/login'));
        }

        if ((int) Session::get('user_type') !== 1) {
            return response()->json([
                'status'  => false,
                'message' => 'Forbidden: administrator privileges required.',
            ], 403);
        }

        return $next($request);
    }
}
