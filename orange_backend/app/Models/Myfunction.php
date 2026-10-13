<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;
use Google\Client;
use Illuminate\Support\Facades\File;

class Myfunction extends Model
{
    use HasFactory;

    public static function sendPushToUser($title, $message, $token)
    {

        try {
        $credentialsFile = config('ketua.firebase_credentials_file');
        $credentialsPath = str_starts_with($credentialsFile, '/') ? $credentialsFile : base_path($credentialsFile);
        if (!file_exists($credentialsPath)) {
            Log::error('Firebase credentials file not found: ' . $credentialsPath);
            return false;
        }

        $client = new Client();
        $client->setAuthConfig($credentialsPath);
        $client->addScope('https://www.googleapis.com/auth/firebase.messaging');
        $client->fetchAccessTokenWithAssertion();
        $accessToken = $client->getAccessToken();
        $accessToken = $accessToken['access_token'];

        $contents = File::get($credentialsPath);
        $json = json_decode(json: $contents, associative: true);

        // Log::info($accessToken);

        $url = 'https://fcm.googleapis.com/v1/projects/'.$json['project_id'].'/messages:send';
        $notificationArray = array('title' => $title, 'body' => $message);

        $device_token = $token;

        $fields = array(
            'message'=> [
                'token'=> $device_token,
                'notification' => $notificationArray,       
            ]
        );

        $headers = array(
            'Content-Type:application/json',
            'Authorization:Bearer ' . $accessToken
        );
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
        // print_r(json_encode($fields));
        $result = curl_exec($ch);
        $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        // Log::debug($result);

        if ($result === FALSE) {
            Log::warning('Firebase push transport failed.');
        }
        curl_close($ch);
        if ($status !== 200) Log::warning('Firebase push rejected.', ['http_status'=>$status]);
        return $result !== false && $status === 200;

        // Push failures must not abort the primary user action.
        } catch (\Throwable $e) {
            Log::warning('Firebase push unavailable.');
            return false;
        }
    }

    public static function point2point_distance($lat1, $lon1, $lat2, $lon2, $unit = 'K', $radius = 100)
    {
        $theta = $lon1 - $lon2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        // Rounding at identical coordinates can produce 1.0000000000000002.
        // Clamp the cosine before acos so nearby profiles are not discarded.
        $dist = acos(max(-1.0, min(1.0, $dist)));
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

    public static function customReplace($string)
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }

    public static function generateFakeUserIdentity()
    {
        $token = random_int(100000, 999999);
        $first = MyFunction::generateRandomString(3);
        $first .= $token;
        $first .= MyFunction::generateRandomString(3);

        $count = Users::where('identity', $first)->count();
        while ($count >= 1) {
            $token = random_int(100000, 999999);
            $first = MyFunction::generateRandomString(3);
            $first .= $token;
            $first .= MyFunction::generateRandomString(3);
            $count = Users::where('identity', $first)->count();
        }
        return $first;
    }

    public static function generateRandomString($length)
    {
        $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $charactersLength = strlen($characters);
        $randomString = '';
        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[random_int(0, $charactersLength - 1)];
        }
        return $randomString;
    }
}
