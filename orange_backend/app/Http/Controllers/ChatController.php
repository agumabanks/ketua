<?php

namespace App\Http\Controllers;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\Myfunction;
use App\Models\UserNotification;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * F06 — Server-side chat.
 *
 * Replaces the Firestore-only client chat with server-authoritative
 * conversations and messages. All endpoints derive the acting user from the
 * bearer token. Media uploads are validated. Message delivery is synchronous
 * (HTTP polling); the client can poll fetchMessages for new messages.
 */
class ChatController extends Controller
{
    private function clearedThrough(Conversation $conversation, Users|\App\Models\User $user): int
    {
        return (int) ($conversation->user_a == $user->id
            ? $conversation->cleared_through_a : $conversation->cleared_through_b);
    }

    /**
     * GET /api/chat/conversations  (auth) — list the caller's conversations.
     */
    public function conversations(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $conversations = Conversation::with(['userA'=>fn ($q) => $q->select('id','fullname','username','is_verified'), 'userB'=>fn ($q) => $q->select('id','fullname','username','is_verified')])
            ->where('user_a', $me->id)
            ->orWhere('user_b', $me->id)
            ->orderByDesc('last_message_at')
            ->orderByDesc('updated_at')
            ->get()
            ->map(function ($c) use ($me) {
                $other = $c->user_a == $me->id ? $c->userB : $c->userA;
                $isBlocked = $c->user_a == $me->id ? (bool) $c->blocked_by_a : (bool) $c->blocked_by_b;
                $isMuted = $c->user_a == $me->id ? (bool) $c->muted_by_a : (bool) $c->muted_by_b;

                $cutoff = $this->clearedThrough($c, $me);
                $latest = Message::where('conversation_id', $c->conversation_id)
                    ->where('id', '>', $cutoff)->where('is_deleted', 0)->orderByDesc('id')->first();
                if (!$latest) return null;
                // Unread count for the caller.
                $unread = Message::where('conversation_id', $c->conversation_id)
                    ->where('receiver_id', $me->id)
                    ->where('id', '>', $cutoff)
                    ->where('is_read', 0)
                    ->where('is_deleted', 0)
                    ->count();

                return [
                    'conversation_id' => $c->conversation_id,
                    'other_user' => $other ? $other->only(['id','fullname','username','is_verified']) : null,
                    'last_message' => $latest->body ?? ($latest->message_type === 'image' ? 'Photo' : 'Video'),
                    'last_message_at' => $latest->created_at,
                    'is_blocked' => $isBlocked,
                    'is_muted' => $isMuted,
                    'unread_count' => $unread,
                ];
            })->filter()->values();

        return response()->json([
            'status' => true,
            'message' => 'Conversations fetched successfully.',
            'data' => $conversations,
        ]);
    }

