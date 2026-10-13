<?php
require dirname(__DIR__).'/vendor/autoload.php';
$app=require dirname(__DIR__).'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use App\Http\Controllers\PlanCatalogController;
if (config('database.connections.mysql.database') !== 'ketua_test') throw new RuntimeException('Use ketua_test only');
$controller=new PlanCatalogController; $passes=0;
$before=DB::table('membership_prices')->where('plan_code','gold')->where('currency_code','UGX')->where('period_days',30)->value('amount_minor');
$currency=DB::table('currencies')->where('code','UGX')->first();
$existing=DB::table('membership_plans')->where('code','gold')->value('store_product_id');
try {
 $controller->price(new Request(['plan_code'=>'gold','currency_code'=>'UGX','period_days'=>30,'amount_minor'=>38000]));
 if (DB::table('membership_prices')->where('plan_code','gold')->where('currency_code','UGX')->where('period_days',30)->value('amount_minor') != 38000) throw new RuntimeException('Price edit failed');
 echo 'PASS: admin can adjust Gold pricing'.PHP_EOL;$passes++;
 if (DB::table('membership_plans')->where('code','gold')->value('store_product_id') !== $existing) throw new RuntimeException('Product mapping lost');
 echo 'PASS: price-only edit preserves store mapping'.PHP_EOL;$passes++;
 $controller->currency(new Request(['code'=>'UGX','name'=>$currency->name,'decimals'=>0]));
 if (!DB::table('currencies')->where('code','UGX')->value('is_default')) throw new RuntimeException('Default lost');
 echo 'PASS: currency edit preserves default'.PHP_EOL;$passes++;
 foreach ([['plan_code'=>'free','currency_code'=>'UGX','period_days'=>30,'amount_minor'=>1], ['plan_code'=>'gold','currency_code'=>'UGX','period_days'=>30,'amount_minor'=>-1]] as $bad) {
  try { $controller->price(new Request($bad)); throw new RuntimeException('Invalid price accepted'); }
  catch (Illuminate\Validation\ValidationException $e) { echo 'PASS: invalid/free plan charge rejected'.PHP_EOL;$passes++; }
 }
 try { $controller->currency(new Request(['code'=>'UGX','name'=>$currency->name,'decimals'=>2])); throw new RuntimeException('Precision changed'); }
 catch (Illuminate\Validation\ValidationException $e) { echo 'PASS: configured currency precision protected'.PHP_EOL;$passes++; }
 echo "RESULT: $passes/$passes catalog admin checks passed".PHP_EOL;
} finally {
 DB::table('membership_prices')->where('plan_code','gold')->where('currency_code','UGX')->where('period_days',30)->update(['amount_minor'=>$before]);
 DB::table('currencies')->where('code','UGX')->update(['name'=>$currency->name,'decimals'=>$currency->decimals,'is_default'=>$currency->is_default]);
}
