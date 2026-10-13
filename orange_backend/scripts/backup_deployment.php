<?php
require '/var/www/ketua.sanaa.co/orange_backend/vendor/autoload.php';
$app=require '/var/www/ketua.sanaa.co/orange_backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$c=config('database.connections.mysql');
if ($c['database'] !== 'ketua') throw new RuntimeException('Unexpected database');
$f=tempnam('/var/backups/ketua/codex-20261010','db-options-');
file_put_contents($f,"[client]\nuser=".$c['username']."\npassword=".$c['password']."\nhost=".$c['host']."\n");chmod($f,0600);
$out='/var/backups/ketua/codex-20261010/catalog-profile-before.sql';
try { passthru('mysqldump --defaults-extra-file='.escapeshellarg($f).' --single-transaction --no-tablespaces '.escapeshellarg($c['database']).' > '.escapeshellarg($out), $code); if ($code) throw new RuntimeException('Backup failed'); chmod($out,0600); echo "Database rollback backup saved.\n"; }
finally { unlink($f); }
