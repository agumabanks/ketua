<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GiftTransaction extends Model
{
    use HasFactory;

    public $table = "gift_transactions";

    protected $fillable = [
        'client_key', 'sender_id',
        'receiver_id',
        'gift_id',
        'coin_price',
        'context',
    ];

    public function sender()
    {
        return $this->belongsTo(Users::class, 'sender_id', 'id');
    }

    public function receiver()
    {
        return $this->belongsTo(Users::class, 'receiver_id', 'id');
    }

    public function gift()
    {
        return $this->belongsTo(Gifts::class, 'gift_id', 'id');
    }
}
