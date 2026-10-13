<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\AppData;
use App\Models\DiamondPacks;
use App\Models\Gifts;
use App\Models\GlobalFunction;
use App\Models\Interest;
use App\Models\LiveApplications;
use App\Models\Post;
use App\Models\RedeemRequest;
use App\Models\Report;
use App\Models\Users;
use App\Models\VerifyRequest;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;

class LoginController extends Controller
{
    function index()
    {
        $totalUsers = Users::count();
        $liveStreamUsers = Users::where('can_go_live', 2)->count();
        $blockedUsers = Users::where('is_block', 1)->count();
        $liveApplications = LiveApplications::count();
        $pendingRedeems = RedeemRequest::where('status', 0)->count();
        $completedRedeems = RedeemRequest::where('status', 1)->count();
        $diamondPacks = DiamondPacks::count();
        $gifts = Gifts::count();
        $verifyRequests = VerifyRequest::count();
        $reports = Report::count();
        $interests = Interest::count();
        $totalPosts = Post::count();
        return view('index')->with([
            'totalUsers' => $totalUsers,
            'liveStreamUsers' => $liveStreamUsers,
            'blockedUsers' => $blockedUsers,
            'liveApplications' => $liveApplications,
            'pendingRedeems' => $pendingRedeems,
            'completedRedeems' => $completedRedeems,
            'gifts' => $gifts,
            'diamondPacks' => $diamondPacks,
            'verifyRequests' => $verifyRequests,
            'reports' => $reports,
            'interests' => $interests,
            'totalPosts' => $totalPosts,
        ]);
    }
    function login()
    {
        Artisan::call('storage:link');

        if (Session::get('user_name')) {
            return redirect('index');
        }

        return  view('login.login');
    }

    // function checklogin(Request $req)
    // {
    //     $setting = AppData::first();
    //     if ($setting) {
    //         Session::put('app_name', $setting->app_name);
    //     }

    //     $data = Admin::where('user_name', $req->user_name)->first();

    //     Artisan::call('storage:link');

    //     if ($req->user_name == $data['user_name'] && $req->user_password == $data['user_password']) {
    //         $req->session()->put('user_name', $data['user_name']);
    //         $req->session()->put('user_password', $data['user_password']);
    //         $req->session()->put('user_type', $data['user_type']);
    //         return response()->json([
    //             'status' => true,
    //             'message' => 'login successfully.',
    //         ]);
    //     } else {
    //         return response()->json([
    //             'status' => false,
    //             'message' => 'Something went wrong.',
    //         ]);
    //     }
    // }

    public function checkLogin(Request $request)
    {
        $data = Admin::where('user_name', $request->user_name)->first();

        // K14: passwords are bcrypt hashes. Legacy rows still hold a reversible
        // Crypt blob — those are accepted once and transparently upgraded to
        // bcrypt on successful login, so the reversible form is phased out.
        if ($data && $this->verifyAdminPassword($data, $request->user_password)) {
            $request->session()->put('user_name', $data['user_name']);
            $request->session()->put('user_type', $data['user_type']);

            return response()->json([
                'status' => true,
                'message' => 'Login successful'
            ]);
        }

        return response()->json([
            'status' => false,
            'message' => 'Invalid credentials'
        ]);
    }

    /**
     * K14: verify an admin password against bcrypt (preferred) or the legacy
     * reversible Crypt blob. On a successful legacy match the stored value is
     * upgraded to bcrypt in place.
     */
    private function verifyAdminPassword(Admin $admin, string $plain): bool
    {
        $stored = $admin->user_password;

        // Preferred: bcrypt hash.
        if (is_string($stored) && str_starts_with($stored, '$2y$')) {
            return Hash::check($plain, $stored);
        }

        // Legacy: reversible Crypt blob. Decrypt, compare, then upgrade.
        try {
            $decrypted = Crypt::decrypt($stored);
        } catch (\Throwable $e) {
            return false;
        }

        if (hash_equals((string) $decrypted, $plain)) {
            $admin->user_password = Hash::make($plain);
            $admin->save();
            return true;
        }

        return false;
    }

    public function forgotPasswordForm(Request $request)
    {
        // SECURITY (verified reset workflow): this endpoint can no longer be
        // called anonymously to overwrite the admin password. It now requires:
        //   1. an authenticated admin session (route also has checkLogin), AND
        //   2. the current password to be supplied and verified.
        // Without both, the stored password is NOT changed.
        $sessionUser = Session::get('user_name');
        if (!$sessionUser) {
            return GlobalFunction::sendSimpleResponse(false, 'Unauthenticated.');
        }

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:8|confirmed',
        ]);
        if ($validator->fails()) {
            return GlobalFunction::sendSimpleResponse(false, $validator->errors()->first());
        }

        $admin = Admin::where('user_name', $sessionUser)->first();
        if (!$admin) {
            return GlobalFunction::sendSimpleResponse(false, 'Admin user not found.');
        }

        // Verify the current password before allowing a change.
        $currentOk = false;
        try {
            $currentOk = hash_equals(Crypt::decrypt($admin->user_password), $request->current_password);
        } catch (\Throwable $e) {
            $currentOk = false;
        }
        if (!$currentOk) {
            return GlobalFunction::sendSimpleResponse(false, 'Current password is incorrect.');
        }

        $admin->user_password = Hash::make($request->new_password);
        $admin->save();

        return GlobalFunction::sendSimpleResponse(true, 'Password updated successfully.');
    }

    function logout()
    {
        session()->pull('user_name');
        session()->pull('user_password');
        session()->pull('user_type');
        return  redirect(url('/admin/login'));
    }

    /**
     * Public landing page (the app's marketing home at the root URL).
     * The admin panel login now lives at /admin/login.
     */
    function landing()
    {
        $downloadUrl = url('downloads/ketua-app/KETUA-latest.apk');
        return view('landing', [
            'downloadUrl' => $downloadUrl,
        ]);
    }

    function profile()
    {
        $data = Admin::first();
        return view('setting.profile', ['data' => $data]);
    }

    function updateProflie(Request $req)
    {
        // K14: store bcrypt, not a reversible Crypt blob. Only change the
        // password when one was actually supplied.
        $update = ['user_name' => $req->user_name];
        if ($req->filled('user_password')) {
            $update['user_password'] = Hash::make($req->user_password);
        }
        $item = Admin::where('user_id', 1)->update($update);

        return  json_encode(['status' => true, "message" => "Update susseccfull"]);
    }
}
