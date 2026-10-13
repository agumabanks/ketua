<?php

namespace App\Http\Controllers;

use App\Models\AppData;
use App\Models\RedeemRequest;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RedeemRequestsController extends Controller
{
    //

    function redeemrequests()
    {
        return view('redeemrequests');
    }

    function getRedeemById($id)
    {
        $data = RedeemRequest::with('user')->where('id', $id)->first();
        $data->user->image = $data->user->images[0]->image;
        echo json_encode($data);
    }

    function completeRedeem(Request $request) { return response()->json(['status'=>false,'message'=>'Legacy wallet redeems require manual reconciliation. Use Earnings withdrawals.'],409); }

    function fetchCompletedRedeems(Request $request)
    {

        $totalData =  RedeemRequest::where('status', '=', 1)->count();
        $rows = RedeemRequest::orderBy('id', 'DESC')->get();

        $result = $rows;

        $columns = array(
            0 => 'id'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
        $totalData = RedeemRequest::where('status', '=', 1)->count();

        $totalFiltered = $totalData;
        if (empty($request->input('search.value'))) {
            $result = RedeemRequest::where('status', '=', 1)
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');
            $result =  RedeemRequest::where('status', 1)
                ->Where('request_id', 'LIKE', "%{$search}%")
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
            $totalFiltered = RedeemRequest::where('status', 1)
                ->Where('request_id', 'LIKE', "%{$search}%")
                ->count();
        }
        $data = array();

        $app_data = AppData::first();

        foreach ($result as $item) {

            if (count($item->user->images) > 0) {
                $image = '<img src="public/storage/' . $item->user->images[0]->image . '" width="50" height="50">';
            } else {
                $image = '<img src="http://placehold.jp/150x150.png" width="50" height="50">';
            }

            $block = '<span class="float-end"><a href=""  rel="' . $item->id . '"   class="btn btn-primary view-request mr-2">View</a><a href = ""  rel = "' . $item->id . '" class = "btn btn-danger delete text-white" > Delete </a></span>';

            $data[] = array(
                $image,
                $item->user->fullname,
                $item->request_id,
                $item->coin_amount,
                $app_data->currency . ' ' . $item->amount_paid,
                $item->payment_gateway,
                $block,

            );
        }
        $json_data = array(
            "draw"            => intval($request->input('draw')),
            "recordsTotal"    => intval($totalData),
            "recordsFiltered" => $totalFiltered,
            "data"            => $data
        );
        echo json_encode($json_data);
        exit();
    }

    function deleteRedeemRequest(Request $request) { return response()->json(['status'=>false,'message'=>'Financial requests cannot be deleted. Retain for reconciliation.'],409); }

    function fetchPendingRedeems(Request $request)
    {

        $totalData =  RedeemRequest::where('status', '=', 0)->count();
        $rows = RedeemRequest::orderBy('id', 'DESC')->get();

        $result = $rows;

        $columns = array(
            0 => 'id'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
        $totalData = RedeemRequest::where('status', '=', 0)->count();

        $totalFiltered = $totalData;
        if (empty($request->input('search.value'))) {
            $result = RedeemRequest::where('status', '=', 0)
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');
            $result =  RedeemRequest::where('status', 0)
                ->Where('request_id', 'LIKE', "%{$search}%")
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
            $totalFiltered = RedeemRequest::where('status', 0)
                ->Where('request_id', 'LIKE', "%{$search}%")
                ->count();
        }
        $data = array();

        $app_data = AppData::first();

        foreach ($result as $item) {

            if (count($item->user->images) > 0) {
                $image = '<img src="public/storage/' . $item->user->images[0]->image . '" width="50" height="50">';
            } else {
                $image = '<img src="http://placehold.jp/150x150.png" width="50" height="50">';
            }

            $block = '<span class="float-end"><a href=""  rel="' . $item->id . '"   class="btn btn-success complete-redeem mr-2">Complete</a><a href = ""  rel = "' . $item->id . '" class = "btn btn-danger delete text-white" > Delete </a></span>';

            $payable_Amount = $app_data->coin_rate * $item->coin_amount;

            $data[] = array(
                $image,
                $item->user->fullname,
                $item->request_id,
                $item->coin_amount,
                $app_data->currency . ' ' . $payable_Amount,
                $item->payment_gateway,
                $block,
            );
        }
        $json_data = array(
            "draw"            => intval($request->input('draw')),
            "recordsTotal"    => intval($totalData),
            "recordsFiltered" => $totalFiltered,
            "data"            => $data
        );
        echo json_encode($json_data);
        exit();
    }

    function placeRedeemRequest(Request $request)
    {
        return response()->json(['status'=>false,'message'=>'Use Earn → Earnings & withdrawals. Gift coins are not cash earnings.'],409);
    }

    function fetchMyRedeemRequests(Request $request)
    {
        $user = auth('app_users')->user();
        if (!$user) return response()->json(['status'=>false],401);
        return response()->json(['status'=>true,'data'=>RedeemRequest::where('user_id',$user->id)->get()]);
    }


    function generateCode()
    {


        function generateRandomString($length)
        {
            $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            $charactersLength = strlen($characters);
            $randomString = '';
            for ($i = 0; $i < $length; $i++) {
                $randomString .= $characters[rand(0, $charactersLength - 1)];
            }
            return $randomString;
        }


        $token =  rand(100000, 999999);

        $first = generateRandomString(3);
        $first .= $token;
        $first .= generateRandomString(3);



        $count = RedeemRequest::where('request_id', $first)->count();

        while ($count >= 1) {

            $token =  rand(100000, 999999);

            $first = generateRandomString(3);
            $first .= $token;
            $first .= generateRandomString(3);
            $count = RedeemRequest::where('request_id', $first)->count();
        }

        return $first;
    }

    /**
     * F13: payout reconciliation (admin). Aggregates outstanding vs paid-out
     * balances so creator/user payouts can be reconciled against the ledger.
     * status 0 = pending, 1 = paid.
     */
    function reconcilePayouts(Request $request)
    {
        $coinRate = (float) AppData::first()->coin_rate;

        $pending = RedeemRequest::where('status', 0)
            ->selectRaw('COUNT(*) AS count, COALESCE(SUM(coin_amount),0) AS coins')
            ->first();
        $paid = RedeemRequest::where('status', 1)
            ->selectRaw('COUNT(*) AS count, COALESCE(SUM(coin_amount),0) AS coins, COALESCE(SUM(amount_paid),0) AS amount_paid')
            ->first();

        return response()->json([
            'status'  => true,
            'message' => 'Payout reconciliation fetched successfully',
            'coin_rate' => $coinRate,
            'pending' => [
                'count' => (int) $pending->count,
                'coins' => (int) $pending->coins,
                'value' => round(((int) $pending->coins) * $coinRate, 2),
            ],
            'paid' => [
                'count'       => (int) $paid->count,
                'coins'       => (int) $paid->coins,
                'amount_paid' => (float) $paid->amount_paid,
                'value'       => round(((int) $paid->coins) * $coinRate, 2),
            ],
            'outstanding_liability' => round(((int) $pending->coins) * $coinRate, 2),
        ]);
    }
}
