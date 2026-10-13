<?php

return [
    'revenuecat_webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
    'firebase_credentials_file' => env('FIREBASE_CREDENTIALS_FILE', 'googleCredentials.json'),
    'live_enabled' => env('KETUA_LIVE_ENABLED', false),
    'agora_app_id' => env('AGORA_APP_ID'),
    'agora_app_certificate' => env('AGORA_APP_CERT'),
    'firebase_project_id' => env('FIREBASE_PROJECT_ID', 'ketua-750dc'),
    'notification_topic' => env('NOTIFICATION_TOPIC', 'ketua'),
    /*
    |--------------------------------------------------------------------------
    | KETUA application flags
    |--------------------------------------------------------------------------
    |
    | Feature/security toggles read via config('ketua.*'). Defaults are safe
    | for production; override via env in .env when needed.
    |
    */

    // K12: the /api/fakeUserLogin backdoor login. MUST stay false in production.
    'allow_fake_login' => env('KETUA_ALLOW_FAKE_LOGIN', false),

    // Auth: require a server-verified identity provider token on register.
    // The unverified escape hatch is for the ISOLATED TEST SUITE ONLY and must
    // stay false in production.
    'allow_unverified_register' => env('KETUA_ALLOW_UNVERIFIED_REGISTER', false),

    // Identity verification is a separate, admin-approved flow. Payment or
    // login must NEVER auto-grant the verified badge (mission rule).
    'verification_requires_admin_approval' => env('KETUA_VERIFY_ADMIN_APPROVAL', true),

    // Shared app gate key for checkHeader. Read via config() (NOT env()) so it
    // works when the config is cached (env() returns null after config:cache).
    'api_key' => env('API_KEY'),
];
