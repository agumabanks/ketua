<?php

namespace App\Http\Controllers;

use App\Models\AppData;
use App\Models\Myfunction;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

/**
 * K01/K04/K05/K12 — Authenticated entry points for the mobile API.
 *
 * Issues per-user Sanctum bearer tokens. Social-login registration keys off a
 * provider identity and NEVER stores or compares a plaintext password.
 *
 * IMPORTANT (mission rule): authentication and login here never set
 * `is_verified`. Identity verification is a separate, admin-approved flow
 * (VerificationRequest) and is never granted by login or payment.
 */
class AuthController extends Controller
{
    /**
     * Register or sign-in a user via a VERIFIED identity provider.
     * POST /api/auth/register  { id_token, fullname?, device_token?, device_type?, login_type? }
     *
     * SECURITY: the acting identity is taken from a server-verified provider
     * token (Firebase ID token), NEVER from a client-supplied `identity` string.
     * Without a valid id_token, no app token is issued. (A testing-only escape
     * hatch exists behind KETUA_ALLOW_UNVERIFIED_REGISTER for the isolated
     * test suite; it is OFF in production.)
     */
    public function register(Request $request)
    {
        $allowUnverified = app()->environment('testing')
            && config('database.connections.mysql.database') === 'ketua_test'
            && (bool) config('ketua.allow_unverified_register', false);

        $identity = null;
        $verifiedName = null;

        if ($request->filled('id_token')) {
            $claims = IdentityProviderController::verifyFirebaseIdToken($request->input('id_token'));
            if ($claims === null || empty($claims['identity'])) {
                return response()->json(['status' => false, 'message' => 'Invalid or expired identity token.'], 401);
            }
            $identity = $claims['identity'];
            $verifiedName = $claims['name'];
        } elseif ($allowUnverified) {
            // Testing only. Never enabled in production.
            $validator0 = Validator::make($request->all(), ['identity' => 'required|string|max:255']);
            if ($validator0->fails()) {
                return response()->json(['status' => false, 'message' => $validator0->errors()->first()]);
            }
            $identity = $request->input('identity');
        } else {
            return response()->json([
                'status'  => false,
                'message' => 'A verified identity token (id_token) is required.',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'fullname'      => 'nullable|string|max:255',
            'device_token'  => 'nullable|string',
            'device_type'   => 'nullable|string|in:1,2',
            'login_type'    => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $appData = AppData::first();
        $freeCoins = (int) ($appData->new_user_free_coins ?? 0);

        $user = Users::where('identity', $identity)->first();

        if ($user !== null && (int) $user->is_block === 1) {
            return response()->json(['status' => false, 'message' => 'Account unavailable.'], 403);
        }

        $isNew = false;
        if ($user === null) {
            $isNew = true;
            $user = new Users();
            $user->identity     = $identity;
            $user->fullname     = Myfunction::customReplace($verifiedName ?? $request->fullname ?? 'User');
            // The stock scaffold requires name/email/password NOT NULL. Populate
            // them deterministically from the verified identity WITHOUT storing a
            // usable password (random hash). Auth is token-based, not password.
            $user->name         = $identity;
            $user->email        = filter_var($identity, FILTER_VALIDATE_EMAIL)
                ? $identity
                : $identity . '@ketua.local';
            $user->password     = Hash::make(\Illuminate\Support\Str::random(32));
            $user->wallet       = $freeCoins;
            $user->total_collected = $freeCoins;
            $user->coins        = $freeCoins;
            $user->username     = $this->generateUniqueUsername();
            $user->is_verified  = 0;   // never auto-verified
            $user->can_go_live  = 0;
            $user->is_fake      = 0;
        }

        $user->device_token = $request->device_token ?? $user->device_token;
        $user->device_type  = $request->device_type ?? $user->device_type;
        $user->login_type   = $request->login_type ?? $user->login_type;
        $user->save();

        $token = $user->createToken('mobile')->plainTextToken;

        $user->load('images');

        return response()->json([
            'status'  => true,
            'message' => $isNew ? 'Registered successfully.' : 'Logged in successfully.',
            'is_new'  => $isNew,
            'token'   => $token,
            'data'    => $user,
        ]);
    }

    /** Number-first routing only: never authenticates or returns account details. */
    public function resolvePhone(Request $request)
    {
        $number = preg_replace('/[\s()\-]/', '', (string) $request->input('phone'));
        if (!preg_match('/^\+[1-9][0-9]{7,14}$/', $number)) {
            return response()->json(['status'=>false,'message'=>'Enter a phone number with its country code.'],422);
        }
        $exists = Users::where('identity','phone:' . hash('sha256',$number))->exists();
        return response()->json(['status'=>true,'next'=>$exists ? 'password' : 'create']);
    }

    /** Phone/password accounts are local accounts; phone ownership is unverified. */
    public function registerPhone(Request $request)
    {
        $number = preg_replace('/[\s()\-]/', '', (string) $request->input('phone'));
        $request->merge(['phone' => $number]);
        $v = Validator::make($request->all(), [
            'phone' => ['required', 'regex:/^\+[1-9][0-9]{7,14}$/'],
            'password' => 'required|string|min:12|max:128|confirmed',
            'fullname' => 'required|string|min:2|max:100',
            'device_token' => 'nullable|string|max:4096',
        ]);
        if ($v->fails()) return response()->json(['status' => false, 'message' => $v->errors()->first()], 422);
        $identity = 'phone:' . hash('sha256', $number);
        if (Users::where('identity', $identity)->exists()) {
            return response()->json(['status' => false, 'message' => 'Unable to register. Try signing in or contact support.'], 409);
        }
        try {
            $user = new Users();
            $user->identity = $identity;
            $user->name = $identity;
            // The unique email column also prevents concurrent duplicate accounts.
            $user->email = hash('sha256', $number) . '@phone.ketua.local';
            $user->fullname = Myfunction::customReplace($request->fullname);
            $user->password = Hash::make($request->password);
            $user->username = $this->generateUniqueUsername();
            $user->wallet = $user->coins = $user->total_collected = 0;
            $user->is_verified = $user->can_go_live = $user->is_fake = 0;
            $user->login_type = 4;
            $user->device_token = $request->device_token;
            $user->save();
            $token = $user->createToken('mobile')->plainTextToken;
            $user->load('images');
            return response()->json(['status' => true, 'message' => 'Registered. Phone ownership is unverified.', 'token' => $token, 'data' => $user]);
        } catch (\Illuminate\Database\QueryException $e) {
            return response()->json(['status' => false, 'message' => 'Unable to register. Try signing in or contact support.'], 409);
        }
    }

    public function loginPhone(Request $request)
    {
        $number = preg_replace('/[\s()\-]/', '', (string) $request->input('phone'));
        if (!preg_match('/^\+[1-9][0-9]{7,14}$/', $number)) {
            return response()->json(['status' => false, 'message' => 'Enter a phone number with its country code.'], 422);
        }
        $request->merge(['identity' => 'phone:' . hash('sha256', $number)]);
        return $this->login($request);
    }

    /**
     * Password login (for accounts that have a real password set, e.g. admins
     * created via the panel). Compares with Hash::check — never plaintext.
     * POST /api/auth/login { identity, password }
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'identity' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user = Users::where('identity', $request->identity)->first();

        // Must exist, have a real (bcrypt) password, and match.
        if (!$user || (int) $user->is_block === 1 || !$this->hasRealPassword($user) || !Hash::check($request->password, $user->password)) {
            return response()->json(['status' => false, 'message' => 'Invalid credentials']);
        }

        if ($request->filled('device_token')) {
            $user->device_token = $request->device_token;
            $user->device_type  = $request->device_type ?? $user->device_type;
            $user->save();
        }

        $token = $user->createToken('mobile')->plainTextToken;
        $user->load('images');

        return response()->json([
            'status'  => true,
            'message' => 'Login successful',
            'token'   => $token,
            'data'    => $user,
        ]);
    }

    /**
     * Logout: revoke the current token.
     * POST /api/auth/logout  (auth)
     */
    public function logout(Request $request)
    {
        $user = auth('app_users')->user();
        if ($user) { $user->device_token=null; $user->save(); }
        if ($user && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }
        return response()->json(['status' => true, 'message' => 'Logged out successfully.']);
    }

    /**
     * Heuristic: distinguish a real bcrypt password from the random hash we set
     * for social-login accounts. Both are bcrypt, so we instead mark social
     * accounts by a sentinel. Simpler & safe: treat all as password-capable and
     * rely on Hash::check — a random 32-char secret will simply never match.
     */
    private function hasRealPassword(Users $user): bool
    {
        return !empty($user->password) && \Illuminate\Support\Str::startsWith($user->password, '$2y$');
    }

    private function generateUniqueUsername(): string
    {
        $characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
        do {
            $username = '';
            for ($i = 0; $i < 8; $i++) {
                $username .= $characters[random_int(0, strlen($characters) - 1)];
            }
        } while (Users::where('username', $username)->exists());
        return $username;
    }
}
