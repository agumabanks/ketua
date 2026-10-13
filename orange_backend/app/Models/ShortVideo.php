<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShortVideo extends Model
{
    use HasFactory;
    public $table = "short_videos";

    protected $fillable = [
        'user_id', 'video', 'thumbnail', 'caption', 'sound', 'duration_sec',
        'likes_count', 'comments_count', 'shares_count', 'views_count', 'hashtags',
    ];

    public function user()
    {
        return $this->belongsTo(Users::class, 'user_id', 'id')->select(['id','fullname','username','bio','gender','is_verified']);
    }

    public function scopeActive($q)
    {
        return $q->where('is_block', 0);
    }
}
