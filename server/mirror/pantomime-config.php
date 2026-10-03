<?php
/**
 * Pantomime config mirror for an Iranian host (PHP 7.0+, no database).
 *
 * Upload this single file to your host, e.g. https://example.ir/pantomime-config.php
 * Nothing to configure. No keys or passwords.
 *
 * Every request serves the cached config. When the cached copy is older than
 * 5 minutes, it is refreshed from the Cloudflare Worker (4 s timeout). If the
 * Worker is unreachable (filtering, international outage) the last good copy
 * keeps being served, and if there is none yet, the bundled default.
 * A downloaded config is accepted only if it looks valid and its
 * config_version is not lower than the cached one.
 */

const SOURCE_URL = 'https://pantomime-config.sepanta-hesaban.workers.dev/config.json';
const TTL_SECONDS = 300;
const FETCH_TIMEOUT = 4;
const DEFAULT_CONFIG = '{"config_version":0,"ads":{"enabled":true,"active_provider":{"play":"adivery","bazaar":"adivery","myket":"adivery","ios":"admob"},"ab_split":null,"fallback_chain":{"play":["adivery","tapsell","admob"],"bazaar":["adivery","tapsell"],"myket":["adivery","tapsell"],"ios":["admob"]},"providers":{},"interstitial_every_n_rounds":3,"banner_on_home":true,"rewarded_enabled":true},"min_supported_version":"1.0.0","message":null}';

function cache_file()
{
    $dir = is_writable(__DIR__) ? __DIR__ : sys_get_temp_dir();
    return $dir . DIRECTORY_SEPARATOR . 'pantomime-config-cache.json';
}

function decode_config($raw)
{
    if (!is_string($raw) || $raw === '' || strlen($raw) > 65536) {
        return null;
    }
    $data = json_decode($raw, true);
    if (!is_array($data) || !isset($data['config_version']) || !is_int($data['config_version'])) {
        return null;
    }
    if (!isset($data['ads']) || !is_array($data['ads']) || !isset($data['ads']['enabled'])) {
        return null;
    }
    return $data;
}

function fetch_source()
{
    if (function_exists('curl_init')) {
        $ch = curl_init(SOURCE_URL);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => FETCH_TIMEOUT,
            CURLOPT_TIMEOUT => FETCH_TIMEOUT,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_USERAGENT => 'pantomime-mirror/1',
        ));
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        return ($body !== false && $code === 200) ? $body : null;
    }
    $ctx = stream_context_create(array('http' => array(
        'timeout' => FETCH_TIMEOUT,
        'header' => "User-Agent: pantomime-mirror/1\r\n",
    )));
    $body = @file_get_contents(SOURCE_URL, false, $ctx);
    return $body === false ? null : $body;
}

function refresh_if_stale($file)
{
    if (is_file($file) && time() - filemtime($file) < TTL_SECONDS) {
        return;
    }
    $cached = is_file($file) ? decode_config(@file_get_contents($file)) : null;
    // Mark the attempt first so concurrent/failed requests don't all wait.
    if (is_file($file)) {
        @touch($file);
    }
    $raw = fetch_source();
    $fresh = decode_config($raw);
    if ($fresh === null) {
        return;
    }
    if ($cached !== null && $fresh['config_version'] < $cached['config_version']) {
        return; // never go back to an older config
    }
    $tmp = $file . '.' . getmypid() . '.tmp';
    if (@file_put_contents($tmp, $raw) !== false) {
        @rename($tmp, $file);
    }
}

$method = isset($_SERVER['REQUEST_METHOD']) ? $_SERVER['REQUEST_METHOD'] : 'GET';
if ($method !== 'GET' && $method !== 'HEAD') {
    http_response_code(405);
    header('Allow: GET, HEAD');
    exit;
}

$file = cache_file();
refresh_if_stale($file);
$body = is_file($file) ? @file_get_contents($file) : false;
if (decode_config($body) === null) {
    $body = DEFAULT_CONFIG;
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: public, max-age=300');
header('Access-Control-Allow-Origin: *');
header('X-Content-Type-Options: nosniff');
if ($method === 'GET') {
    echo $body;
}
