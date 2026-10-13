<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{{ $title }} · KETUA</title><style>
:root{color-scheme:dark}body{margin:0;background:#0e0e13;color:#eeeeF4;font:17px/1.7 system-ui,sans-serif}main{max-width:760px;margin:auto;padding:28px 24px 64px}.brand{font-size:30px;font-weight:900;letter-spacing:1px;color:#ff3975}.slogan{color:#adaab9;font-size:14px}h1{font-size:32px;line-height:1.2}h2,h3{line-height:1.35;margin-top:1.7em}a{color:#e5b4ff;overflow-wrap:anywhere}p,li{overflow-wrap:anywhere}table{max-width:100%;display:block;overflow:auto}article{margin-top:28px}blockquote{border-left:3px solid #ff3975;padding-left:16px}
</style></head><body><main><div class="brand">KETUA</div><div class="slogan">Meet. Vibe. Connect.</div><h1>{{ $title }}</h1><article>@if($available){!! $content !!}@else<p>This policy has not been published. Please contact KETUA support before proceeding.</p>@endif</article>
<div style="margin-top:40px;padding-top:20px;border-top:1px solid #2a2a35;text-align:center;font-size:14px;color:#adaab9">
  <a href="{{ route('dataDeletion.create') }}">Request Data Deletion</a> &middot;
  <a href="{{ route('csae') }}">Child Safety (CSAE)</a> &middot;
  <a href="{{ route('privacypolicy') }}">Privacy Policy</a> &middot;
  <a href="{{ route('termsOfUse') }}">Terms of Use</a>
</div>
</main></body></html>