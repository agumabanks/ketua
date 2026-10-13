<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;use Illuminate\Support\Facades\DB;use App\Services\PremiumAccess;
class PremiumController extends Controller {
 public function status(){return response()->json(['status'=>true,'data'=>PremiumAccess::status(auth('app_users')->user()?->id),'packs'=>DB::table('super_like_packs')->where('reward_type','star')->where('enabled',true)->get()]);}
 public function settings(Request $r){$v=$r->validate(['hide_ads'=>'sometimes|boolean','hide_age'=>'sometimes|boolean','hide_distance'=>'sometimes|boolean','incognito'=>'sometimes|boolean','passport_country'=>'sometimes|nullable|string|max:100']);$id=auth('app_users')->user()?->id;if(PremiumAccess::plan($id)==='free')return response()->json(['status'=>false,'message'=>'Gold or Pro required.'],403);DB::transaction(function()use($id,$v){DB::table('users')->where('id',$id)->lockForUpdate()->first();PremiumAccess::usage($id);DB::table('premium_usage')->where('user_id',$id)->update($v);});return $this->status();}
}
