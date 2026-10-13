<?php
use Illuminate\Database\Migrations\Migration;use Illuminate\Database\Schema\Blueprint;use Illuminate\Support\Facades\Schema;
return new class extends Migration{public function up(){Schema::create('coin_transfers',function(Blueprint $t){$t->id();$t->unsignedBigInteger('sender_id');$t->unsignedBigInteger('receiver_id');$t->unsignedInteger('coins');$t->uuid('request_key');$t->unique(['sender_id','request_key']);$t->timestamps();});}public function down(){Schema::dropIfExists('coin_transfers');}};
