<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>KETUA — Meet. Vibe. Connect.</title>
<meta name="description" content="KETUA is where real connections begin. Discover people nearby, go live, and vibe with your community.">
<link rel="icon" type="image/x-icon" href="{{ asset('asset/img/favicon.png') }}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
  --bg:#0e0e13; --bg2:#16161f; --card:#1c1c28; --line:#2a2a3a;
  --pink:#ff3975; --pink2:#ff6b9d; --purple:#a259ff; --text:#f2f2f7; --muted:#9a97ad;
  --grad:linear-gradient(120deg,#ff3975,#a259ff);
}
*{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth}
body{background:var(--bg);color:var(--text);font-family:'Plus Jakarta Sans',system-ui,-apple-system,sans-serif;line-height:1.6;overflow-x:hidden}
a{color:inherit;text-decoration:none}
.wrap{max-width:1140px;margin:0 auto;padding:0 24px}
img{max-width:100%}

/* NAV */
nav{position:fixed;top:0;left:0;right:0;z-index:50;backdrop-filter:blur(14px);background:rgba(14,14,19,.72);border-bottom:1px solid rgba(255,255,255,.06)}
.nav-in{display:flex;align-items:center;justify-content:space-between;height:68px}
.brand{display:flex;align-items:center;gap:10px;font-weight:800;font-size:22px;letter-spacing:.5px}
.brand .dot{width:10px;height:10px;border-radius:50%;background:var(--grad);box-shadow:0 0 14px var(--pink)}
.nav-links{display:flex;align-items:center;gap:28px;font-size:15px;font-weight:500}
.nav-links a{color:var(--muted);transition:color .2s}
.nav-links a:hover{color:var(--text)}
.btn{display:inline-flex;align-items:center;gap:8px;padding:11px 22px;border-radius:12px;font-weight:700;font-size:15px;transition:transform .15s,box-shadow .2s;border:none;cursor:pointer}
.btn-primary{background:var(--grad);color:#fff;box-shadow:0 8px 24px rgba(255,57,117,.35)}
.btn-primary:hover{transform:translateY(-2px);box-shadow:0 12px 32px rgba(255,57,117,.45)}
.btn-ghost{background:rgba(255,255,255,.06);color:var(--text);border:1px solid var(--line)}
.btn-ghost:hover{background:rgba(255,255,255,.1)}
.nav-toggle{display:none;background:none;border:none;color:var(--text);font-size:26px;cursor:pointer}

/* HERO */
.hero{position:relative;padding:150px 0 90px;text-align:center;overflow:hidden}
.hero::before{content:"";position:absolute;top:-180px;left:50%;transform:translateX(-50%);width:820px;height:820px;background:radial-gradient(circle,rgba(255,57,117,.22),transparent 62%);pointer-events:none}
.hero::after{content:"";position:absolute;bottom:-260px;right:-160px;width:620px;height:620px;background:radial-gradient(circle,rgba(162,89,255,.18),transparent 62%);pointer-events:none}
.hero-badge{display:inline-flex;align-items:center;gap:8px;padding:7px 16px;border-radius:999px;background:rgba(255,57,117,.12);border:1px solid rgba(255,57,117,.3);color:var(--pink2);font-size:13px;font-weight:600;margin-bottom:26px}
.hero h1{font-size:clamp(38px,6vw,68px);font-weight:800;line-height:1.08;letter-spacing:-1px;margin-bottom:20px}
.hero h1 .grad{background:var(--grad);-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent}
.hero p{font-size:clamp(16px,2.2vw,20px);color:var(--muted);max-width:560px;margin:0 auto 36px}
.hero-cta{display:flex;gap:14px;justify-content:center;flex-wrap:wrap}
.hero-stats{display:flex;gap:44px;justify-content:center;margin-top:60px;flex-wrap:wrap}
.hero-stats .num{font-size:30px;font-weight:800;background:var(--grad);-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent}
.hero-stats .lbl{font-size:13px;color:var(--muted)}

/* phone mock */
.phone{width:250px;height:500px;border-radius:40px;border:8px solid #26263a;background:var(--bg2);margin:56px auto 0;position:relative;box-shadow:0 30px 80px rgba(0,0,0,.5);overflow:hidden}
.phone .notch{position:absolute;top:12px;left:50%;transform:translateX(-50%);width:90px;height:22px;background:#000;border-radius:20px;z-index:2}
.phone .screen{position:absolute;inset:0;background:linear-gradient(160deg,#1f1f30,#12121c);display:flex;flex-direction:column;padding:52px 16px 16px}
.pcard{flex:1;border-radius:20px;background:linear-gradient(160deg,#2a1a2e,#1a1428);position:relative;overflow:hidden;border:1px solid rgba(255,255,255,.06)}
.pcard .pfill{position:absolute;inset:0;background:radial-gradient(circle at 60% 30%,rgba(255,57,117,.25),transparent 60%),radial-gradient(circle at 30% 80%,rgba(162,89,255,.25),transparent 60%)}
.pcard .pname{position:absolute;bottom:14px;left:16px;font-weight:700}
.pcard .pname small{display:block;color:var(--muted);font-weight:500;font-size:12px}
.pactions{display:flex;justify-content:center;gap:14px;margin-top:16px}
.pact{width:46px;height:46px;border-radius:50%;display:grid;place-items:center;font-size:20px;background:var(--card);border:1px solid var(--line)}
.pact.like{background:var(--grad);border:none}

/* FEATURES */
section{padding:84px 0}
.sec-head{text-align:center;margin-bottom:52px}
.sec-head .tag{color:var(--pink2);font-weight:700;font-size:14px;letter-spacing:1px;text-transform:uppercase}
.sec-head h2{font-size:clamp(28px,4vw,42px);font-weight:800;margin-top:10px;letter-spacing:-.5px}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:22px}
.feat{background:var(--card);border:1px solid var(--line);border-radius:20px;padding:30px;transition:transform .2s,border-color .2s}
.feat:hover{transform:translateY(-4px);border-color:rgba(255,57,117,.4)}
.feat .ic{width:52px;height:52px;border-radius:14px;background:rgba(255,57,117,.14);display:grid;place-items:center;font-size:24px;margin-bottom:18px}
.feat h3{font-size:19px;font-weight:700;margin-bottom:8px}
.feat p{color:var(--muted);font-size:15px}

/* DOWNLOAD */
.dl{background:linear-gradient(160deg,#1a1226,#0e0e13);border-top:1px solid var(--line);border-bottom:1px solid var(--line);text-align:center}
.dl-box{max-width:640px;margin:0 auto}
.dl h2{font-size:clamp(28px,4vw,40px);font-weight:800;margin-bottom:14px}
.dl p{color:var(--muted);margin-bottom:30px;font-size:17px}
.dl .btn{font-size:17px;padding:15px 34px}
.dl .meta{margin-top:16px;font-size:13px;color:var(--muted)}

/* FOOTER */
footer{padding:56px 0 34px;background:#0b0b10}
.f-grid{display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:32px;margin-bottom:40px}
.f-brand p{color:var(--muted);font-size:14px;margin-top:12px;max-width:280px}
.f-col h4{font-size:14px;font-weight:700;margin-bottom:14px;letter-spacing:.5px}
.f-col a{display:block;color:var(--muted);font-size:14px;padding:5px 0;transition:color .2s}
.f-col a:hover{color:var(--text)}
.f-bottom{border-top:1px solid var(--line);padding-top:24px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;color:var(--muted);font-size:13px}
.f-social{display:flex;gap:14px}
.f-social a{width:36px;height:36px;border-radius:10px;background:var(--card);border:1px solid var(--line);display:grid;place-items:center;font-size:15px;transition:border-color .2s}
.f-social a:hover{border-color:var(--pink)}

@media(max-width:820px){
  .nav-links{position:fixed;top:68px;right:0;left:0;background:var(--bg2);flex-direction:column;padding:20px;gap:18px;border-bottom:1px solid var(--line);transform:translateY(-140%);transition:transform .25s}
  .nav-links.open{transform:translateY(0)}
  .nav-toggle{display:block}
  .grid3{grid-template-columns:1fr}
  .f-grid{grid-template-columns:1fr 1fr}
}
</style>
</head>
<body>

<nav>
  <div class="wrap nav-in">
    <a href="{{ url('/') }}" class="brand"><span class="dot"></span>KETUA</a>
    <button class="nav-toggle" onclick="document.getElementById('navlinks').classList.toggle('open')">☰</button>
    <div class="nav-links" id="navlinks">
      <a href="#features">Features</a>
      <a href="{{ route('privacypolicy') }}">Privacy</a>
      <a href="{{ route('termsOfUse') }}">Terms</a>
      <a href="{{ route('csae') }}">Safety</a>
      <a href="{{ $downloadUrl }}" class="btn btn-primary" style="padding:9px 18px">Get the App</a>
    </div>
  </div>
</nav>

<header class="hero">
  <div class="wrap">
    <span class="hero-badge">🔥 Now live — meet people nearby</span>
    <h1>Meet. Vibe.<br><span class="grad">Connect.</span></h1>
    <p>KETUA is where real connections begin. Discover people around you, go live, chat, and build your community — all in one place.</p>
    <div class="hero-cta">
      <a href="{{ $downloadUrl }}" class="btn btn-primary">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        Download for Android
      </a>
      <a href="#features" class="btn btn-ghost">Explore features</a>
    </div>

    <div class="hero-stats">
      <div><div class="num">18+</div><div class="lbl">Community</div></div>
      <div><div class="num">Live</div><div class="lbl">Streaming</div></div>
      <div><div class="num">100%</div><div class="lbl">Private &amp; secure</div></div>
    </div>

    <div class="phone">
      <div class="notch"></div>
      <div class="screen">
        <div class="pcard">
          <div class="pfill"></div>
          <div class="pname">Amani, 27<small>~3 km away · Kampala</small></div>
        </div>
        <div class="pactions">
          <div class="pact">↩</div>
          <div class="pact">✕</div>
          <div class="pact like">♥</div>
        </div>
      </div>
    </div>
  </div>
</header>

<section id="features">
  <div class="wrap">
    <div class="sec-head">
      <div class="tag">Why KETUA</div>
      <h2>Everything you need to connect</h2>
    </div>
    <div class="grid3">
      <div class="feat">
        <div class="ic">💫</div>
        <h3>Smart discovery</h3>
        <p>Swipe through profiles matched to your interests, preferences and how close you are.</p>
      </div>
      <div class="feat">
        <div class="ic">🎥</div>
        <h3>Go live</h3>
        <p>Broadcast to your community, join live rooms, and interact in real time.</p>
      </div>
      <div class="feat">
        <div class="ic">💬</div>
        <h3>Real-time chat</h3>
        <p>Message your matches instantly with fast, secure conversations.</p>
      </div>
      <div class="feat">
        <div class="ic">🎁</div>
        <h3>Gifts &amp; rewards</h3>
        <p>Send gifts, climb the leaderboards, and earn as a creator.</p>
      </div>
      <div class="feat">
        <div class="ic">📍</div>
        <h3>Nearby map</h3>
        <p>See who's around you on an interactive map and filter by distance.</p>
      </div>
      <div class="feat">
        <div class="ic">🔒</div>
        <h3>Safe by design</h3>
        <p>Blocking, reporting and moderation keep the community respectful.</p>
      </div>
    </div>
  </div>
</section>

<section class="dl">
  <div class="wrap dl-box">
    <h2>Get KETUA on your phone</h2>
    <p>Download the app and start meeting people near you today. Free to install.</p>
    <a href="{{ $downloadUrl }}" class="btn btn-primary">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
      Download APK
    </a>
    <div class="meta">Android 7.0+ · ~80 MB · Direct install</div>
  </div>
</section>

<footer>
  <div class="wrap">
    <div class="f-grid">
      <div class="f-brand">
        <a href="{{ url('/') }}" class="brand"><span class="dot"></span>KETUA</a>
        <p>Meet. Vibe. Connect. The community app for real connections.</p>
      </div>
      <div class="f-col">
        <h4>App</h4>
        <a href="{{ $downloadUrl }}">Download APK</a>
        <a href="#features">Features</a>
      </div>
      <div class="f-col">
        <h4>Legal</h4>
        <a href="{{ route('privacypolicy') }}">Privacy Policy</a>
        <a href="{{ route('termsOfUse') }}">Terms of Use</a>
        <a href="{{ route('csae') }}">Child Safety</a>
      </div>
      <div class="f-col">
        <h4>Your data</h4>
        <a href="{{ route('dataDeletion.create') }}">Request deletion</a>
        <a href="mailto:support@ketua.sanaa.co">Contact support</a>
        <a href="{{ url('/admin/login') }}">Admin login</a>
      </div>
    </div>
    <div class="f-bottom">
      <div>© {{ date('Y') }} KETUA. All rights reserved.</div>
      <div class="f-social">
        <a href="#" aria-label="Instagram">ig</a>
        <a href="#" aria-label="X">x</a>
        <a href="#" aria-label="TikTok">tt</a>
      </div>
    </div>
  </div>
</footer>

<script>
document.querySelectorAll('a[href^="#"]').forEach(a=>{
  a.addEventListener('click',e=>{
    const t=document.querySelector(a.getAttribute('href'));
    if(t){e.preventDefault();t.scrollIntoView({behavior:'smooth'});document.getElementById('navlinks').classList.remove('open');}
  });
});
</script>
</body>
</html>
