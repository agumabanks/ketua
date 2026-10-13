<?php

namespace App\Http\Controllers;

use App\Models\AppData;
use App\Models\Images;
use App\Models\UserActivityDay;
use App\Models\UserBoost;
use App\Models\UserHeartbeat;
use App\Models\UserMilestone;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Mission features: Boosts, Heartbeat (presence), consistency milestones,
 * and profile completeness.
 *
 * All endpoints derive the acting user from the bearer token. Boosts are
 * coin-gated and time-boxed server-side; milestones are awarded for consistent
 * daily activity (3/5-day streaks); profile completeness is a computed score
 * that nudges users to finish their profile.
 */
class FeatureController extends Controller
{
    /**
     * POST /api/boost  (auth) — purchase a profile boost.
     * Price from appdata.boost_price (server-side). Creates a 30-minute
     * visibility window. Atomic wallet debit.
     */
    public function boost(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        $appData = AppData::first();
        $price = (float) ($appData->boost_price ?? 0);
        if ($price <= 0) return response()->json(['status'=>false, 'message'=>'Boost pricing is not configured.'], 503);

        try {
            $result = DB::transaction(function () use ($me, $price) {
                $locked = Users::where('id', $me->id)->lockForUpdate()->first();
                $balance = (float) $locked->wallet;

                if ($price > 0 && $balance < $price) {
                    return ['ok' => false, 'code' => 402, 'message' => 'Not enough coins to boost.', 'wallet' => $balance];
                }

                if ($price > 0) {
                    $locked->wallet = $balance - $price;
                    \App\Services\FundedCoins::consume($locked->id,(int)$price);
                    $locked->save();
                }

                $now = now();
                $expires = $now->copy()->addMinutes(30);

                // Extend an existing active boost rather than stacking.
                $active = UserBoost::where('user_id', $locked->id)->active()->first();
                if ($active) {
                    $active->expires_at = $active->expires_at->copy()->addMinutes(30);
                    $active->save();
                    $expires = $active->expires_at;
                } else {
                    UserBoost::create([
                        'user_id' => $locked->id,
                        'coin_price' => $price,
                        'started_at' => $now,
                        'expires_at' => $expires,
                    ]);
                }

                return ['ok' => true, 'code' => 200, 'message' => 'Boost activated for 30 minutes!', 'wallet' => $locked->wallet, 'expires_at' => $expires->toIso8601String()];
            });
        } catch (\Throwable $e) {
            return response()->json(['status' => false, 'message' => 'Something went wrong.'], 500);
        }

        return response()->json([
            'status' => $result['ok'],
            'message' => $result['message'],
            'wallet' => $result['wallet'] ?? null,
            'expires_at' => $result['expires_at'] ?? null,
        ], $result['code']);
    }

