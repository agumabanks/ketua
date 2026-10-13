<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserMilestone extends Model
{
    use HasFactory;
    public $table = "user_milestones";
    protected $fillable = ['user_id', 'streak_days', 'achieved_at'];
    protected $casts = ['achieved_at'=>'datetime'];
}
