<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DataDeletionRequest extends Model
{
    protected $table = 'data_deletion_requests';

    protected $fillable = [
        'email',
        'username',
        'full_name',
        'request_type',
        'reason',
        'status',
        'admin_notes',
        'processed_at',
    ];

    protected $casts = [
        'processed_at' => 'datetime',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];

    public const TYPES = [
        'full_account' => 'Delete my entire account and all associated data',
        'data_only'    => 'Delete my data but keep my account active',
    ];

    public const STATUSES = [
        'pending'    => 'Pending',
        'processing' => 'Processing',
        'completed'  => 'Completed',
        'rejected'   => 'Rejected',
    ];
}
