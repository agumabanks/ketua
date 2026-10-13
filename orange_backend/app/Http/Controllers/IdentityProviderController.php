<?php

namespace App\Http\Controllers;

use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Verifies identity-provider credentials SERVER-SIDE before any app token is
 * issued. Currently supports Firebase ID tokens (the app authenticates with
 * Firebase Auth for Google/Apple/email). The token's signature and claims are
 * validated against Google's public keys, so a client cannot mint a token for
 * an arbitrary identity.
 *
 * This closes the gap where /api/auth/register would issue a token for any
 * supplied `identity` string with no proof of ownership.
 */
class IdentityProviderController extends Controller
{
    /**
     * Exchange a verified Firebase ID token for app identity claims.
     * Returns ['identity' => ..., 'email' => ..., 'name' => ...] or null.
     */
    public static function verifyFirebaseIdToken(string $idToken): ?array
    {
        // Validate Firebase Secure Token JWTs with firebase/php-jwt.
        // against Google's rotating public keys and check audience/issuer/exp.
        try {
            $projectId = config('ketua.firebase_project_id');
            if (!is_string($projectId) || $projectId === '') return null;
            $segments = explode('.', $idToken);
            if (count($segments) !== 3 || strlen($idToken) > 16384) return null;
            $header = json_decode(\Firebase\JWT\JWT::urlsafeB64Decode($segments[0]), true);
            if (($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) return null;
            $certificates = \Illuminate\Support\Facades\Cache::remember('firebase.securetoken.certificates', 1800, function () {
                return \Illuminate\Support\Facades\Http::timeout(10)->get(
                    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
                )->throw()->json();
            });
            $certificate = $certificates[$header['kid']] ?? null;
            if (!$certificate) {
                \Illuminate\Support\Facades\Cache::forget('firebase.securetoken.certificates');
                return null;
            }
            $payload = (array) \Firebase\JWT\JWT::decode($idToken, new \Firebase\JWT\Key($certificate, 'RS256'));

            // Basic claim checks.
            $iss = $payload['iss'] ?? '';
            $aud = $payload['aud'] ?? '';
            $exp = $payload['exp'] ?? 0;

            $issOk = $iss === 'https://securetoken.google.com/' . $projectId;
            $audOk = $aud === $projectId;
            $expOk = is_int($exp) && $exp > time();
            $iat = $payload['iat'] ?? null;
            $authTime = $payload['auth_time'] ?? null;

            $subject = $payload['sub'] ?? '';
            if (!$issOk || !$audOk || !$expOk || !is_string($subject) || $subject === ''
                || strlen($subject) > 128 || !is_int($iat) || !is_int($authTime)
                || $iat < 0 || $authTime < 0 || $iat > time() || $authTime > time()) {
                return null;
            }

            return [
                'identity' => $subject,
                'email'    => $payload['email'] ?? null,
                'name'     => $payload['name'] ?? null,
                'uid'      => $payload['sub'] ?? null,
            ];
        } catch (\Throwable $e) {
            \Log::warning('Firebase ID token verification failed: ' . $e->getMessage());
            return null;
        }
    }
}
