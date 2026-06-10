# Laravel Video Streaming Configuration Guide

## Problem
The video player is getting a `MediaCodecVideoRenderer error` which indicates either:
1. The video codec is not supported by the device
2. The HTTP headers from Laravel are not properly configured for video streaming
3. Range requests (byte serving) are not enabled

## Solution
Configure Laravel to properly stream video files with correct headers and range request support.

---

## Step 1: Update Video Route Controller

Create or update your video controller to properly stream videos:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class VideoController extends Controller
{
    /**
     * Stream video with proper headers and range support
     */
    public function stream(Request $request, $filename)
    {
        // Get the video file path
        $path = storage_path('app/public/videos/' . $filename);
        
        // Check if file exists
        if (!file_exists($path)) {
            return response()->json([
                'success' => false,
                'message' => 'Video not found'
            ], 404);
        }

        // Get file information
        $fileSize = filesize($path);
        $mimeType = mime_content_type($path);
        
        // Set default mime type if detection fails
        if (!$mimeType) {
            $mimeType = 'video/mp4';
        }

        // Get the range header
        $range = $request->header('Range');
        
        if ($range) {
            // Parse range header
            list(, $range) = explode('=', $range, 2);
            list($start, $end) = explode('-', $range);
            
            $start = intval($start);
            $end = $end ? intval($end) : ($fileSize - 1);
            $length = $end - $start + 1;
            
            // Create streaming response with range support
            $response = new StreamedResponse(function() use ($path, $start, $length) {
                $stream = fopen($path, 'rb');
                fseek($stream, $start);
                
                $buffer = 1024 * 8; // 8KB chunks
                while (!feof($stream) && $length > 0) {
                    $read = ($length > $buffer) ? $buffer : $length;
                    echo fread($stream, $read);
                    flush();
                    $length -= $read;
                }
                
                fclose($stream);
            }, 206); // 206 Partial Content
            
            $response->headers->set('Content-Type', $mimeType);
            $response->headers->set('Content-Length', $length);
            $response->headers->set('Content-Range', "bytes {$start}-{$end}/{$fileSize}");
            $response->headers->set('Accept-Ranges', 'bytes');
            $response->headers->set('Cache-Control', 'public, max-age=31536000');
            $response->headers->set('Access-Control-Allow-Origin', '*');
            
        } else {
            // No range header - send entire file
            $response = new StreamedResponse(function() use ($path) {
                $stream = fopen($path, 'rb');
                fpassthru($stream);
                fclose($stream);
            }, 200);
            
            $response->headers->set('Content-Type', $mimeType);
            $response->headers->set('Content-Length', $fileSize);
            $response->headers->set('Accept-Ranges', 'bytes');
            $response->headers->set('Cache-Control', 'public, max-age=31536000');
            $response->headers->set('Access-Control-Allow-Origin', '*');
        }
        
        return $response;
    }
}
```

---

## Step 2: Add Route

Add this route to `routes/api.php`:

```php
// Video streaming route
Route::get('/videos/{filename}', [VideoController::class, 'stream'])
    ->name('api.videos.stream');
```

---

## Step 3: Update Course Model

Update your Course model to return the proper streaming URL:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    /**
     * Get the video URL for streaming
     */
    public function getVideoUrlAttribute($value)
    {
        // If it's already a full URL, fix localhost
        if (str_starts_with($value, 'http://') || str_starts_with($value, 'https://')) {
            $appUrl = config('app.url');
            $appHost = parse_url($appUrl, PHP_URL_HOST);
            
            $value = str_replace('localhost', $appHost, $value);
            $value = str_replace('127.0.0.1', $appHost, $value);
            
            return $value;
        }
        
        // If it's a storage path, convert to streaming URL
        if (str_starts_with($value, 'storage/')) {
            $filename = basename($value);
            return config('app.url') . '/api/videos/' . $filename;
        }
        
        return $value;
    }
}
```

---

## Step 4: Configure CORS (if needed)

If you have CORS issues, update `config/cors.php`:

```php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    
    'allowed_methods' => ['*'],
    
    'allowed_origins' => ['*'],
    
    'allowed_origins_patterns' => [],
    
    'allowed_headers' => ['*'],
    
    'exposed_headers' => ['Content-Range', 'Accept-Ranges', 'Content-Length'],
    
    'max_age' => 0,
    
    'supports_credentials' => false,
];
```

---

## Step 5: Alternative - Use Laravel's BinaryFileResponse

