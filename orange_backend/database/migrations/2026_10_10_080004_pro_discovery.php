<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
return new class extends Migration {
    public function up(): void {
        $plan = DB::table('membership_plans')->where('code','pro')->first();
        if (!$plan) return;
        $features = json_decode($plan->features, true) ?? [];
        if (!in_array('priority_visibility', $features, true)) $features[] = 'priority_visibility';
        DB::table('membership_plans')->where('code','pro')->update(['features'=>json_encode($features),'updated_at'=>now()]);
    }
    public function down(): void {
        $plan = DB::table('membership_plans')->where('code','pro')->first();
        if ($plan) DB::table('membership_plans')->where('code','pro')->update(['features'=>json_encode(array_values(array_diff(json_decode($plan->features,true) ?? [], ['priority_visibility'])))]);
    }
};
