@extends('include.app')
@section('content')
<div class="card p-4">
<h2>KETUA plans and currencies</h2><p><a href="{{route('premiumCommerce')}}">Super Like packs, allowances, ads and paid content</a></p>
<p>UGX is the default. Amounts use each currency’s smallest unit: UGX 39000 = 39,000 shillings; USD 999 = $9.99. Store checkout uses the actual localized store price. Adding a currency does not convert balances or existing prices.</p>
@if(session('success')) <div class="alert alert-success">{{ session('success') }}</div> @endif
@if($errors->any()) <div class="alert alert-danger">{{ $errors->first() }}</div> @endif
<h3>Currencies</h3>
<ul>@foreach($currencies as $currency)<li>{{ $currency->code }} — {{ $currency->name }} ({{ $currency->decimals }} decimal places) {{ $currency->is_default ? '· Default' : '' }}</li>@endforeach</ul>
<form method="post" action="{{ route('planCatalog.currency') }}">@csrf
<label>Currency code <input class="form-control" name="code" maxlength="3" required placeholder="UGX"></label>
<label>Name <input class="form-control" name="name" maxlength="80" required></label>
<label>Decimal places <input class="form-control" name="decimals" type="number" min="0" max="4" required value="0"></label>
<label><input name="is_default" type="checkbox" value="1"> Make default currency</label>
<button class="btn btn-primary">Save currency</button></form>
<hr><h3>Plan prices</h3>
<table class="table"><thead><tr><th>Plan</th><th>Currency</th><th>Smallest-unit amount</th><th>Days</th></tr></thead><tbody>
@foreach($prices as $price)<tr><td>{{ $price->plan_code }}</td><td>{{ $price->currency_code }}</td><td>{{ $price->amount_minor === null ? 'Not configured' : $price->amount_minor }}</td><td>{{ $price->period_days }}</td></tr>@endforeach
</tbody></table>
<form method="post" action="{{ route('planCatalog.price') }}">@csrf
<label>Plan <select name="plan_code" class="form-control">@foreach($plans as $plan)<option value="{{ $plan->code }}">{{ $plan->name }}</option>@endforeach</select></label>
<label>Currency <select name="currency_code" class="form-control">@foreach($currencies as $currency)<option>{{ $currency->code }}</option>@endforeach</select></label>
<label>Amount in smallest units <input name="amount_minor" class="form-control" type="number" min="0" step="1" required></label>
<label>Duration in days <input name="period_days" class="form-control" type="number" min="1" max="366" required value="30"></label>
<label>Store product ID <input name="store_product_id" class="form-control" maxlength="150"></label>
<button class="btn btn-primary">Save plan price</button></form>
</div>
@endsection
