@extends('include.app')

@section('header')
    <script src="{{ asset('asset/script/dataDeletion.js') }}"></script>
@endsection

@section('content')
    <div class="card mt-3">
        <div class="card-header">
            <h4>
                Data Deletion Requests
                <a target="_blank" class="btn btn-sm btn-outline-primary ml-2" href="{{ route('dataDeletion.create') }}">View Public Form</a>
            </h4>
        </div>
        <div class="card-body">

            {{-- Filters --}}
            <form method="GET" action="{{ route('dataDeletion.admin') }}" class="form-inline mb-3">
                <div class="form-group mr-2 mb-2">
                    <input type="text" name="search" class="form-control" placeholder="Search email / username / name"
                           value="{{ $filter['search'] ?? '' }}">
                </div>
                <div class="form-group mr-2 mb-2">
                    <select name="status" class="form-control">
                        <option value="">All statuses</option>
                        @foreach($statuses as $key => $label)
                            <option value="{{ $key }}" {{ ($filter['status'] ?? '') === $key ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <button type="submit" class="btn btn-primary mb-2">Filter</button>
                <a href="{{ route('dataDeletion.admin') }}" class="btn btn-light mb-2 ml-1">Reset</a>
            </form>

            <div class="table-responsive">
                <table class="table table-striped" id="dataDeletionTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Email</th>
                            <th>Username</th>
                            <th>Type</th>
                            <th>Status</th>
                            <th>Submitted</th>
                            <th>Processed</th>
                            <th>Account</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($requests as $req)
                            <tr data-id="{{ $req->id }}">
                                <td>{{ $req->id }}</td>
                                <td>{{ $req->email }}</td>
                                <td>{{ $req->username ?? '—' }}</td>
                                <td>
                                    <span class="badge badge-{{ $req->request_type === 'full_account' ? 'danger' : 'warning' }}">
                                        {{ $types[$req->request_type] ?? $req->request_type }}
                                    </span>
                                </td>
                                <td>
                                    <span class="badge status-badge badge-{{ [
                                        'pending'    => 'secondary',
                                        'processing' => 'info',
                                        'completed'  => 'success',
                                        'rejected'   => 'danger',
                                    ][$req->status] ?? 'secondary' }}">
                                        {{ $statuses[$req->status] ?? $req->status }}
                                    </span>
                                </td>
                                <td>{{ $req->created_at?->format('M j, Y H:i') }}</td>
                                <td>{{ $req->processed_at?->format('M j, Y H:i') ?? '—' }}</td>
                                <td>
                                    <a href="{{ route('dataDeletion.lookupUser', ['email' => $req->email]) }}"
                                       class="btn btn-sm btn-light lookup-btn" data-email="{{ $req->email }}" target="_blank">Look up</a>
                                </td>
                                <td>
                                    <button class="btn btn-sm btn-primary update-status-btn"
                                            data-id="{{ $req->id }}"
                                            data-status="{{ $req->status }}"
                                            data-notes="{{ $req->admin_notes }}">
                                        Update
                                    </button>
                                </td>
                            </tr>
                            @if($req->reason)
                                <tr>
                                    <td></td>
                                    <td colspan="8" style="background:#f8f9fa">
                                        <strong>Reason:</strong> {{ $req->reason }}
                                        @if($req->admin_notes)
                                            <br><strong>Admin notes:</strong> {{ $req->admin_notes }}
                                        @endif
                                    </td>
                                </tr>
                            @endif
                        @empty
                            <tr><td colspan="9" class="text-center text-muted py-4">No deletion requests found.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            {{ $requests->links() }}
        </div>
    </div>

    {{-- Status Update Modal --}}
    <div class="modal fade" id="statusModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Update Request <span id="modalReqId"></span></h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <input type="hidden" id="modal_id">
                    <div class="form-group">
                        <label>Status</label>
                        <select id="modal_status" class="form-control">
                            @foreach($statuses as $key => $label)
                                <option value="{{ $key }}">{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Admin notes</label>
                        <textarea id="modal_notes" class="form-control" rows="4" placeholder="Internal notes (optional)"></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="modalSaveBtn">Save Changes</button>
                </div>
            </div>
        </div>
    </div>

    <input type="hidden" value="{{ rtrim(config('app.url'), '/') . '/' }}" id="appUrl">
@endsection
