<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CheckHeader
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $apiKey = config('ketua.api_key');
        if (!$apiKey) {
            $data['status']    = false;
            $data['message']  = "API key not configured";
            return new JsonResponse($data, 500);
        }

        if (isset($_SERVER['HTTP_APIKEY'])) {
            $providedKey = $_SERVER['HTTP_APIKEY'];
            if (hash_equals($apiKey, $providedKey)) {
                return $next($request);
            }
        }

        $data['status']    = false;
        $data['message']  = "Unauthorized Access";
        return new JsonResponse($data, 401);
    }
}
