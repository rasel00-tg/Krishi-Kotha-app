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

# Load .env from Admin Control if available
$adminEnvPath = Join-Path (Split-Path $webDir -Parent) "Krishi Kotha-Admin Control\.env"
if (Test-Path $adminEnvPath) {
    Get-Content $adminEnvPath | ForEach-Object {
        $line = $_.Trim()
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
            $parts = $line.Split("=", 2)
            if ($parts.Length -eq 2) {
                [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
            }
        }
    }
}

$R2AccountId  = [System.Environment]::GetEnvironmentVariable("R2_ACCOUNT_ID")
if ([string]::IsNullOrWhiteSpace($R2AccountId)) { $R2AccountId = "4590e8f97a7e4a512a2fadba152c9739" }
$R2AccessKey  = [System.Environment]::GetEnvironmentVariable("R2_ACCESS_KEY_ID")
if ([string]::IsNullOrWhiteSpace($R2AccessKey)) { $R2AccessKey = "589f56efee5234c2446810055c2de6be" }
$R2SecretKey  = [System.Environment]::GetEnvironmentVariable("R2_SECRET_ACCESS_KEY")
if ([string]::IsNullOrWhiteSpace($R2SecretKey)) { $R2SecretKey = "33d749af62bee6ee6246abe989e759fc990685648e2986b2a3a6250ebdbb158f" }
$R2Bucket     = [System.Environment]::GetEnvironmentVariable("R2_BUCKET_NAME")
if ([string]::IsNullOrWhiteSpace($R2Bucket)) { $R2Bucket = "krishikoth" }
$R2PublicBase = [System.Environment]::GetEnvironmentVariable("R2_PUBLIC_DEV_URL")
if ([string]::IsNullOrWhiteSpace($R2PublicBase)) { $R2PublicBase = "https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev" }
$R2HostName   = "$R2AccountId.r2.cloudflarestorage.com"

function Get-HmacSha256Bytes($key, $dataBytes) {
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $key
    return $hmac.ComputeHash($dataBytes)
}

function Get-Sha256Hex([byte[]]$rawBytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($rawBytes, 0, $rawBytes.Length)
    return -join ($hash | ForEach-Object { "{0:x2}" -f $_ })
}

function Get-R2PresignedPutUrl([string]$fileName, [string]$contentType = "image/jpeg", [int]$expiresIn = 300) {
    $now = [DateTime]::UtcNow
    $amzDate = $now.ToString("yyyyMMddTHHmmssZ")
    $dateStamp = $now.ToString("yyyyMMdd")
    $region = "auto"
    $service = "s3"

    $cleanFileName = $fileName -replace "[^a-zA-Z0-9_\.\-]", "_"
    $targetPath = "/$R2Bucket/$cleanFileName"

    $algorithm = "AWS4-HMAC-SHA256"
    $credentialScope = "$dateStamp/$region/$service/aws4_request"
    $credentialParam = [System.Uri]::EscapeDataString("$R2AccessKey/$credentialScope")

    $canonicalQuery = "X-Amz-Algorithm=$algorithm&X-Amz-Credential=$credentialParam&X-Amz-Date=$amzDate&X-Amz-Expires=$expiresIn&X-Amz-SignedHeaders=host"
    $canonicalHeaders = "host:$R2HostName`n"
    $signedHeaders = "host"
    $payloadHash = "UNSIGNED-PAYLOAD"

    $canonicalRequest = "PUT`n$targetPath`n$canonicalQuery`n$canonicalHeaders`n$signedHeaders`n$payloadHash"
    $canonicalRequestBytes = [System.Text.Encoding]::UTF8.GetBytes($canonicalRequest)
    $canonicalRequestHash = Get-Sha256Hex $canonicalRequestBytes

    $stringToSign = "$algorithm`n$amzDate`n$credentialScope`n$canonicalRequestHash"

    $kSecret = [System.Text.Encoding]::UTF8.GetBytes("AWS4" + $R2SecretKey)
    $kDate = Get-HmacSha256Bytes $kSecret ([System.Text.Encoding]::UTF8.GetBytes($dateStamp))
    $kRegion = Get-HmacSha256Bytes $kDate ([System.Text.Encoding]::UTF8.GetBytes($region))
    $kService = Get-HmacSha256Bytes $kRegion ([System.Text.Encoding]::UTF8.GetBytes($service))
    $kSigning = Get-HmacSha256Bytes $kService ([System.Text.Encoding]::UTF8.GetBytes("aws4_request"))

    $signatureBytes = Get-HmacSha256Bytes $kSigning ([System.Text.Encoding]::UTF8.GetBytes($stringToSign))
    $signature = -join ($signatureBytes | ForEach-Object { "{0:x2}" -f $_ })

    $uploadUrl = "https://$R2HostName$targetPath`?$canonicalQuery&X-Amz-Signature=$signature"
    $publicUrl = "$R2PublicBase/$cleanFileName"

    return @{
        uploadUrl = $uploadUrl
        publicUrl = $publicUrl
        fileName  = $cleanFileName
        expiresIn = $expiresIn
    }
}