If you prefer a simpler approach without custom streaming:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class VideoController extends Controller
{
    public function stream($filename)
    {
        $path = storage_path('app/public/videos/' . $filename);
        
        if (!file_exists($path)) {
            return response()->json(['error' => 'Video not found'], 404);
        }
        
        return response()->file($path, [
            'Content-Type' => 'video/mp4',
            'Accept-Ranges' => 'bytes',
            'Content-Disposition' => 'inline; filename="' . $filename . '"',
            'Access-Control-Allow-Origin' => '*',
        ]);
    }
}
```

---

## Step 6: Ensure Proper Video Encoding

For maximum compatibility with older Android devices, ensure videos are encoded with:

```bash
# Convert video to compatible format using ffmpeg
ffmpeg -i input.mp4 \
  -c:v libx264 \
  -profile:v baseline \
  -level 3.0 \
  -pix_fmt yuv420p \
  -c:a aac \
  -b:a 128k \
  -movflags +faststart \
  output.mp4
```

**Key flags explained:**
- `-profile:v baseline`: Most compatible H.264 profile for older devices
- `-level 3.0`: Compatible with most hardware decoders
- `-pix_fmt yuv420p`: Standard pixel format
- `-c:a aac`: AAC audio codec (widely supported)
- `-movflags +faststart`: Enables progressive download (moov atom at start)

---

## Step 7: Update .htaccess (if using Apache)

Add to `public/.htaccess`:

```apache
# Enable video streaming
<FilesMatch "\.(mp4|webm|ogg|avi|mov)$">
    Header set Accept-Ranges "bytes"
    Header set Cache-Control "public, max-age=31536000"
</FilesMatch>

# Enable CORS for video files
<IfModule mod_headers.c>
    Header add Access-Control-Allow-Origin "*"
    Header add Access-Control-Allow-Headers "range"
    Header add Access-Control-Expose-Headers "accept-ranges, content-length, content-range"
</IfModule>
```

---

## Step 8: Test Video Streaming

Test your video endpoint with curl:

```bash
# Test basic request
curl -I http://192.168.100.99:8000/api/videos/your-video.mp4

# Expected response should include:
# HTTP/1.1 200 OK
# Content-Type: video/mp4
# Accept-Ranges: bytes
# Content-Length: 12345678

# Test range request
curl -I -H "Range: bytes=0-1023" http://192.168.100.99:8000/api/videos/your-video.mp4

# Expected response should include:
# HTTP/1.1 206 Partial Content
# Content-Range: bytes 0-1023/12345678
# Accept-Ranges: bytes
```

---

## Step 9: Update Course Database URLs

Update existing course video URLs to use the streaming endpoint:

```sql
-- If your videos are in storage/videos/
UPDATE courses 
SET video_url = CONCAT('http://192.168.100.99:8000/api/videos/', 
                       SUBSTRING_INDEX(video_url, '/', -1))
WHERE video_url LIKE '%storage/videos/%';

-- Or if they're localhost URLs
UPDATE courses 
SET video_url = REPLACE(video_url, 'http://localhost:8000', 'http://192.168.100.99:8000');
```

---

## Troubleshooting

### Issue: "MediaCodecVideoRenderer error"
**Cause**: Video codec not supported or improper headers
**Fix**: 
1. Re-encode video with baseline H.264 profile
2. Ensure Accept-Ranges header is sent
3. Test with curl to verify headers

### Issue: Video loads but doesn't play
**Cause**: Missing range request support
**Fix**: Implement Step 1 (full streaming controller)

### Issue: Video plays on browser but not in app
**Cause**: CORS headers missing
**Fix**: Add CORS configuration (Step 4)

### Issue: Video buffers constantly
**Cause**: Not optimized for progressive download
**Fix**: Re-encode with `-movflags +faststart`

### Issue: "Video format not supported"
**Cause**: Incompatible codec
**Fix**: Use baseline H.264 + AAC (Step 6)

---

## Quick Test

Create a test route to verify your setup:

```php
Route::get('/test-video', function() {
    $path = storage_path('app/public/videos/test.mp4');
    
    if (!file_exists($path)) {
        return response()->json(['error' => 'File not found']);
    }
    
    return response()->file($path, [
        'Content-Type' => 'video/mp4',
        'Accept-Ranges' => 'bytes',
    ]);
});
```

Test in browser: `http://192.168.100.99:8000/api/test-video`

---

## Summary Checklist

- [ ] Video streaming controller created with range support
- [ ] Route added to api.php
- [ ] Course model returns correct streaming URL
- [ ] CORS configured properly
- [ ] Videos encoded with baseline H.264 profile
- [ ] .htaccess updated (if using Apache)
- [ ] Tested with curl - headers correct
- [ ] Database URLs updated
- [ ] Tested on device - video plays smoothly

---

## Alternative: If All Else Fails

If native video streaming continues to cause issues, the Flutter app now has a **WebView fallback** that will automatically activate when hardware codec errors are detected. The WebView player uses the device's built-in Chromium engine to handle video playback, which is more compatible with problematic formats.

The fallback happens automatically - no additional configuration needed!