    /**
     * GET /api/boost/status  (auth)
     */
    public function boostStatus(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }
        $active = UserBoost::where('user_id', $me->id)->active()->first();
        return response()->json([
            'status' => true,
            'active' => $active !== null,
            'coin_price' => (int) (AppData::first()->boost_price ?? 0),
            'duration_minutes' => 30,
            'wallet' => (float) $me->wallet,
            'expires_at' => $active ? $active->expires_at->toIso8601String() : null,
        ]);
    }

    /**
     * POST /api/heartbeat  (auth) — presence ping. Updates last-seen and
     * evaluates consistency milestones (3/5-day streaks).
     */
    public function heartbeat(Request $request)
    {
        $me = auth('app_users')->user();
        if ($me == null) {
            return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
        }

        // Deterministic server day (UTC). The client never supplies the date, so
        // it cannot forge activity days or backdate/forward-date a streak.
        $today = now()->utc()->toDateString();
        $nowTs = now();

        // Append/preserve DAILY history. Idempotent within a day (replays just
        // bump last_seen_at), so multiple pings the same day never inflate the
        // streak. This replaces the old updateOrCreate that kept only the latest
        // ping and destroyed history.
        $row = UserActivityDay::firstOrNew([
            'user_id' => $me->id,
            'activity_date' => $today,
        ]);
        $row->last_seen_at = $nowTs;
        if (empty($row->first_seen_at)) {
            $row->first_seen_at = $nowTs;
        }
        $row->save();

        // Keep a lightweight "last seen" pointer for presence.
        UserHeartbeat::updateOrCreate(
            ['user_id' => $me->id],
            ['last_seen_at' => $nowTs]
        );

        $milestones = $this->evaluateMilestones($me);

        return response()->json([
            'status' => true,
            'message' => 'Heartbeat recorded.',
            'milestones' => $milestones,
        ]);
    }

    /**
     * GET /api/profile/completeness  (auth) — computed 0-100 score + missing items.
     */
    public function profileCompleteness(Request $request)
    {
        try {
            $me = auth('app_users')->user();
            if ($me == null) {
                return response()->json(['status' => false, 'message' => 'Unauthenticated.'], 401);
            }

            $photoCount = Images::where('user_id', $me->id)->count();

            // NOTE: the Users model has an `interests()` relation method that
            // shadows the `interests` column, so read it via getOriginal() to
            // avoid triggering the (pathological) relation query.
            $interests = $me->getOriginal('interests');

            $checks = [
                'fullname' => !empty($me->fullname),
                'bio' => !empty($me->bio),
                'about' => !empty($me->about),
                'dob' => !empty($me->dob),
                'gender' => !empty($me->gender),
                'location' => !empty($me->city) || !empty($me->country),
                'interests' => !empty($interests),
                'photos' => $photoCount >= 1,
            ];

            $done = count(array_filter($checks));
            $total = count($checks);
            $score = $total > 0 ? (int) round(($done / $total) * 100) : 0;
            $missing = [];
            foreach ($checks as $k => $v) {
                if (!$v) { $missing[] = $k; }
            }

            return response()->json([
                'status' => true,
                'score' => $score,
                'missing' => $missing,
            ]);
        } catch (\Throwable $e) {
            \Log::error('profileCompleteness RAW: ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine() . ' mem=' . memory_get_usage(true));
            return response()->json(['status' => false, 'message' => 'Could not compute completeness.'], 500);
        }
    }

    /**
     * Award 3/5-day consistency milestones based on consecutive active days
     * (presence heartbeats). Idempotent: a milestone for a given streak length
     * is only created once.
     */
    private function evaluateMilestones(Users $me): array
    {
        // Deterministic streak from preserved daily history (user_activity_days).
        // - Only days <= today count (future-dated rows are ignored => clock-abuse safe).
        // - Consecutive days ending today (or yesterday) form the streak.
        // - Replays within a day are idempotent (unique user_id+activity_date).
        $today = \Carbon\Carbon::now('UTC')->startOfDay();

        $days = UserActivityDay::where('user_id', $me->id)
            ->whereDate('activity_date', '<=', $today->toDateString())
            ->orderByDesc('activity_date')
            ->limit(30)
            ->pluck('activity_date')
            ->map(fn($d) => \Carbon\Carbon::parse($d)->startOfDay())
            ->values();

        $streak = 0;
        $expected = $today->copy();
        // Allow the streak to end today OR yesterday (grace for "not yet active today").
        if ($days->isNotEmpty() && $days->first()->lt($today)) {
            $expected = $days->first()->copy();
        }
        foreach ($days as $d) {
            if ($d->equalTo($expected)) {
                $streak++;
                $expected = $expected->subDay();
            } elseif ($d->lt($expected)) {
                break; // gap -> streak ends
            }
            // $d > $expected can't happen due to ordering + today cap
        }

        $appData = AppData::first();
        $milestoneDays = (int) ($appData->milestone_days ?? 3);

        $awarded = [];
        foreach ([3, 5] as $target) {
            if ($streak >= $target) {
                $exists = UserMilestone::where('user_id', $me->id)->where('streak_days', $target)->exists();
                if (!$exists) {
                    UserMilestone::create([
                        'user_id' => $me->id,
                        'streak_days' => $target,
                        'achieved_at' => now(),
                    ]);
                    $awarded[] = $target;
                }
            }
        }

        return [
            'streak_days' => $streak,
            'milestone_target' => $milestoneDays,
            'newly_awarded' => $awarded,
        ];
    }
}
