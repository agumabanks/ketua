<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;
    public $table = "subscriptions";

    protected $fillable = [
        'user_id', 'plan', 'product_id', 'status',
        'started_at', 'expires_at', 'provider', 'provider_txn_id', 'last_event_ms',
    ];

    protected $casts = ['started_at'=>'datetime', 'expires_at'=>'datetime'];

    public function scopeActive($q)
    {
        return $q->where(function ($status) {
            $status->where('status','active')->orWhere(function ($cancelled) {
                $cancelled->where('status','cancelled')->whereNotNull('expires_at');
            });
        })
            ->where(function ($w) {
                $w->whereNull('expires_at')->orWhere('expires_at', '>', now());
            });
    }

    public function user()
    {
        return $this->belongsTo(Users::class, 'user_id', 'id');
    }
}
