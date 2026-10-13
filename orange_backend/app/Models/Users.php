<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Users extends Authenticatable
{
    use HasFactory, HasApiTokens;

    public $table = "users";
    public $timestamps = false;

    /**
     * K10: never leak credentials or sensitive internals in API JSON.
     * (Laravel 8 uses $hidden; $visible stays unset so other fields pass through.)
     */
    protected $hidden = [
        'password',
        'remember_token',
        'device_token',
    ];

    public function images()
    {
        return $this->hasMany(Images::class, 'user_id', 'id')->orderBy('sort_order')->orderBy('id');
    }

    // A legacy compatibility migration added a nullable users.images column.
    // Always read photos from the owned image records, never that shadow column.
    public function getImagesAttribute($value)
    {
        return $this->getRelationValue('images');
    }

    public function notifications()
    {
        return $this->hasMany(UserNotification::class, 'user_id', 'id');
    }

    public function interests()
    {
        return $this->hasMany(Interest::class, 'id', 'interests');
    }

    function liveApplications()
    {
        return $this->hasOne(LiveApplications::class, 'user_id', 'id');
    }
    
    function verifyRequest()
    {
        return $this->hasOne(VerifyRequest::class, 'user_id', 'id');
    }

    function liveHistory()
    {
        return $this->hasMany(LiveHistory::class, 'user_id', 'id');
    }

    function redeemRequests()
    {
        return $this->hasMany(RedeemRequest::class, 'user_id', 'id');
    }

    public function stories()
    {
        return $this->hasMany(Story::class, 'user_id', 'id');
    }
}
