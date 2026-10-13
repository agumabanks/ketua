<?php
namespace App\Services;
use Illuminate\Support\Facades\Http;use Illuminate\Support\Facades\Cache;
class KetuaPesapal {
 private function settings():array{$file='/var/lib/ketua-secrets/pesapal.json';return is_file($file)?(json_decode(file_get_contents($file),true)??[]):[];}
 public function configured():bool{$s=$this->settings();return !empty($s['consumer_key'])&&!empty($s['consumer_secret'])&&!empty($s['enabled']);}
 private function base():string{$s=$this->settings();$url=$s['api_url']??'https://pay.pesapal.com/v3';if(!in_array($url,['https://pay.pesapal.com/v3','https://cybqa.pesapal.com/pesapalv3'],true))throw new \RuntimeException('Invalid payment provider');return $url;}
 public function token():string{if(!$this->configured())throw new \RuntimeException('Payments are not configured');$s=$this->settings();return Cache::remember('ketua.pesapal.token.'.hash('sha256',$s['consumer_key']),now()->addMinutes(3),function()use($s){$r=Http::acceptJson()->timeout(20)->post($this->base().'/api/Auth/RequestToken',['consumer_key'=>$s['consumer_key'],'consumer_secret'=>$s['consumer_secret']]);$r->throw();$token=$r->json('token');if(!$token)throw new \RuntimeException('Payment provider unavailable');return $token;});}
 public function registerIpn():string{return Cache::remember('ketua.pesapal.ipn.'.hash('sha256',$this->base()),now()->addDay(),function(){$r=Http::acceptJson()->withToken($this->token())->timeout(20)->post($this->base().'/api/URLSetup/RegisterIPN',['url'=>'https://ketua.sanaa.co/api/payments/pesapal/ipn','ipn_notification_type'=>'GET']);$r->throw();$id=$r->json('ipn_id');if(!$id)throw new \RuntimeException('Payment notification unavailable');return $id;});}
 public function start($order,$user):array {
  $r=Http::acceptJson()->withToken($this->token())->timeout(25)->post($this->base().'/api/Transactions/SubmitOrderRequest',['id'=>$order->id,'currency'=>$order->currency_code,'amount'=>$order->amount_minor/(10**(int)\Illuminate\Support\Facades\DB::table('currencies')->where('code',$order->currency_code)->value('decimals')),'description'=>'KETUA account top-up','callback_url'=>'https://ketua.sanaa.co/api/payments/pesapal/return','notification_id'=>$this->registerIpn(),'billing_address'=>['email_address'=>$user->email??'','phone_number'=>$user->phone_number??'','first_name'=>$user->fullname??'KETUA member','country_code'=>'UG']]);$r->throw();$b=$r->json();
  if(($b['merchant_reference']??null)!==$order->id || empty($b['order_tracking_id']) || !self::trustedUrl($b['redirect_url']??''))throw new \RuntimeException('Invalid payment reference');return $b;
 }
 public static function trustedUrl(string $url):bool{$p=parse_url($url);return ($p['scheme']??'')==='https' && in_array(strtolower($p['host']??''),['pay.pesapal.com','cybqa.pesapal.com'],true)&&!isset($p['user']);}
 public function status(string $tracking):array{$r=Http::acceptJson()->withToken($this->token())->timeout(20)->get($this->base().'/api/Transactions/GetTransactionStatus',['orderTrackingId'=>$tracking]);$r->throw();return $r->json();}
}
