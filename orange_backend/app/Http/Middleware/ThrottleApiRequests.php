<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;

/**
 * K16 — Layered API rate limiting.
 *
 * The mobile API is gated by a shared key (checkHeader) that ships inside the
 * APK and is therefore extractable by anyone. Gate-key secrecy is NOT a
 * security control, so this middleware enforces hard per-identity limits that
 * do not depend on the key:
 *
 *   - Authenticated requests are limited per USER id (the bearer token
 *     identity), which is the correct abuse boundary for a mobile client.
 *   - Unauthenticated requests (login/register, webhook-style, or gate-only
 *     endpoints) fall back to per-IP limiting.
 *
 * Two limits are applied and the FIRST one to trip wins:
 *   1. Per-minute burst (default 120/min) — absorbs normal client polling
 *      (presence heartbeats, feed scroll, chat polling).
 *   2. Per-hour sustained cap (default 6000/hour) — blunts slow-drip scraping
 *      and bulk-exfiltration scripts that stay under the per-minute ceiling.
 *
 * Keys are namespaced so an IP-based bucket and a user-based bucket never
 * collide. Responses are JSON (the whole API is JSON) with a 429 and a
 * Retry-After header.
 */
class ThrottleApiRequests
{
    /** Burst limit per minute. */
    protected int $perMinute = 120;

    /** Sustained cap per hour. */
    protected int $perHour = 6000;

    public function handle(Request $request, Closure $next)
    {
        // Prefer the authenticated user id (from auth.app_users / Sanctum),
        // then fall back to the client IP for unauthenticated traffic.
        $user = $request->user();
        $identity = $user ? 'u:' . $user->id : 'ip:' . $request->ip();

        $minuteKey = 'rl:min:' . $identity;
        $hourKey   = 'rl:hr:' . $identity;

        // --- per-minute burst ---
        if (RateLimiter::tooManyAttempts($minuteKey, $this->perMinute)) {
            return $this->buildRejection(RateLimiter::availableIn($minuteKey));
        }
        RateLimiter::hit($minuteKey, 60); // 1-minute decay window

        // --- per-hour sustained cap ---
        if (RateLimiter::tooManyAttempts($hourKey, $this->perHour)) {
            return $this->buildRejection(RateLimiter::availableIn($hourKey));
        }
        RateLimiter::hit($hourKey, 3600); // 1-hour decay window

        return $next($request);
    }

    protected function buildRejection(int $retryAfter): JsonResponse
    {
        return new JsonResponse([
            'status'  => false,
            'message' => 'Too many requests. Please slow down and try again shortly.',
        ], 429, [
            'Retry-After' => max(1, $retryAfter),
        ]);
    }
}
