<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserBoost extends Model
{
    use HasFactory;
    public $table = "user_boosts";
    protected $fillable = ['user_id', 'coin_price', 'started_at', 'expires_at'];
    protected $casts = ['started_at'=>'datetime', 'expires_at'=>'datetime'];

    public function scopeActive($q)
    {
        return $q->where('expires_at', '>', now());
    }
}
