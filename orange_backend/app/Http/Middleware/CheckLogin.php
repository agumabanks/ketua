<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

/**
 * Admin panel session guard.
 *
 * SECURITY: authentication is checked BEFORE the request reaches the
 * controller. The previous implementation called $next($request) first and
 * only redirected afterwards, which meant unauthenticated requests still
 * executed the controller (state changes) before being bounced. Now an
 * unauthenticated request never enters the controller at all.
 */
class CheckLogin
{
    public function handle(Request $request, Closure $next)
    {
        // Authenticate FIRST — do not run the controller for anonymous callers.
        if (!Session::get('user_name')) {
            return redirect(url('/admin/login'));
        }

        $response = $next($request);

        // No-store headers on authenticated responses.
        $response->headers->set('Cache-Control', 'nocache, no-store, max-age=0, must-revalidate');
        $response->headers->set('Pragma', 'no-cache');
        $response->headers->set('Expires', 'Sun, 02 Jan 2021 00:00:00 GMT');

        return $response;
    }
}
