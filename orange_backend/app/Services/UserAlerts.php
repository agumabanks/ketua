<?php
namespace App\Services;
use Illuminate\Support\Facades\DB;
class UserAlerts {
 public static function send(int $userId,string $title,string $message):void {
  $n=new \App\Models\UserNotification();$n->user_id=$userId;$n->my_user_id=$userId;$n->type=8;$n->message=$message;$n->save();
  DB::afterCommit(function()use($userId,$title,$message){$u=\App\Models\Users::find($userId);if($u && $u->is_notification && !$u->is_block && $u->device_token)\App\Models\Myfunction::sendPushToUser($title,$message,$u->device_token);});
 }
}
