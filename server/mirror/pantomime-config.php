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
 *
 * The same file also mirrors the word list:
 *   pantomime-config.php?file=words_fa.json
 * (same rules: refreshed every 5 minutes, last good copy kept, never older;
 * 404 until the first successful download, then the app keeps its own words).
 */

const SOURCE_URL = 'https://pantomime-config.sepanta-hesaban.workers.dev/config.json';
const TTL_SECONDS = 300;
const FETCH_TIMEOUT = 4;
const DEFAULT_CONFIG = '{"config_version":0,"ads":{"enabled":true,"active_provider":{"play":"adivery","bazaar":"adivery","myket":"adivery","ios":"admob"},"ab_split":null,"fallback_chain":{"play":["adivery","tapsell","admob"],"bazaar":["adivery","tapsell"],"myket":["adivery","tapsell"],"ios":["admob"]},"providers":{},"interstitial_every_n_rounds":3,"banner_on_home":true,"rewarded_enabled":true},"min_supported_version":"1.0.0","message":null}';

function cache_file($name)
{
    $dir = is_writable(__DIR__) ? __DIR__ : sys_get_temp_dir();
    return $dir . DIRECTORY_SEPARATOR . $name;
}

/** What can be mirrored: source URL, cache file, validator, version key. */
function mirrored_files()
{
    return array(
        'config.json' => array(
            'url' => SOURCE_URL,
            'cache' => 'pantomime-config-cache.json',
            'decode' => 'decode_config',
            'version' => 'config_version',
        ),
        'words_fa.json' => array(
            'url' => substr(SOURCE_URL, 0, strrpos(SOURCE_URL, '/') + 1) . 'words_fa.json',
            'cache' => 'pantomime-words-fa-cache.json',
            'decode' => 'decode_words',
            'version' => 'version',
        ),
    );
}

function decode_words($raw)
{
    if (!is_string($raw) || $raw === '' || strlen($raw) > 2097152) {
        return null;
    }
    $data = json_decode($raw, true);
    if (!is_array($data) || !isset($data['version']) || !is_int($data['version']) || $data['version'] < 1) {
        return null;
    }
    if (!isset($data['language']) || $data['language'] !== 'fa') {
        return null;
    }
    if (!isset($data['categories']) || !is_array($data['categories']) || count($data['categories']) < 3) {
        return null;
    }
    return $data;
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

function fetch_source($url)
{
    if (function_exists('curl_init')) {
        $ch = curl_init($url);
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
    $body = @file_get_contents($url, false, $ctx);
    return $body === false ? null : $body;
}

function refresh_if_stale($spec)
{
    $file = cache_file($spec['cache']);
    $decode = $spec['decode'];
    $v = $spec['version'];
    if (is_file($file) && time() - filemtime($file) < TTL_SECONDS) {
        return;
    }
    $cached = is_file($file) ? $decode(@file_get_contents($file)) : null;
    // Mark the attempt first so concurrent/failed requests don't all wait.
    if (is_file($file)) {
        @touch($file);
    }
    $raw = fetch_source($spec['url']);
    $fresh = $decode($raw);
    if ($fresh === null) {
        return;
    }
    if ($cached !== null && $fresh[$v] < $cached[$v]) {
        return; // never go back to an older version
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

$name = isset($_GET['file']) ? (string) $_GET['file'] : 'config.json';
$files = mirrored_files();
if (!isset($files[$name])) {
    http_response_code(404);
    exit;
}
$spec = $files[$name];
refresh_if_stale($spec);
$file = cache_file($spec['cache']);
$body = is_file($file) ? @file_get_contents($file) : false;
$decode = $spec['decode'];
if ($decode($body) === null) {
    if ($name !== 'config.json') {
        http_response_code(404);
        header('Cache-Control: no-store');
        exit;
    }
    $body = DEFAULT_CONFIG;
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: public, max-age=300');
header('Access-Control-Allow-Origin: *');
header('X-Content-Type-Options: nosniff');
if ($method === 'GET') {
    echo $body;
}
