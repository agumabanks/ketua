@extends('include.app')
@section('content')
<h2>Experiences · events, parties & live events</h2>
<p>Times use UTC. Prices use minor currency units: UGX 37000 = UGX 37,000; USD 1000 = USD 10.00. Paid checkout is unavailable until configured. Preview events cannot issue tickets.</p>
@if(session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif
@if($errors->any())<div class="alert alert-danger">{{ $errors->first() }}</div>@endif
@foreach($experiences->prepend(null) as $event)
<div class="card"><div class="card-body"><h4>{{ $event ? 'Edit: '.$event->title : 'Create experience' }}</h4>
<form method="post" action="{{ route('experiences.save') }}">@csrf
@if($event)<input type="hidden" name="id" value="{{ $event->id }}">@endif
<label>Title<input class="form-control" name="title" maxlength="120" value="{{ $event->title ?? '' }}" required></label>
<label>Category<select name="category" class="form-control">@foreach(['event','party','live'] as $category)<option value="{{ $category }}" @selected(($event->category ?? '') === $category)>{{ ucfirst($category) }}</option>@endforeach</select></label>
<label>Description<textarea name="description" class="form-control" required>{{ $event->description ?? '' }}</textarea></label>
<label>Venue<input name="venue" class="form-control" value="{{ $event->venue ?? '' }}" required></label>
<label>Starts UTC<input type="datetime-local" name="starts_at" class="form-control" value="{{ $event ? date('Y-m-d\TH:i', strtotime($event->starts_at)) : '' }}" required></label>
<label>Ends UTC<input type="datetime-local" name="ends_at" class="form-control" value="{{ $event ? date('Y-m-d\TH:i', strtotime($event->ends_at)) : '' }}" required></label>
<label>Currency<select name="currency_code" class="form-control">@foreach($currencies as $currency)<option value="{{ $currency->code }}" @selected(($event->currency_code ?? 'UGX') === $currency->code)>{{ $currency->code }}</option>@endforeach</select></label>
<label>Price in minor units<input type="number" name="amount_minor" min="0" class="form-control" value="{{ $event->amount_minor ?? 0 }}" required></label>
<label>Capacity<input type="number" name="capacity" min="1" class="form-control" value="{{ $event->capacity ?? 100 }}" required></label>
<input type="hidden" name="published" value="0"><label><input type="checkbox" name="published" value="1" @checked($event->published ?? false)> Published</label>
<input type="hidden" name="is_demo" value="0"><label><input type="checkbox" name="is_demo" value="1" @checked($event->is_demo ?? false)> Preview only</label>
<button class="btn btn-primary">Save experience</button>
</form></div></div>
@endforeach
@endsection
