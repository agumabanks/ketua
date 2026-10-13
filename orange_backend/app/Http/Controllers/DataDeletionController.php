<?php

namespace App\Http\Controllers;

use App\Models\DataDeletionRequest;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DataDeletionController extends Controller
{
    /**
     * Public form for users to request deletion of their data.
     */
    public function create()
    {
        return view('dataDeletion.request', [
            'types'   => DataDeletionRequest::TYPES,
            'success' => session('deletion_success'),
        ]);
    }

    /**
     * Store a new deletion request from the public form.
     */
    public function store(Request $request)
    {
        $rules = [
            'email'        => 'required|email|max:255',
            'full_name'    => 'nullable|string|max:255',
            'username'     => 'nullable|string|max:255',
            'request_type' => 'required|in:full_account,data_only',
            'reason'       => 'nullable|string|max:2000',
            'confirm'      => 'accepted',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            if ($request->expectsJson()) {
                return response()->json([
                    'status'  => false,
                    'message' => $validator->errors()->first(),
                ], 422);
            }
            return back()->withErrors($validator)->withInput();
        }

        $data = $validator->validated();
        unset($data['confirm']);

        $deletion = DataDeletionRequest::create($data);

        if ($request->expectsJson()) {
            return response()->json([
                'status'  => true,
                'message' => 'Your data deletion request has been submitted. Our team will review it within 30 days.',
            ]);
        }

        return redirect()
            ->route('dataDeletion.create')
            ->with('deletion_success', 'Your data deletion request has been submitted. Our team will review it within 30 days.');
    }

    /**
     * Admin panel listing all deletion requests.
     */
    public function index(Request $request)
    {
        $query = DataDeletionRequest::orderByDesc('id');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $term = $request->search;
            $query->where(function ($q) use ($term) {
                $q->where('email', 'like', "%{$term}%")
                  ->orWhere('username', 'like', "%{$term}%")
                  ->orWhere('full_name', 'like', "%{$term}%");
            });
        }

        $requests = $query->paginate(25)->withQueryString();

        return view('dataDeletion.admin', [
            'requests'  => $requests,
            'statuses'  => DataDeletionRequest::STATUSES,
            'types'     => DataDeletionRequest::TYPES,
            'filter'    => $request->only('status', 'search'),
        ]);
    }

    /**
     * Update the status of a deletion request (admin).
     */
    public function updateStatus(Request $request, $id)
    {
        $rules = [
            'status'      => 'required|in:pending,processing,completed,rejected',
            'admin_notes' => 'nullable|string|max:2000',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        $deletion = DataDeletionRequest::findOrFail($id);
        $deletion->status      = $request->status;
        $deletion->admin_notes = $request->admin_notes ?? $deletion->admin_notes;

        if (in_array($request->status, ['completed', 'rejected'])) {
            $deletion->processed_at = now();
        }

        $deletion->save();

        return response()->json([
            'status'  => true,
            'message' => "Request #{$id} updated to \"{$request->status}\".",
        ]);
    }

    /**
     * Look up a matching user account by email (admin helper).
     */
    public function lookupUser(Request $request)
    {
        $email = $request->query('email');
        if (!$email) {
            return response()->json(['status' => false, 'message' => 'Email is required']);
        }

        $user = Users::where('email', $email)->first();
        if (!$user) {
            return response()->json([
                'status'  => true,
                'found'   => false,
                'message' => 'No account found with that email.',
            ]);
        }

        return response()->json([
            'status'    => true,
            'found'     => true,
            'user_id'   => $user->id,
            'username'  => $user->username,
            'full_name' => $user->fullname,
        ]);
    }
}
