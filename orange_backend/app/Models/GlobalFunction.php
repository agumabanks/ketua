<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Google\Client;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

class GlobalFunction extends Model
{
    use HasFactory;

    public static function sendSimpleResponse($status, $msg)
    {
        return response()->json(['status' => $status, 'message' => $msg]);
    }
    
    public static function sendDataResponse($status, $msg, $data)
    {
        return response()->json(['status' => $status, 'message' => $msg, 'data' => $data]);
    }

    public static function sendPushNotificationToAllUsers($title, $message)
    {
        try {
            $file = config('ketua.firebase_credentials_file');
            $path = str_starts_with($file, '/') ? $file : base_path($file);
            if (!is_file($path)) return json_encode(['status'=>false,'message'=>'Firebase not configured']);
            $client = new Client();
            $client->setAuthConfig($path);
            $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
            $auth = $client->fetchAccessTokenWithAssertion();
            if (empty($auth['access_token'])) throw new \RuntimeException('Push authentication unavailable');
            $project = json_decode(File::get($path), true)['project_id'];
            $sent = true;
            foreach (['ios','android'] as $platform) {
                $notification = ['title'=>(string)$title,'body'=>(string)$message];
                $payload = ['message'=>['topic'=>config('ketua.notification_topic', 'ketua').'_'.$platform,
                    'notification'=>$notification,'data'=>$notification]];
                $curl = curl_init('https://fcm.googleapis.com/v1/projects/'.$project.'/messages:send');
                curl_setopt_array($curl, [CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,
                    CURLOPT_CONNECTTIMEOUT=>5,CURLOPT_TIMEOUT=>10,
                    CURLOPT_HTTPHEADER=>['Content-Type: application/json','Authorization: Bearer '.$auth['access_token']],
                    CURLOPT_POSTFIELDS=>json_encode($payload)]);
                $response = curl_exec($curl);
                $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
                curl_close($curl);
                $sent = $sent && $response !== false && $status === 200;
            }
            return json_encode(['status'=>$sent,'message'=>$sent ? 'Notification sent successfully' : 'Push delivery was not accepted for every platform.']);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Broadcast push unavailable.');
            return json_encode(['status'=>false,'message'=>'Push delivery unavailable.']);
        }
    }

    public static function createMediaUrl($media)
    {
        $url = url('public/storage/' . $media);
        return $url;
    }

    public static function uploadFilToS3($request, $key)
    {
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'webm'];
        $maxFileSize = 50 * 1024 * 1024; // 50MB

        $file = $request->file($key);
        $extension = strtolower($file->getClientOriginalExtension());
        $fileSize = $file->getSize();

        if (!in_array($extension, $allowedExtensions)) {
            throw new \InvalidArgumentException('File type not allowed. Allowed: ' . implode(', ', $allowedExtensions));
        }
        if ($fileSize > $maxFileSize) {
            throw new \InvalidArgumentException('File size exceeds 50MB limit');
        }
        if (!$file->isValid()) {
            throw new \RuntimeException('File upload failed');
        }

        $s3 = Storage::disk('s3');
        $fileName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
        $filePath = 'uploads/' . $fileName;
        $result = $s3->put($filePath, file_get_contents($file), 'private');
        return $filePath;
    }

    public static function point2point_distance($lat1, $lon1, $lat2, $lon2, $unit = 'K', $radius)
    {
        $theta = $lon1 - $lon2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        $dist = acos($dist);
        $dist = rad2deg($dist);
        $miles = $dist * 60 * 1.1515;
        $unit = strtoupper($unit);

        if ($unit == "K") {
            return (($miles * 1.609344) <= $radius);
        } else if ($unit == "N") {
            return ($miles * 0.8684);
        } else {
            return $miles;
        }
    }

    public static function cleanString($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }

    public static function deleteFile($filename, string $disk = 'public')
    {
        if (!is_string($filename) || $filename === '' || !in_array($disk, ['public','local'], true)
            || str_contains($filename, '..') || str_contains($filename, '\\') || str_starts_with($filename, '/')) return;
        if (!preg_match('~^(?:uploads/|verification/|ketua-qa/)?[A-Za-z0-9_.-]+$~', $filename)) return;
        $root = realpath(Storage::disk($disk)->path(''));
        $path = realpath(Storage::disk($disk)->path($filename));
        if ($root && $path && str_starts_with($path, $root . DIRECTORY_SEPARATOR) && is_file($path)) unlink($path);
    }

    /**
     * K07: validate uploads before storing. Whitelist extensions, enforce a
     * size cap, verify the file uploaded cleanly, and store under a random
     * server-generated name (never the client filename) to prevent arbitrary
     * file upload / path traversal / executable upload.
     *
     * Throws \InvalidArgumentException on rejection so callers can 422.
     */
    public static function saveFileAndGivePath($file, array $allowedExtensions = null, int $maxFileSize = null, string $disk = 'public', string $directory = 'uploads')
    {
        if ($file == null) {
            return null;
        }

        $allowedExtensions = $allowedExtensions ?? ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'webm'];
        $maxFileSize = $maxFileSize ?? (50 * 1024 * 1024); // 50MB

        if (!$file->isValid()) {
            throw new \RuntimeException('File upload failed.');
        }

        $extension = strtolower($file->getClientOriginalExtension());
        if (!in_array($extension, $allowedExtensions, true)) {
            throw new \InvalidArgumentException('File type not allowed. Allowed: ' . implode(', ', $allowedExtensions));
        }

        if ($file->getSize() > $maxFileSize) {
            throw new \InvalidArgumentException('File size exceeds the ' . (int)($maxFileSize / 1024 / 1024) . 'MB limit.');
        }

        $mimeMap = [
            'jpg'=>['image/jpeg'], 'jpeg'=>['image/jpeg'], 'png'=>['image/png'],
            'gif'=>['image/gif'], 'webp'=>['image/webp'], 'mp4'=>['video/mp4'],
            'mov'=>['video/quicktime'], 'webm'=>['video/webm'],
        ];
        if (!in_array($file->getMimeType(), $mimeMap[$extension] ?? [], true)) {
            throw new \InvalidArgumentException('The uploaded content does not match its media type.');
        }
        if (str_starts_with($file->getMimeType(), 'image/')) {
            $size = @getimagesize($file->getRealPath());
            if (!$size || $size[0] * $size[1] > 25000000) throw new \InvalidArgumentException('Invalid image or image resolution exceeds 25 megapixels.');
        }
        if (!in_array($disk, ['public','local'], true) || !in_array($directory, ['uploads','verification'], true)) {
            throw new \InvalidArgumentException('Invalid media storage destination.');
        }
        if ($directory === 'verification' && $disk !== 'local') throw new \InvalidArgumentException('Verification media must stay private.');

        // Store under a random name with a safe extension only.
        $safeName = time() . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
        return $file->storeAs($directory, $safeName, $disk);
    }
}