function Send-R2Upload([byte[]]$bodyBytes, [string]$fileName, [string]$contentType = "image/jpeg") {
    $now = [DateTime]::UtcNow
    $amzDate = $now.ToString("yyyyMMddTHHmmssZ")
    $dateStamp = $now.ToString("yyyyMMdd")
    $region = "auto"
    $service = "s3"

    $cleanFileName = $fileName -replace "[^a-zA-Z0-9_\.\-]", "_"
    $targetPath = "/$R2Bucket/$cleanFileName"
    $payloadHash = Get-Sha256Hex $bodyBytes

    $canonicalHeaders = "content-type:$contentType`nhost:$R2HostName`nx-amz-content-sha256:$payloadHash`nx-amz-date:$amzDate`n"
    $signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date"
    $canonicalRequest = "PUT`n$targetPath`n`n$canonicalHeaders`n$signedHeaders`n$payloadHash"

    $algorithm = "AWS4-HMAC-SHA256"
    $credentialScope = "$dateStamp/$region/$service/aws4_request"
    $canonicalRequestBytes = [System.Text.Encoding]::UTF8.GetBytes($canonicalRequest)
    $canonicalRequestHash = Get-Sha256Hex $canonicalRequestBytes
    $stringToSign = "$algorithm`n$amzDate`n$credentialScope`n$canonicalRequestHash"

    $kSecret = [System.Text.Encoding]::UTF8.GetBytes("AWS4" + $R2SecretKey)
    $kDate = Get-HmacSha256Bytes $kSecret ([System.Text.Encoding]::UTF8.GetBytes($dateStamp))
    $kRegion = Get-HmacSha256Bytes $kDate ([System.Text.Encoding]::UTF8.GetBytes($region))
    $kService = Get-HmacSha256Bytes $kRegion ([System.Text.Encoding]::UTF8.GetBytes($service))
    $kSigning = Get-HmacSha256Bytes $kService ([System.Text.Encoding]::UTF8.GetBytes("aws4_request"))

    $signatureBytes = Get-HmacSha256Bytes $kSigning ([System.Text.Encoding]::UTF8.GetBytes($stringToSign))
    $signature = -join ($signatureBytes | ForEach-Object { "{0:x2}" -f $_ })

    $authHeader = "$algorithm Credential=$R2AccessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"

    $headers = @{
        "Authorization"        = $authHeader
        "x-amz-date"           = $amzDate
        "x-amz-content-sha256" = $payloadHash
        "Content-Type"         = $contentType
    }

    $uploadUri = "https://$R2HostName$targetPath"
    $null = Invoke-RestMethod -Uri $uploadUri -Method Put -Headers $headers -Body $bodyBytes

    return "$R2PublicBase/$cleanFileName"
}

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

        # 1. API: Get Temporary Pre-signed Upload URL
        if ($localPath -eq "/api/get-presigned-url" -and ($request.HttpMethod -eq "GET" -or $request.HttpMethod -eq "POST")) {
            try {
                $rawFileName = $request.QueryString["filename"]
                if ([string]::IsNullOrWhiteSpace($rawFileName)) {
                    $rawFileName = "upload_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + ".jpg"
                }
                $cType = $request.QueryString["contentType"]
                if ([string]::IsNullOrWhiteSpace($cType)) { $cType = "image/jpeg" }

                $presigned = Get-R2PresignedPutUrl -fileName $rawFileName -contentType $cType -expiresIn 300

                $jsonObj = @{
                    success   = $true
                    uploadUrl = $presigned.uploadUrl
                    publicUrl = $presigned.publicUrl
                    fileName  = $presigned.fileName
                    expiresIn = $presigned.expiresIn
                }
                $jsonStr = $jsonObj | ConvertTo-Json
                $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $jsonBytes.Length
                $response.OutputStream.Write($jsonBytes, 0, $jsonBytes.Length)
                $response.OutputStream.Close()
                continue
            } catch {
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes((@{ success = $false; error = $_.Exception.Message } | ConvertTo-Json))
                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 500
                $response.ContentLength64 = $errBytes.Length
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                $response.OutputStream.Close()
                continue
            }
        }

        # 2. API: Backend Direct Upload Gateway
        if ($localPath -eq "/api/upload-r2" -and $request.HttpMethod -eq "POST") {
            try {
                $rawFileName = $request.QueryString["filename"]
                if ([string]::IsNullOrWhiteSpace($rawFileName)) {
                    $rawFileName = $request.Headers["x-filename"]
                }
                if ([string]::IsNullOrWhiteSpace($rawFileName)) {
                    $rawFileName = "upload_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + ".jpg"
                }

                $cType = $request.ContentType
                if ([string]::IsNullOrWhiteSpace($cType)) {
                    $cType = "image/jpeg"
                }

                $ms = New-Object System.IO.MemoryStream
                $request.InputStream.CopyTo($ms)
                $bodyBytes = $ms.ToArray()

                if ($bodyBytes.Length -eq 0) {
                    throw "No image bytes received in request body"
                }

                $publicUrl = Send-R2Upload -bodyBytes $bodyBytes -fileName $rawFileName -contentType $cType

                $jsonObj = @{
                    success   = $true
                    publicUrl = $publicUrl
                    fileName  = $rawFileName
                    size      = $bodyBytes.Length
                }
                $jsonStr = $jsonObj | ConvertTo-Json
                $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $jsonBytes.Length
                $response.OutputStream.Write($jsonBytes, 0, $jsonBytes.Length)
                $response.OutputStream.Close()
                continue
            } catch {
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes((@{ success = $false; error = $_.Exception.Message } | ConvertTo-Json))
                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 500
                $response.ContentLength64 = $errBytes.Length
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                $response.OutputStream.Close()
                continue
            }
        }

        if ($localPath -eq "/" -or [string]::IsNullOrWhiteSpace($localPath)) {
            $filePath = Join-Path $webDir "index.html"
        } else {
            $cleaned = [System.Uri]::UnescapeDataString($localPath.TrimStart('/'))
            $filePath = Join-Path $webDir $cleaned
            if (-not (Test-Path $filePath -PathType Leaf)) {
                $parentAssets = Join-Path (Split-Path $webDir -Parent) $cleaned
                if (Test-Path $parentAssets -PathType Leaf) {
                    $filePath = $parentAssets
                }
            }
        }

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            if ($filePath.EndsWith(".html")) {
                $response.ContentType = "text/html; charset=utf-8"
            } elseif ($filePath.EndsWith(".css")) {
                $response.ContentType = "text/css; charset=utf-8"
            } elseif ($filePath.EndsWith(".js")) {
                $response.ContentType = "application/javascript; charset=utf-8"
            } elseif ($filePath.EndsWith(".json")) {
                $response.ContentType = "application/json; charset=utf-8"
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