    /**
     * POST /api/chat/send  (auth) — send a message.
     * { receiver_id, body?, message_type?, media? }
     */
    public function send(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), [
            'receiver_id' => 'required|integer|min:1',
            'body' => 'nullable|string|max:5000',
            'message_type' => 'nullable|string|in:text,image,video',
            'client_key'=>'nullable|uuid', 'reply_to_id'=>'nullable|integer|min:1',
        ]);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $receiver = Users::find($request->receiver_id);
        if ($receiver == null) {
            return response()->json(['status' => false, 'message' => 'Receiver not found.']);
        }
        if ((int) $receiver->id === (int) $me->id) {
            return response()->json(['status' => false, 'message' => 'Cannot message yourself.']);
        }

        if ((int)$receiver->is_block === 1 || in_array($receiver->id, explode(',', $me->blocked_users ?? '')) || in_array($me->id, explode(',', $receiver->blocked_users ?? ''))) return response()->json(['status'=>false,'message'=>'Conversation unavailable.'], 403);
        $messageType = $request->input('message_type', 'text');
        $body = $request->input('body');
        $media = null;
        if ($messageType === 'text' && trim((string) $body) === '') {
            return response()->json(['status'=>false, 'message'=>'A message cannot be empty.'], 422);
        }
        $ids = [$me->id, $receiver->id];
        sort($ids);
        $conversationId = $ids[0] . '_' . $ids[1];
        $existing = Conversation::where('conversation_id', $conversationId)->first();
        if ($existing && ($existing->blocked_by_a || $existing->blocked_by_b)) {
            return response()->json(['status'=>false, 'message'=>'Conversation unavailable.'], 403);
        }

        // Media upload for image/video messages.
        if (in_array($messageType, ['image', 'video'], true)) {
            $file = $request->file('media');
            if ($file == null) {
                return response()->json(['status' => false, 'message' => 'Media file is required.'], 422);
            }
            if (!$file->isValid()) {
                return response()->json(['status' => false, 'message' => 'Upload failed.'], 422);
            }
            $allowed = $messageType === 'image'
                ? ['jpg', 'jpeg', 'png', 'webp', 'gif']
                : ['mp4', 'mov', 'webm', 'avi'];
            $ext = strtolower($file->getClientOriginalExtension() ?? $file->extension());
            if (!in_array($ext, $allowed, true)) {
                return response()->json(['status' => false, 'message' => 'File type not allowed.'], 422);
            }
            $mimes = $messageType === 'image'
                ? ['image/jpeg','image/png','image/webp','image/gif']
                : ['video/mp4','video/quicktime','video/webm','video/x-msvideo'];
            if (!in_array($file->getMimeType(), $mimes, true)
                || ($messageType === 'image' && @getimagesize($file->getRealPath()) === false)) {
                return response()->json(['status'=>false, 'message'=>'The file does not contain valid media.'], 422);
            }
            if ($file->getSize() > 60 * 1024 * 1024) {
                return response()->json(['status' => false, 'message' => 'File exceeds 60MB limit.'], 422);
            }
            $media = $file->storeAs('chat_media', time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext, 'local');
        }

        try { $result = DB::transaction(function () use ($ids, $conversationId, $body, $messageType, $media, $me, $receiver, $request) {
            Conversation::firstOrCreate(['conversation_id'=>$conversationId], ['user_a'=>$ids[0], 'user_b'=>$ids[1]]);
            $conversation = Conversation::where('conversation_id', $conversationId)->lockForUpdate()->firstOrFail();
            if ($conversation->blocked_by_a || $conversation->blocked_by_b) return null;
            if ($requestKey = $request->input('client_key')) {
                $old=Message::where('sender_id',$me->id)->where('client_key',$requestKey)->first();
                if($old){if($old->conversation_id!==$conversationId || $old->body!==$body || $old->message_type!==$messageType || $old->reply_to_id!=$request->input('reply_to_id'))abort(409,'Message key already used.');return [$conversation,$old];}
            }
            $reply=$request->input('reply_to_id');
            if($reply && !Message::where('id',$reply)->where('conversation_id',$conversationId)->where('is_deleted',0)->where('id','>',$this->clearedThrough($conversation,$me))->exists())abort(422,'Reply unavailable.');
            $conversation->last_message = $body ?? ($messageType === 'image' ? 'Photo' : 'Video');
            $conversation->last_message_by = $me->id;
            $conversation->last_message_at = now();
            $conversation->save();
            $message = Message::create([
                'conversation_id'=>$conversationId, 'sender_id'=>$me->id, 'receiver_id'=>$receiver->id,
                'body'=>$body, 'message_type'=>$messageType, 'media'=>$media,'client_key'=>$request->input('client_key'),'reply_to_id'=>$reply,
            ]);
            return [$conversation, $message];
        }); } catch (\Throwable $e) {
            if($media)\Illuminate\Support\Facades\Storage::disk('local')->delete($media);
            throw $e;
        }
        if (!$result) {
            if ($media) \Illuminate\Support\Facades\Storage::disk('local')->delete($media);
            return response()->json(['status'=>false, 'message'=>'Conversation unavailable.'], 403);
        }
        [$conversation, $message] = $result;
        if($media && $message->media!==$media)\Illuminate\Support\Facades\Storage::disk('local')->delete($media);

        // Notify the receiver (best-effort).
        $receiverMuted = $conversation->user_a == $receiver->id ? $conversation->muted_by_a : $conversation->muted_by_b;
        if (!$receiverMuted && !empty($receiver->device_token)) {
            try {
                Myfunction::sendPushToUser(
                    'New message',
                    $me->fullname . ' sent you a message',
                    $receiver->device_token
                );
            } catch (\Throwable $e) {
            }
        }

        return response()->json([
            'status' => true,
            'message' => 'Message sent.',
            'data' => $message,
        ]);
    }

    /**
     * POST /api/chat/messages  (auth) — fetch messages in a conversation.
     * { conversation_id, before_id?, count? }
     */
    public function messages(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), [
            'conversation_id' => 'required|string',
            'before_id' => 'nullable|integer',
            'count' => 'nullable|integer',
        ]);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $conversation = Conversation::where('conversation_id', $request->conversation_id)->first();
        if ($conversation == null) {
            $parts=explode('_',$request->conversation_id);
            if(count($parts)!==2 || !ctype_digit($parts[0]) || !ctype_digit($parts[1]) || !in_array((string)$me->id,$parts,true) || (int)$parts[0]>=(int)$parts[1])return response()->json(['status'=>false,'message'=>'Forbidden.'],403);
            $target=Users::find((int)($parts[0]==$me->id ? $parts[1] : $parts[0]));
            if(!$target || $target->is_block || in_array($target->id,explode(',',(string)$me->blocked_users)) || in_array($me->id,explode(',',(string)$target->blocked_users)))return response()->json(['status'=>false,'message'=>'Conversation unavailable.'],403);
            return response()->json(['status'=>true,'data'=>[],'is_blocked'=>false,'is_muted'=>false,'can_send'=>true]);
        }
        // Ownership check.
        if (!in_array($me->id, [$conversation->user_a, $conversation->user_b], true)) {
            return response()->json(['status' => false, 'message' => 'Forbidden.'], 403);
        }

        $count = max(1, min((int) ($request->input('count', 50)), 100));
        $query = Message::with(['sender'=>fn ($query) => $query->select('id','fullname','username','is_verified')])
            ->where('conversation_id', $request->conversation_id)
            ->where('id', '>', $this->clearedThrough($conversation, $me))
            ->where('is_deleted', 0)
            ->orderByDesc('created_at');

        if ($request->filled('before_id')) {
            $query->where('id', '<', $request->before_id);
        }

        $messages = $query->limit($count)->get()->values();
        foreach($messages as $m){
            $m->media_url=$m->media ? url('/api/chat/media/'.$m->id) : null;
            if($m->reply_to_id){$original=Message::where('id',$m->reply_to_id)->where('conversation_id',$conversation->conversation_id)->where('is_deleted',0)->where('id','>',$this->clearedThrough($conversation,$me))->first();$m->reply_preview=$original ? mb_substr($original->body ?? 'Photo',0,160) : 'Message unavailable';}
        }

        return response()->json([
            'status' => true,
            'message' => 'Messages fetched successfully.',
            'is_blocked' => (bool) ($conversation->user_a == $me->id ? $conversation->blocked_by_a : $conversation->blocked_by_b),
            'is_muted' => (bool) ($conversation->user_a == $me->id ? $conversation->muted_by_a : $conversation->muted_by_b),
            'can_send' => !$conversation->blocked_by_a && !$conversation->blocked_by_b,
            'data' => $messages,
        ]);
    }

    /**
     * POST /api/chat/read  (auth) — mark messages as read up to a message id.
     */
    public function media(int $id){
        $me=auth('app_users')->user();if(!$me)abort(401);
        $m=Message::where('id',$id)->where('is_deleted',0)->firstOrFail();
        $c=Conversation::where('conversation_id',$m->conversation_id)->firstOrFail();
        if(!in_array((int)$me->id,[(int)$c->user_a,(int)$c->user_b],true) || $m->id <= $this->clearedThrough($c,$me) || !$m->media)abort(404);
        $path=\Illuminate\Support\Facades\Storage::disk('local')->path($m->media);if(!is_file($path))abort(404);
        $r=response()->file($path,['X-Content-Type-Options'=>'nosniff']);$r->setPrivate();$r->headers->addCacheControlDirective('no-store');return $r;
    }

    public function markRead(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), [
            'conversation_id' => 'required|string',
            'last_read_message_id' => 'required|integer|min:1',
        ]);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $conversation = Conversation::where('conversation_id', $request->conversation_id)->first();
        if ($conversation == null) {
            return response()->json(['status' => false, 'message' => 'Conversation not found.']);
        }
        if (!in_array($me->id, [$conversation->user_a, $conversation->user_b], true)) {
            return response()->json(['status' => false, 'message' => 'Forbidden.'], 403);
        }

        Message::where('conversation_id', $request->conversation_id)
            ->where('receiver_id', $me->id)
            ->where('id', '<=', $request->last_read_message_id)
            ->where('is_read', 0)
            ->update(['is_read' => 1, 'read_at' => now()]);

        return response()->json(['status' => true, 'message' => 'Messages marked as read.']);
    }

    /**
     * POST /api/chat/block  (auth) — block/unblock the other user.
     * { conversation_id, action: block|unblock }
     */
    public function block(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), [
            'conversation_id' => 'required|string',
            'action' => 'required|string|in:block,unblock',
        ]);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $conversation = Conversation::where('conversation_id', $request->conversation_id)->first();
        if ($conversation == null) {
            return response()->json(['status' => false, 'message' => 'Conversation not found.']);
        }
        if (!in_array($me->id, [$conversation->user_a, $conversation->user_b], true)) {
            return response()->json(['status' => false, 'message' => 'Forbidden.'], 403);
        }

        $block = $request->action === 'block';
        DB::transaction(function () use ($conversation, $me, $block) {
            $locked = Conversation::whereKey($conversation->id)->lockForUpdate()->firstOrFail();
            $otherId = $locked->user_a == $me->id ? $locked->user_b : $locked->user_a;
            $column = $locked->user_a == $me->id ? 'blocked_by_a' : 'blocked_by_b';
            $locked->$column = $block;
            $locked->save();
            $actor = Users::whereKey($me->id)->lockForUpdate()->firstOrFail();
            $blocked = array_filter(array_map('intval', explode(',', $actor->blocked_users ?? '')));
            $blocked = array_values(array_diff($blocked, [(int) $otherId]));
            if ($block) $blocked[] = (int) $otherId;
            $actor->blocked_users = implode(',', array_unique($blocked));
            $actor->save();
        });

        return response()->json(['status' => true, 'message' => $request->action === 'block' ? 'User blocked.' : 'User unblocked.']);
    }

    /**
     * POST /api/chat/mute  (auth) — mute/unmute the conversation.
     */
    public function mute(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), [
            'conversation_id' => 'required|string',
            'action' => 'required|string|in:mute,unmute',
        ]);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $conversation = Conversation::where('conversation_id', $request->conversation_id)->first();
        if ($conversation == null) {
            return response()->json(['status' => false, 'message' => 'Conversation not found.']);
        }
        if (!in_array($me->id, [$conversation->user_a, $conversation->user_b], true)) {
            return response()->json(['status' => false, 'message' => 'Forbidden.'], 403);
        }

        $mute = $request->action === 'mute';
        if ($conversation->user_a == $me->id) {
            $conversation->muted_by_a = $mute;
        } else {
            $conversation->muted_by_b = $mute;
        }
        $conversation->save();

        return response()->json(['status' => true, 'message' => $request->action === 'mute' ? 'Conversation muted.' : 'Conversation unmuted.']);
    }

    /**
     * POST /api/chat/deleteMessage  (auth) — soft-delete a message.
     */
    public function deleteMessage(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['message_id' => 'required|integer|min:1']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $message = Message::find($request->message_id);
        if ($message == null) {
            return response()->json(['status' => false, 'message' => 'Message not found.']);
        }
        if ((int) $message->sender_id !== (int) $me->id) {
            return response()->json(['status' => false, 'message' => 'You can only delete your own messages.'], 403);
        }

        $message->is_deleted = 1;
        $message->save();

        return response()->json(['status' => true, 'message' => 'Message deleted.']);
    }

    /**
     * POST /api/chat/deleteConversation  (auth) — remove the conversation for the caller.
     */
    public function deleteConversation(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $v = Validator::make($request->all(), ['conversation_id' => 'required|string']);
        if ($v->fails()) {
            return response()->json(['status' => false, 'message' => $v->errors()->first()]);
        }

        $conversation = Conversation::where('conversation_id', $request->conversation_id)->first();
        if ($conversation == null) {
            return response()->json(['status' => false, 'message' => 'Conversation not found.']);
        }
        if (!in_array($me->id, [$conversation->user_a, $conversation->user_b], true)) {
            return response()->json(['status' => false, 'message' => 'Forbidden.'], 403);
        }

        // A clear affects only this participant's existing history. New messages
        // remain visible, and the other participant retains their copy.
        DB::transaction(function () use ($conversation, $me) {
            $locked = Conversation::whereKey($conversation->id)->lockForUpdate()->firstOrFail();
            $column = $locked->user_a == $me->id ? 'cleared_through_a' : 'cleared_through_b';
            $locked->$column = (int) Message::where('conversation_id', $locked->conversation_id)->max('id');
            $locked->save();
        });

        return response()->json(['status' => true, 'message' => 'Conversation deleted.']);
    }
}
