<?php

namespace App\Http\Controllers;

use App\Models\Constants;
use App\Models\GiftTransaction;
use App\Models\Gifts;
use App\Models\Myfunction;
use App\Models\UserNotification;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Mission feature: gifting.
 *
 * sendGift is the single server-authoritative path for sending a gift. It:
 *   - derives the sender from the bearer token (never trusts client user_id),
 *   - prices the gift from the `gifts` catalog (never trusts a client price),
 *   - atomically debits the sender wallet and credits the receiver wallet,
 *   - writes an immutable ledger row (gift_transactions),
 *   - notifies the receiver.
 *
 * All balance math happens server-side inside a locked transaction so a
 * concurrent request cannot double-spend.
 */
class GiftController extends Controller
{
    /**
     * POST /api/sendGift  (auth)
     * { gift_id, receiver_id, context? }
     */
    public function sendGift(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'client_key' => 'nullable|uuid',
            'gift_id'     => 'required|integer|min:1',
            'receiver_id' => 'required|integer|min:1',
            'context'     => 'nullable|string|max:50',
            'expected_coin_price' => 'nullable|integer|min:1|max:1000000',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $sender = auth('app_users')->user();
        if ($sender == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        if ((int) $request->receiver_id === (int) $sender->id) {
            return response()->json(['status' => false, 'message' => 'You cannot send a gift to yourself.']);
        }

        // Price comes from the catalog, not the client.
        $gift = Gifts::find($request->gift_id);
        if ($gift == null) {
            return response()->json(['status' => false, 'message' => 'Gift not found.']);
        }
        $price = (float) ($gift->coin_price ?? 0);
        if ($price <= 0) {
            return response()->json(['status' => false, 'message' => 'This gift has no valid price.']);
        }

        $receiver = Users::find($request->receiver_id);
        if ($receiver == null) {
            return response()->json(['status' => false, 'message' => 'Receiver not found.']);
        }

        try {
            $result = DB::transaction(function () use ($sender, $receiver, $gift, $price, $request) {
                $current=Gifts::where('id',$gift->id)->lockForUpdate()->first();
                if(!$current || (float)$current->coin_price<=0)return ['ok'=>false,'code'=>409,'message'=>'This gift is unavailable.'];
                $price=(float)$current->coin_price;
                if($request->filled('expected_coin_price') && (int)$request->expected_coin_price !== (int)$price)return ['ok'=>false,'code'=>409,'message'=>'This gift price changed. Refresh the gift catalog and confirm its new value.'];
                // Lock both accounts in the same order for opposite-direction gifts.
                $accounts = Users::whereIn('id', [$sender->id, $receiver->id])->orderBy('id')->lockForUpdate()->get()->keyBy('id');
                $lockedSender = $accounts->get($sender->id);
                $lockedReceiver = $accounts->get($receiver->id);
                if (!$lockedSender || !$lockedReceiver || $lockedSender->is_block || $lockedReceiver->is_block
                    || in_array($lockedReceiver->id, explode(',', $lockedSender->blocked_users ?? ''))
                    || in_array($lockedSender->id, explode(',', $lockedReceiver->blocked_users ?? ''))) {
                    return ['ok'=>false, 'code'=>403, 'message'=>'Gifting is unavailable for this connection.'];
                }
                if($request->filled('client_key')){
                    $old=GiftTransaction::where('sender_id',$sender->id)->where('client_key',$request->client_key)->first();
                    if($old){if($old->gift_id!=$gift->id || $old->receiver_id!=$receiver->id || $old->context!=$request->context)return ['ok'=>false,'code'=>409,'message'=>'Gift request key already used.'];return ['ok'=>true,'code'=>200,'message'=>'Gift already delivered.','wallet'=>$lockedSender->wallet,'transaction_id'=>$old->id,'replayed'=>true];}
                }
                $balance = (float) $lockedSender->wallet;

                if ($balance < $price) {
                    return [
                        'ok' => false,
                        'code' => 402,
                        'message' => 'Not enough coins in your wallet.',
                        'wallet' => $balance,
                    ];
                }

                // Debit sender, credit receiver (receiver earnings count toward
                // total_collected for future payouts/redeems).
                $lockedSender->wallet = $balance - $price;
                $lockedSender->save();

                $lockedReceiver->wallet = (float) $lockedReceiver->wallet + $price;
                $lockedReceiver->total_collected = (float) $lockedReceiver->total_collected + $price;
                $lockedReceiver->save();

                // Immutable ledger row.
                $tx = GiftTransaction::create([
                    'client_key'=>$request->client_key,
                    'sender_id'   => $lockedSender->id,
                    'receiver_id' => $lockedReceiver->id,
                    'gift_id'     => $gift->id,
                    'coin_price'  => $price,
                    'context'     => $request->context,
                ]);


                \App\Services\FundedCoins::move($lockedSender->id,$lockedReceiver->id,(int)$price,$tx->id);
                if($request->context==='chat'){
                    $ids=[$sender->id,$receiver->id];sort($ids);$cid=implode('_',$ids);
                    $c=\App\Models\Conversation::firstOrCreate(['conversation_id'=>$cid],['user_a'=>$ids[0],'user_b'=>$ids[1]]);
                    $c=\App\Models\Conversation::where('conversation_id',$cid)->lockForUpdate()->first();
                    if($c->blocked_by_a || $c->blocked_by_b)throw new \RuntimeException('Conversation unavailable');
                    $body='🎁 '.($current->title ?? 'Gift').' · '.(int)$price.' coins';
                    \App\Models\Message::create(['conversation_id'=>$cid,'sender_id'=>$sender->id,'receiver_id'=>$receiver->id,'body'=>$body,'message_type'=>'gift']);
                    $c->last_message=$body;$c->last_message_by=$sender->id;$c->last_message_at=now();$c->save();
                }
                return [
                    'ok' => true,
                    'code' => 200,
                    'message' => 'Gift sent successfully!',
                    'wallet' => $lockedSender->wallet,
                    'transaction_id' => $tx->id,
                ];
            });
        } catch (\Throwable $e) {
            return response()->json(['status' => false, 'message' => 'Something went wrong while sending the gift.'], 500);
        }

        // Push delivery must not hold wallet locks or roll back a committed gift.
        if ($result['ok'] && empty($result['replayed'])) $this->notifyReceiver($sender, $receiver, $gift);

        return response()->json([
            'status'  => $result['ok'],
            'message' => $result['message'],
            'wallet'  => $result['wallet'] ?? null,
            'transaction_id' => $result['transaction_id'] ?? null,
        ], $result['code']);
    }

    /**
     * GET /api/myGifts  (auth) — gifts I have sent and received (ledger).
     */
    public function myGifts(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $sent = GiftTransaction::with('gift', 'receiver:id,fullname,username,is_verified')
            ->where('sender_id', $me->id)->latest()->limit(100)->get();
        $received = GiftTransaction::with('gift', 'sender:id,fullname,username,is_verified')
            ->where('receiver_id', $me->id)->latest()->limit(100)->get();

        return response()->json([
            'status' => true,
            'message' => 'Gifts fetched successfully.',
            'data' => ['sent' => $sent, 'received' => $received],
        ]);
    }

    private function notifyReceiver(Users|\App\Models\User $sender, Users $receiver, Gifts $gift): void
    {
        try {
            $notification = new UserNotification();
            $notification->my_user_id = $sender->id;
            $notification->user_id = $receiver->id;
            $notification->item_id = $sender->id;
            $notification->type = Constants::notificationTypeGift ?? 5;
            $notification->message = $sender->fullname . ' sent you a ' . $gift->title . '!';
            $notification->save();

            if ($receiver->is_notification && !$receiver->is_block && !empty($receiver->device_token)) {
                Myfunction::sendPushToUser(
                    'New gift!',
                    $sender->fullname . ' sent you a ' . $gift->title,
                    $receiver->device_token
                );
            }
        } catch (\Throwable $e) {
            // Notifications are best-effort.
        }
    }
}
