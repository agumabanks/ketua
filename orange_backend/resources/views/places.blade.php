@extends('include.app')
@section('content')
<h2>Explore places & reservations</h2>
<p>Dating, AirStay and spa listings. Member submissions remain private until approved and published. Reservations are requests, with no payment taken. Confirm only after checking venue availability. Prices use minor units; times below are UTC.</p>
@if(session('success'))<div class="alert alert-success">{{session('success')}}</div>@endif
@if($errors->any())<div class="alert alert-danger">{{$errors->first()}}</div>@endif
@foreach($places->prepend(null) as $p)
<div class="card"><div class="card-body"><h4>{{$p?->title ?? 'New listing'}}</h4>
@if($p?->owner_id)<p>Submitted by member #{{$p->owner_id}}</p>@endif
<form method="post" action="{{route('places.save')}}">@csrf
@if($p)<input type="hidden" name="id" value="{{$p->id}}">@endif
@foreach(['title','description','country','district','town','address','includes','image_url'] as $field)<label>{{ucfirst(str_replace('_',' ',$field))}}<input class="form-control" name="{{$field}}" value="{{$p?->$field}}" @if($field!=='image_url') required @endif></label>@endforeach
<label>Category<select name="category">@foreach(['date'=>'Dating','stay'=>'AirStay','spa'=>'Massage & spa'] as $k=>$label)<option value="{{$k}}" @selected($p?->category===$k)>{{$label}}</option>@endforeach</select></label>
@foreach(['latitude','longitude','price_min','price_max'] as $f)<label>{{$f}}<input type="number" step="{{$f==='latitude'||$f==='longitude'?'any':'1'}}" name="{{$f}}" value="{{$p?->$f}}" required></label>@endforeach
<label>Currency<select name="currency_code">@foreach($currencies as $c)<option @selected(($p?->currency_code ?? 'UGX')===$c->code)>{{$c->code}}</option>@endforeach</select></label>
<label>Price unit<select name="price_unit">@foreach(['person','night','session'] as $unit)<option @selected($p?->price_unit===$unit)>{{$unit}}</option>@endforeach</select></label>
<label>Review<select name="status">@foreach(['pending','approved','rejected'] as $status)<option @selected($p?->status===$status)>{{$status}}</option>@endforeach</select></label>
<label>Review note<input name="review_note" value="{{$p?->review_note}}"></label>
<input type="hidden" name="published" value="0"><label><input type="checkbox" name="published" value="1" @checked($p?->published)>Published</label><button class="btn btn-primary">Save listing</button>
</form>
@if($p)<hr><h5>Add availability for {{$p->title}}</h5><form method="post" action="{{route('places.slot')}}">@csrf<input type="hidden" name="listing_id" value="{{$p->id}}"><label>Starts UTC<input type="datetime-local" name="starts_at" required></label><label>Ends UTC<input type="datetime-local" name="ends_at" required></label><label>Exact price per unit<input type="number" name="amount_minor" min="0" required></label><label>Capacity<input type="number" name="capacity" min="1" required></label><button>Add slot</button></form>
@foreach($slots->where('listing_id',$p->id) as $s)<p>#{{$s->id}} · {{$s->starts_at}} → {{$s->ends_at}} · {{$p->currency_code}} {{$s->amount_minor}} · {{$s->capacity}} available units</p>@endforeach
@endif</div></div>
@endforeach
<h3>Reservation requests</h3>
@foreach($reservations as $r)<div class="card"><div class="card-body"><h4>{{$r->title}} · {{$r->status}}</h4><p>{{$r->reference}} · Member #{{$r->user_id}} · {{$r->quantity}} units · {{$r->currency_code}} {{$r->total_minor}} · No online payment taken.</p><form method="post" action="{{route('places.review')}}">@csrf<input type="hidden" name="id" value="{{$r->id}}"><select name="status"><option>confirmed</option><option>rejected</option><option>cancelled</option></select><input name="review_note" placeholder="Venue confirmation / reason"><button>Update reservation</button></form></div></div>@endforeach
@endsection
