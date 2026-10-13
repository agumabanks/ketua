<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
 public function up(){
  Schema::create('place_listings',function(Blueprint $t){$t->id();$t->unsignedBigInteger('owner_id')->nullable()->index();$t->string('title',120);$t->string('category',20);$t->text('description');$t->string('country',100);$t->string('district',100);$t->string('town',100);$t->string('address',250);$t->decimal('latitude',10,7);$t->decimal('longitude',10,7);$t->string('currency_code',3);$t->unsignedBigInteger('price_min');$t->unsignedBigInteger('price_max');$t->string('price_unit',20);$t->text('includes');$t->string('image_url',500)->nullable();$t->string('status',20)->default('pending')->index();$t->boolean('published')->default(false);$t->text('review_note')->nullable();$t->timestamps();});
  Schema::create('place_slots',function(Blueprint $t){$t->id();$t->unsignedBigInteger('listing_id')->index();$t->dateTime('starts_at');$t->dateTime('ends_at');$t->unsignedBigInteger('amount_minor');$t->unsignedInteger('capacity');$t->boolean('enabled')->default(true);$t->timestamps();});
  Schema::create('place_reservations',function(Blueprint $t){$t->id();$t->uuid('reference')->unique();$t->unsignedBigInteger('user_id')->index();$t->unsignedBigInteger('listing_id')->index();$t->uuid('request_key');$t->unsignedInteger('quantity');$t->unsignedBigInteger('total_minor');$t->string('currency_code',3);$t->string('status',20)->default('requested')->index();$t->text('review_note')->nullable();$t->timestamps();$t->unique(['user_id','request_key']);});
  Schema::create('place_reservation_slots',function(Blueprint $t){$t->id();$t->unsignedBigInteger('reservation_id')->index();$t->unsignedBigInteger('slot_id')->index();$t->unsignedInteger('quantity');$t->unique(['reservation_id','slot_id']);});
 }
 public function down(){foreach(['place_reservation_slots','place_reservations','place_slots','place_listings'] as $table)Schema::dropIfExists($table);}
};
