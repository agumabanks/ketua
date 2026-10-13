<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;
    public $table = "messages";

    protected $fillable = [
        'conversation_id', 'sender_id', 'receiver_id', 'body', 'message_type',
        'client_key', 'reply_to_id', 'media', 'is_read', 'read_at', 'is_deleted',
    ];
    protected $casts = ['read_at'=>'datetime'];

    public function sender()
    {
        return $this->belongsTo(Users::class, 'sender_id', 'id');
    }

    public function receiver()
    {
        return $this->belongsTo(Users::class, 'receiver_id', 'id');
    }
}
