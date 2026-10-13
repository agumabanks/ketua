<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Data Deletion Request &middot; KETUA</title>
<style>
:root{color-scheme:dark}
body{margin:0;background:#0e0e13;color:#eeeef4;font:16px/1.6 system-ui,sans-serif}
main{max-width:620px;margin:auto;padding:28px 24px 64px}
.brand{font-size:30px;font-weight:900;letter-spacing:1px;color:#ff3975}
.slogan{color:#adaab9;font-size:14px}
h1{font-size:28px;line-height:1.2}
a{color:#e5b4ff;overflow-wrap:anywhere}
label{display:block;margin:14px 0 4px;font-weight:600;font-size:14px}
input[type=text],input[type=email],textarea,select{width:100%;padding:10px 12px;border-radius:8px;border:1px solid #2a2a35;background:#16161e;color:#eeeef4;font:inherit;box-sizing:border-box}
textarea{min-height:90px;resize:vertical}
.radio-row{display:flex;align-items:flex-start;gap:10px;padding:12px 14px;border:1px solid #2a2a35;border-radius:8px;margin-top:8px;cursor:pointer;background:#16161e}
.radio-row:hover{border-color:#ff3975}
.radio-row input[type=radio]{margin-top:3px;accent-color:#ff3975}
.radio-row .desc{color:#adaab9;font-size:13px}
button{margin-top:20px;padding:12px 24px;border:none;border-radius:8px;background:#ff3975;color:#fff;font-weight:700;font-size:16px;cursor:pointer;width:100%}
button:hover{background:#e02e65}
.notice{padding:14px;border-radius:8px;margin-bottom:20px}
.notice.ok{background:#0f2a1a;border:1px solid #1d5c38;color:#4ade80}
.notice.warn{background:#2a1a0f;border:1px solid #5c3a1d;color:#fbbf24}
.error{color:#f87171;font-size:13px;margin-top:3px}
.back{margin-top:20px;text-align:center;font-size:14px}
.required{color:#ff3975}
</style>
</head>
<body>
<main>
  <div class="brand">KETUA</div>
  <div class="slogan">Meet. Vibe. Connect.</div>
  <h1>Request Data Deletion</h1>

  @if(session('deletion_success'))
    <div class="notice ok">{{ session('deletion_success') }}</div>
  @endif

  <p style="color:#adaab9">Use this form to request deletion of your personal data or your entire account. We process all requests within 30 days as required by applicable privacy regulations.</p>

  @if($errors->any())
    <div class="notice warn">
      @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
    </div>
  @endif

  <form method="POST" action="{{ route('dataDeletion.store') }}">
    @csrf

    <label for="email">Email address <span class="required">*</span></label>
    <input type="email" id="email" name="email" value="{{ old('email') }}" placeholder="you@example.com" required>

    <label for="full_name">Full name</label>
    <input type="text" id="full_name" name="full_name" value="{{ old('full_name') }}" placeholder="Your name (helps us locate your record)">

    <label for="username">Username</label>
    <input type="text" id="username" name="username" value="{{ old('username') }}" placeholder="Your KETUA username">

    <label>What would you like deleted? <span class="required">*</span></label>
    @foreach($types as $key => $label)
      <label class="radio-row">
        <input type="radio" name="request_type" value="{{ $key }}" {{ old('request_type') === $key ? 'checked' : '' }} required>
        <div>
          <strong>{{ $label }}</strong>
          @if($key === 'full_account')
            <div class="desc">Removes your profile, photos, posts, messages, likes, followers, and all associated data. This action is irreversible.</div>
          @else
            <div class="desc">Removes your personal data (photos, posts, messages) while keeping your account active for login purposes only.</div>
          @endif
        </div>
      </label>
    @endforeach

    <label for="reason">Reason for deletion (optional)</label>
    <textarea id="reason" name="reason" placeholder="Tell us why you're leaving (optional)">{{ old('reason') }}</textarea>

    <label class="radio-row" style="margin-top:16px">
      <input type="checkbox" name="confirm" value="1" required>
      <div>
        <strong>I understand this action may be irreversible</strong>
        <div class="desc">Once your data has been permanently deleted it cannot be recovered.</div>
      </div>
    </label>

    <button type="submit">Submit Deletion Request</button>
  </form>

  <div class="back">
    <a href="{{ route('privacypolicy') }}">Privacy Policy</a> &middot;
    <a href="{{ route('termsOfUse') }}">Terms of Use</a>
  </div>
</main>
</body>
</html>
