<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserHeartbeat extends Model
{
    use HasFactory;
    public $table = "user_heartbeats";
    protected $fillable = ['user_id', 'last_seen_at'];
    protected $casts = ['last_seen_at'=>'datetime'];
}
