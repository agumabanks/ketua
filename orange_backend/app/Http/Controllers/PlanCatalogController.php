<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlanCatalogController extends Controller
{
    public function catalog()
    {
        $currencies = DB::table('currencies')->where('enabled', true)->orderByDesc('is_default')->get();
        $plans = DB::table('membership_plans')->where('enabled', true)->get();
        foreach ($plans as $plan) {
            $rule=DB::table('premium_rules')->where('plan_code',$plan->code)->first();
            $plan->features = $rule ? [
                $rule->session_likes===null?'Unlimited likes':$rule->session_likes.' likes per session',
                $rule->daily_rewinds===null?'Unlimited rewinds':($rule->daily_rewinds===0?'No rewinds':$rule->daily_rewinds.' rewinds per day'),
                $rule->weekly_stars.' Super Likes per week', 'Matching','Chat','Report and block',
            ] : json_decode($plan->features,true);
            if($rule?->hide_ads)$plan->features=array_merge($plan->features,['See who likes you','Hide ads','Control age and distance visibility','Incognito discovery']);
            if($rule?->passport)$plan->features[]='Worldwide discovery and chat';
            $plan->prices = DB::table('membership_prices')->where('plan_code', $plan->code)
                ->whereIn('currency_code', $currencies->pluck('code'))->get();
            // A catalog price is never proof of payment or a store checkout price.
            $plan->checkout_available = $plan->code!=='free';
        }
        return response()->json(['status'=>true,'default_currency'=>$currencies->first()->code ?? 'UGX',
            'currencies'=>$currencies,'plans'=>$plans,'languages'=>['en','fr','sw']]);
    }

    public function index()
    {
        return view('planCatalog', ['currencies'=>DB::table('currencies')->get(),
            'plans'=>DB::table('membership_plans')->get(), 'prices'=>DB::table('membership_prices')->get()]);
    }

    public function currency(Request $request)
    {
        $request->merge(['code'=>strtoupper((string)$request->input('code'))]);
        $v = $request->validate(['code'=>'required|regex:/^[A-Z]{3}$/','name'=>'required|string|max:80',
            'decimals'=>'required|integer|min:0|max:4','is_default'=>'nullable|boolean']);
        DB::transaction(function () use ($v) {
            DB::table('currencies')->lockForUpdate()->get();
            $existing=DB::table('currencies')->where('code',$v['code'])->first();
            if ($existing && (int)$existing->decimals !== (int)$v['decimals'] && DB::table('membership_prices')->where('currency_code',$v['code'])->whereNotNull('amount_minor')->exists()) {
                throw \Illuminate\Validation\ValidationException::withMessages(['decimals'=>'Decimal precision cannot change while this currency has configured prices.']);
            }
            if (!empty($v['is_default'])) DB::table('currencies')->update(['is_default'=>false]);
            DB::table('currencies')->updateOrInsert(['code'=>$v['code']], ['name'=>$v['name'],
                'decimals'=>$v['decimals'],'enabled'=>true,'is_default'=>!empty($v['is_default']) || ($existing && $existing->is_default),'updated_at'=>now()]);
        });
        return redirect()->route('planCatalog')->with('success','Currency saved.');
    }

    public function price(Request $request)
    {
        $v=$request->validate(['plan_code'=>'required|exists:membership_plans,code',
            'currency_code'=>'required|exists:currencies,code', 'amount_minor'=>'required|integer|min:0|max:100000000000',
            'period_days'=>'required|integer|min:1|max:366', 'store_product_id'=>'nullable|string|max:150|unique:membership_plans,store_product_id,'.$request->input('plan_code').',code']);
        if ($v['plan_code'] === 'free' && (int)$v['amount_minor'] !== 0) throw \Illuminate\Validation\ValidationException::withMessages(['amount_minor'=>'The Free plan must remain free.']);
        DB::transaction(function () use ($v) {
            DB::table('membership_prices')->updateOrInsert(['plan_code'=>$v['plan_code'],
                'currency_code'=>$v['currency_code'],'period_days'=>$v['period_days']],['amount_minor'=>$v['amount_minor']]);
            if (!empty($v['store_product_id'])) DB::table('membership_plans')->where('code',$v['plan_code'])->update([
                'store_product_id'=>$v['store_product_id'] ?? null, 'updated_at'=>now()]);
        });
        return redirect()->route('planCatalog')->with('success','Plan price saved. Checkout still requires verified store configuration.');
    }
}
