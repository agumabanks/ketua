<?php

namespace App\Http\Controllers;

use App\Models\Users;
use App\Models\Images;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class IncomingLikesController extends Controller
{
    public function index(Request $request)
    {
        $v=$request->validate(['sort'=>'nullable|in:recommended,recent,stars','page'=>'nullable|integer|min:1|max:1000']);
        $me=auth('app_users')->user();
        $hidden=array_filter(explode(',', (string)$me->hidden_user_ids));
        $blocked=array_filter(explode(',', (string)$me->blocked_users));
        $query=DB::table('like_profiles as l')->join('users as u','u.id','=','l.my_user_id')
            ->where('l.user_id',$me->id)->where('u.is_block',0)->where('u.anonymous',0)
            ->whereNotIn('u.id',array_merge($hidden,$blocked,[$me->id]))
            ->whereRaw('NOT FIND_IN_SET(?, COALESCE(u.blocked_users, ?))',[(string)$me->id,''])
            ->whereDate('u.dob','<=',now()->subYears(18)->toDateString());
        if (($v['sort'] ?? '')==='stars') $query->where('l.star',1);
        $count=(clone $query)->distinct()->count('u.id');
        $unlocked=\App\Services\PremiumAccess::plan($me->id)!=='free';
        if (!$unlocked) {
            // Never send original images/identities behind a client-only blur.
            return response()->json(['status'=>true,'count'=>$count,'unlocked'=>false,
                'preview_count'=>min(6,$count),'data'=>[],'has_more'=>false]);
        }
        $page=(int)($v['page'] ?? 1);
        $rows=$query->select('u.id','u.fullname','u.username','u.dob','u.bio','u.interests','u.relationship_goal_id',
            'u.is_verified','l.star','l.id as like_id')->orderByDesc('l.id')->offset(($page-1)*20)->limit(21)->get();
        $more=$rows->count()>20;
        $mine=array_filter(explode(',',(string)$me->getOriginal('interests')));
        $data=$rows->take(20)->map(function ($u) use ($mine) {
            $common=array_values(array_intersect($mine,array_filter(explode(',',(string)$u->interests))));
            return ['id'=>(int)$u->id,'fullname'=>$u->fullname,'username'=>$u->username,
                'age'=>\Carbon\Carbon::parse($u->dob)->age,'bio'=>$u->bio,'interests'=>$u->interests,
                'relationship_goal_id'=>$u->relationship_goal_id,'is_verified'=>(int)$u->is_verified,
                'star'=>(bool)$u->star,'common_interests'=>$common,'is_like'=>false,
                'images'=>Images::where('user_id',$u->id)->get(['id','user_id','image'])];
        });
        if (($v['sort'] ?? 'recommended')==='recommended') $data=$data->sortByDesc(fn($u)=>count($u['common_interests']))->values();
        return response()->json(['status'=>true,'count'=>$count,'unlocked'=>true,'data'=>$data,'has_more'=>$more]);
    }
}
