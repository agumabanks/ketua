<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;
    public $table = "conversations";

    protected $fillable = [
        'conversation_id', 'user_a', 'user_b', 'last_message', 'last_message_by',
        'last_message_at', 'blocked_by_a', 'blocked_by_b', 'muted_by_a', 'muted_by_b', 'cleared_through_a', 'cleared_through_b',
    ];
    protected $casts = ['last_message_at'=>'datetime'];

    public function userA()
    {
        return $this->belongsTo(Users::class, 'user_a', 'id');
    }

    public function userB()
    {
        return $this->belongsTo(Users::class, 'user_b', 'id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class, 'conversation_id', 'conversation_id')->orderBy('created_at');
    }
}
