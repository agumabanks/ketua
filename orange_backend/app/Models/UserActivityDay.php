<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserActivityDay extends Model
{
    use HasFactory;
    public $table = "user_activity_days";

    protected $fillable = ['user_id', 'activity_date', 'first_seen_at', 'last_seen_at'];
    protected $casts = ['activity_date'=>'datetime', 'first_seen_at'=>'datetime', 'last_seen_at'=>'datetime'];
}
