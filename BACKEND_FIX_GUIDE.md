# Backend Fix Guide: Fixing Localhost URLs in Laravel API

## Problem
The Laravel backend is returning `localhost:8000` URLs in course video_url fields, which causes connection errors on mobile devices.

## Solution
Update the Laravel backend to use dynamic URLs based on the server's actual IP address or the `APP_URL` environment variable.

---

## Step 1: Update `.env` File

Open your Laravel project's `.env` file and set:

```env
APP_URL=http://192.168.100.99:8000
```

Replace `192.168.100.99` with your actual server IP address.

---

## Step 2: Fix Course Model or Controller

### Option A: Fix in the Model (Recommended)

Edit `app/Models/Course.php` and add an accessor:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    protected $fillable = ['title', 'description', 'video_url', 'professor_id', /* other fields */];

    /**
     * Get the video URL with proper domain
     */
    public function getVideoUrlAttribute($value)
    {
        // If the URL is already absolute (starts with http:// or https://), return it
        if (str_starts_with($value, 'http://') || str_starts_with($value, 'https://')) {
            // Replace localhost with APP_URL host
            $appUrl = config('app.url');
            $appHost = parse_url($appUrl, PHP_URL_HOST);
            $appPort = parse_url($appUrl, PHP_URL_PORT);
            
            $value = str_replace('localhost', $appHost, $value);
            $value = str_replace('127.0.0.1', $appHost, $value);
            
            // Handle port if needed
            if ($appPort && $appPort != 80 && $appPort != 443) {
                $value = str_replace(':8000', ":$appPort", $value);
            }
        }
        
        return $value;
    }
}
```

### Option B: Fix in the Controller

Edit your course controller (e.g., `app/Http/Controllers/Api/CourseController.php`):

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\Request;

class CourseController extends Controller
{
    public function index(Request $request)
    {
        $student = $request->user(); // Assuming you're using Sanctum auth
        
        $courses = Course::where('class_id', $student->class_id)
            ->with('professor')
            ->orderBy('created_at', 'desc')
            ->get();

        // Fix localhost URLs
        $courses->transform(function ($course) {
            $course->video_url = $this->fixUrl($course->video_url);
            return $course;
        });

        return response()->json([
            'success' => true,
            'data' => $courses,
        ]);
    }

    /**
     * Replace localhost with the actual APP_URL host
     */
    private function fixUrl($url)
    {
        if (empty($url)) {
            return $url;
        }

        $appUrl = config('app.url');
        $appHost = parse_url($appUrl, PHP_URL_HOST);
        $appScheme = parse_url($appUrl, PHP_URL_SCHEME);
        $appPort = parse_url($appUrl, PHP_URL_PORT);

        // Replace localhost and 127.0.0.1 with actual host
        $url = str_replace('localhost', $appHost, $url);
        $url = str_replace('127.0.0.1', $appHost, $url);

        // Ensure proper scheme
        if (!str_starts_with($url, 'http://') && !str_starts_with($url, 'https://')) {
            $url = $appScheme . '://' . $appHost . ($appPort ? ":$appPort" : '') . '/' . ltrim($url, '/');
        }

        return $url;
    }
}
```

---

## Step 3: Fix Storage URLs (for Images)

If you're using Laravel's storage for images, update `config/filesystems.php`:

```php
'public' => [
    'driver' => 'local',
    'root' => storage_path('app/public'),
    'url' => env('APP_URL').'/storage',
    'visibility' => 'public',
],
```

Then in your models or controllers, use:

```php
// Instead of:
$imageUrl = Storage::url('images/course.jpg');

// Use:
$imageUrl = config('app.url') . Storage::url('images/course.jpg');
```

---

## Step 4: Create a Helper Function (Optional but Recommended)

Create `app/Helpers/UrlHelper.php`:

```php
<?php

namespace App\Helpers;

class UrlHelper
{
    /**
     * Convert localhost URLs to use APP_URL
     */
    public static function fixLocalhost($url)
    {
        if (empty($url)) {
            return $url;
        }

        $appUrl = config('app.url');
        $parsedAppUrl = parse_url($appUrl);
        
        $host = $parsedAppUrl['host'] ?? 'localhost';
        $port = $parsedAppUrl['port'] ?? null;
        
        // Replace localhost variants
        $url = preg_replace('/https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/', 
            $appUrl, 
            $url
        );
        
        return $url;
    }
}
```

Register it in `composer.json`:

```json
"autoload": {
    "psr-4": {
        "App\\": "app/"
    },
    "files": [
        "app/Helpers/UrlHelper.php"
    ]
},
```

Then run: `composer dump-autoload`

Usage:
```php
use App\Helpers\UrlHelper;

$course->video_url = UrlHelper::fixLocalhost($course->video_url);
```

---

## Step 5: Test the API

Test your API endpoint:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://192.168.100.99:8000/api/courses
```

Verify the response contains:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "React",
      "video_url": "http://192.168.100.99:8000/storage/videos/react.mp4"
    }
  ]
}
```

---

## Important Notes

1. **Never hardcode localhost** - Always use `config('app.url')` or environment variables
2. **Update APP_URL** when deploying to different environments (development, staging, production)
3. **Restart your Laravel server** after changing `.env` file
4. **Clear config cache** if needed: `php artisan config:clear`

---

## Quick Fix Command

If you just want a quick fix for existing database entries:

```sql
UPDATE courses 
SET video_url = REPLACE(video_url, 'localhost', '192.168.100.99')
WHERE video_url LIKE '%localhost%';

UPDATE courses 
SET video_url = REPLACE(video_url, '127.0.0.1', '192.168.100.99')
WHERE video_url LIKE '%127.0.0.1%';
```

**Note:** This is a temporary fix. Implement the Model accessor or Controller fix for a permanent solution.
