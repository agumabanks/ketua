<?php

namespace App\Http\Controllers;

use App\Models\GlobalFunction;
use App\Models\LiveApplications;
use App\Models\LiveHistory;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LiveApplicationController extends Controller
{
    function liveapplication()
    {
        return view('liveapplication');
    }

    function livehistory()
    {
        return view('livehistory');
    }

    function fetchAllLiveStreamHistory(Request $request) {
        $v=$request->validate(['start'=>'nullable|integer|min:0','count'=>'nullable|integer|min:1|max:100']);
        return response()->json(['status'=>true,'data'=>LiveHistory::where('user_id',auth('app_users')->user()->id)->orderByDesc('id')->offset($v['start']??0)->limit($v['count']??20)->get()]);
    }

    function fetchLiveHistory(Request $request)
    {
        $totalData =  LiveHistory::count();
        $rows = LiveHistory::orderBy('id', 'DESC')->get();

        $result = $rows;

        $columns = array(
            0 => 'id'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
        $totalData = LiveHistory::count();
        $totalFiltered = $totalData;
        if (empty($request->input('search.value'))) {
            $result = LiveHistory::offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');
            $result =  LiveHistory::Where('title', 'LIKE', "%{$search}%")
                ->orWhere('id', 'LIKE', "%{$search}%")
                ->orWhere('amount_collected', 'LIKE', "%{$search}%")
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
            $totalFiltered = LiveHistory::where('id', 'LIKE', "%{$search}%")
                ->orWhere('amount_collected', 'LIKE', "%{$search}%")
                ->count();
        }
        $data = array();
        foreach ($result as $item) {

            if (count($item->user->images) > 0) {
                $image = '<img src="public/storage/' . $item->user->images[0]->image . '" width="50" height="50">';
            } else {
                $image = '<img src="http://placehold.jp/150x150.png" width="50" height="50">';
            }

            // $introVideo = '<a href=""  rel="' . $item->intro_video . '"   class="btn btn-warning  intro_video mr-2"><i class="fas fa-play"></i></a>';

            $data[] = array(
                $image,
                $item->user->fullname,
                $item->started_at,
                $item->streamed_for,
                $item->amount_collected,
                date('d-M-Y', strtotime($item->created_at)),

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

    function addLiveStreamHistory(Request $request) {
        return response()->json(['status'=>false,'message'=>'Stream history must be recorded by a verified live provider.'],409);
    }

    public function approveApplication(Request $request)
    {
        $liveRequest = LiveApplications::where('id', $request->application_id)->first();
        if ($liveRequest) {

            GlobalFunction::deleteFile($liveRequest->intro_video);

            $user = Users::where('id', $liveRequest->user_id)->first();
            $user->can_go_live = 2;
            $user->save();
            
            $liveRequest->delete();

            return response()->json([
                'status' => true,
                'message' => 'Live Application Approved',
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'Live Application Not Found',
            ]);    
        }     
    }

    function viewLiveApplication($id)
    {
        $data = LiveApplications::where('id', $id)->first();

        return view('viewLiveApplication', ['data' => $data]);
    }

    function deleteLiveApplication(Request $request)
    {
        $liveRequest = LiveApplications::where('id', $request->application_id)->first();
        if ($liveRequest) {

            GlobalFunction::deleteFile($liveRequest->intro_video);

            $user = Users::where('id', $liveRequest->user_id)->first();
            $user->can_go_live = 0;
            $user->save();

            $liveRequest->delete();

            return response()->json([
                'status' => true,
                'message' => 'Delete Live Application',
            ]);
        } else {
            return response()->json([
                'status' => false,
                'message' => 'Live Application Not Found',
            ]);    
        }       
    }

    function fetchLiveApplications(Request $request)
    {
        $totalData =  LiveApplications::count();
        $rows = LiveApplications::orderBy('id', 'DESC')->get();

        $result = $rows;

        $columns = array(
            0 => 'id',
            1 => 'title'
        );

        $limit = $request->input('length');
        $start = $request->input('start');
        $order = $columns[$request->input('order.0.column')];
        $dir = $request->input('order.0.dir');
        $totalData = LiveApplications::count();
        $totalFiltered = $totalData;
        if (empty($request->input('search.value'))) {
            $result = LiveApplications::offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
        } else {
            $search = $request->input('search.value');
            $result =  LiveApplications::Where('title', 'LIKE', "%{$search}%")
                ->orWhere('message', 'LIKE', "%{$search}%")
                ->offset($start)
                ->limit($limit)
                ->orderBy($order, $dir)
                ->get();
            $totalFiltered = LiveApplications::where('title', 'LIKE', "%{$search}%")
                ->orWhere('message', 'LIKE', "%{$search}%")
                ->count();
        }
        $data = array();
        foreach ($result as $item) {

            if (count($item->user->images) > 0) {
                $image = '<img src="public/storage/' . $item->user->images[0]->image . '" width="50" height="50">';
            } else {
                $image = '<img src="http://placehold.jp/150x150.png" width="50" height="50">';
            }

            $block = '<span class="float-end"><a href="' . route('viewLiveApplication', $item->id) . '"  rel="' . $item->id . '"   class="btn btn-primary view_application mr-2">View</a><a href = ""  rel = "' . $item->id . '" class = "btn btn-danger reject text-white" > Reject </a></span>';
            // $introVideo = '<a href=""  rel="' . $item->intro_video . '"   class="btn btn-warning  intro_video mr-2"><i class="fas fa-play"></i></a>';

            $data[] = array(
                $image,
                $item->user->fullname,
                $item->languages,
                $block

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

    public function eligibility(Request $request) {
        $user=auth('app_users')->user();
        abort_unless($user,401);
        $adult=$user->dob && \Carbon\Carbon::parse($user->dob)->age>=18;
        $state=(int)$user->can_go_live;
        $configured=(bool)config('ketua.live_enabled') && preg_match('/^[a-fA-F0-9]{32}$/',(string)config('ketua.agora_app_id')) && preg_match('/^[a-fA-F0-9]{32}$/',(string)config('ketua.agora_app_certificate'));
        return response()->json(['status'=>true,'data'=>[
            'application_state'=>[0=>'Not applied',1=>'Pending review',2=>'Approved'][$state]??'Not approved',
            'can_apply'=>$adult && $state===0,
            'can_broadcast'=>$adult && $state===2 && $configured,
            'service_available'=>(bool)$configured,
            'message'=>!$adult?'Hosting requires an adult account.':(!$configured?'Live broadcasting is not available yet. Applications can be reviewed by the administrator.':($state===2?'Your hosting application is approved.':($state===1?'Your application is awaiting administrator review.':'Apply to host live conversations.')))
        ]]);
    }
    public function applyForLive(Request $request) {
        $id=auth('app_users')->user()?->id;
        abort_unless($id,401);
        $v=$request->validate([
            'about_you'=>'required|string|max:2000',
            'languages'=>'required|string|max:200',
            'intro_video'=>'required|file|mimetypes:video/mp4,video/quicktime,video/webm|max:25600',
            'social_links'=>'required|string|max:2000'
        ]);
        $path=null;
        try {
            return \Illuminate\Support\Facades\DB::transaction(function() use($request,$id,$v,&$path){
                $user=Users::where('id',$id)->lockForUpdate()->firstOrFail();
                if(!$user->dob || \Carbon\Carbon::parse($user->dob)->age<18) return response()->json(['status'=>false,'message'=>'Hosting requires an adult account.'],403);
                if((int)$user->can_go_live!==0 || LiveApplications::where('user_id',$id)->exists()) return response()->json(['status'=>false,'message'=>'Your application already exists or has been reviewed.'],409);
                $path=GlobalFunction::saveFileAndGivePath($request->file('intro_video'),['mp4','mov','webm'],25*1024*1024);
                $application=new LiveApplications();$application->user_id=$id;
                $application->about_you=$v['about_you'];$application->languages=$v['languages'];
                $application->intro_video=$path;$application->social_links=json_encode($v['social_links']);$application->save();
                $user->can_go_live=1;$user->save();
                return response()->json(['status'=>true,'message'=>'Application submitted for administrator review.']);
            });
        } catch(\Throwable $e) { if($path) GlobalFunction::deleteFile($path);throw $e; }
    }
}
