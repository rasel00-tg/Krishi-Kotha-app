param (
    [int]$Port = 8080
)

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Output "Krishi Kotha Web Preview server started at $prefix"
} catch {
    Write-Error "Failed to start listener: $_"
    exit 1
}

$webDir = $PSScriptRoot

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Comprehensive CORS Headers for Seamless Asset & Image Loading
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.AddHeader("Access-Control-Allow-Headers", "*")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.OutputStream.Close()
            continue
        }

        $localPath = $request.Url.LocalPath

        # High-Speed Image Proxy to guarantee 100% remote crop image fetch for PDF
        if ($localPath -eq "/proxy-image") {
            $targetUrl = $request.QueryString["url"]
            if (-not [string]::IsNullOrWhiteSpace($targetUrl)) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                    $imgBytes = $wc.DownloadData($targetUrl)
                    $response.ContentType = "image/jpeg"
                    $response.StatusCode = 200
                    $response.ContentLength64 = $imgBytes.Length
                    $response.OutputStream.Write($imgBytes, 0, $imgBytes.Length)
                    $response.OutputStream.Close()
                    continue
                } catch {
                    $response.StatusCode = 502
                    $response.OutputStream.Close()
                    continue
                }
            }
        }

        if ($localPath -eq "/" -or [string]::IsNullOrWhiteSpace($localPath)) {
            $filePath = Join-Path $webDir "index.html"
        } else {
            $cleaned = $localPath.TrimStart('/')
            $filePath = Join-Path $webDir $cleaned
        }

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            if ($filePath.EndsWith(".html")) {
                $response.ContentType = "text/html; charset=utf-8"
            } elseif ($filePath.EndsWith(".css")) {
                $response.ContentType = "text/css; charset=utf-8"
            } elseif ($filePath.EndsWith(".js")) {
                $response.ContentType = "application/javascript; charset=utf-8"
            } elseif ($filePath.EndsWith(".png")) {
                $response.ContentType = "image/png"
            } elseif ($filePath.EndsWith(".jpg") -or $filePath.EndsWith(".jpeg")) {
                $response.ContentType = "image/jpeg"
            } elseif ($filePath.EndsWith(".svg")) {
                $response.ContentType = "image/svg+xml"
            } elseif ($filePath.EndsWith(".ico")) {
                $response.ContentType = "image/x-icon"
            } else {
                $response.ContentType = "application/octet-stream"
            }

            $response.StatusCode = 200
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFoundBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($notFoundBytes, 0, $notFoundBytes.Length)
        }

        $response.OutputStream.Close()
    } catch {
        # Keep listening even on dropped connections
    }
}
