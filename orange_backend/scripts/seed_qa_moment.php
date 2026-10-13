<?php
// Owner-authorized, explicitly synthetic playback fixture. No financial grants.
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';
$app = require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if (config('database.connections.mysql.database') !== 'ketua') throw new RuntimeException('Unexpected database');
$manifest = json_decode(file_get_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json'), true);
$user = App\Models\Users::findOrFail($manifest['qa_user_ids'][0]);
if (!str_starts_with($user->identity, 'ketua-device-qa-')) throw new RuntimeException('Expected synthetic user');
if (!Illuminate\Support\Facades\Storage::disk('public')->exists('ketua-qa/moment.mp4')) throw new RuntimeException('Missing QA media');
$video = App\Models\ShortVideo::firstOrCreate(['user_id'=>$user->id,'video'=>'ketua-qa/moment.mp4'], [
 'caption'=>'KETUA QA • Synthetic playback test. No real person.',
 'thumbnail'=>'ketua-qa/amani.jpg', 'duration_sec'=>5,
]);
$manifest['qa_moment_id'] = $video->id;
file_put_contents('/var/backups/ketua/codex-20261010/device-qa-manifest.json', json_encode($manifest, JSON_PRETTY_PRINT));
echo "Synthetic QA moment is ready.\n";
