<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Gifts extends Model
{
    use HasFactory;
    public $table = "gifts";
    protected $appends = ['coin_price'];
    public function getCoinPriceAttribute() { return (int) ($this->attributes['price'] ?? 0); }
    public function setCoinPriceAttribute($value) { $this->attributes['price'] = (int) $value; }
    public function getNameAttribute($value) { return $value ?: ($this->attributes['title'] ?? 'Gift'); }
    public function setNameAttribute($value) { $this->attributes['name'] = $value; $this->attributes['title'] = $value; }
}
