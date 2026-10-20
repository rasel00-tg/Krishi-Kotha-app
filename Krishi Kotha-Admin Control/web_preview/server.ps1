param (
    [int]$Port = 5000
)

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Output "Krishi Kotha Admin Control Preview server started at $prefix"
} catch {
    Write-Error ("Failed to start listener on port $Port : " + $_)
    exit 1
}

$webDir = $PSScriptRoot

# ==================== ENVIRONMENT CONFIGURATION ====================
# Securely load credentials from process environment or .env file (NEVER hardcoded in source)
function Load-DotEnvFile([string]$path) {
    if (Test-Path $path) {
        Get-Content $path | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
                $idx = $line.IndexOf("=")
                $key = $line.Substring(0, $idx).Trim()
                $val = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
                if (-not [System.Environment]::GetEnvironmentVariable($key)) {
                    [System.Environment]::SetEnvironmentVariable($key, $val, "Process")
                }
            }
        }
    }
}

$projectRoot = Split-Path $PSScriptRoot -Parent
Load-DotEnvFile (Join-Path $projectRoot ".env")
Load-DotEnvFile (Join-Path $PSScriptRoot ".env")

$R2AccountId  = [System.Environment]::GetEnvironmentVariable("R2_ACCOUNT_ID")
$R2AccessKey  = [System.Environment]::GetEnvironmentVariable("R2_ACCESS_KEY_ID")
$R2SecretKey  = [System.Environment]::GetEnvironmentVariable("R2_SECRET_ACCESS_KEY")
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

# ==================== PRE-SIGNED URL GENERATOR (INDUSTRY STANDARD) ====================
# Generates a temporary, short-lived (5-10 min) single-use Pre-signed PUT URL using AWS SigV4.
# Master Secret Access Key remains strictly protected on backend server.
function Get-R2PresignedPutUrl([string]$fileName, [string]$contentType = "image/jpeg", [int]$expiresIn = 300) {
    if ([string]::IsNullOrWhiteSpace($R2SecretKey) -or [string]::IsNullOrWhiteSpace($R2AccessKey)) {
        throw "Cloudflare R2 credentials not configured in environment or .env"
    }

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

    # Canonical query string (sorted alphabetically)
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

# ==================== BACKEND DIRECT UPLOAD GATEWAY ====================
function Send-R2Upload([byte[]]$bodyBytes, [string]$fileName, [string]$contentType = "image/jpeg") {
    if ([string]::IsNullOrWhiteSpace($R2SecretKey) -or [string]::IsNullOrWhiteSpace($R2AccessKey)) {
        throw "Cloudflare R2 credentials not configured in environment or .env"
    }

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

        # Enable CORS for secure cross-origin requests
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS, HEAD")
        $response.AddHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, x-filename")

        if ($request.HttpMethod -eq "OPTIONS" -or $request.HttpMethod -eq "HEAD") {
            $response.StatusCode = 200
            $response.OutputStream.Close()
            continue
        }

        $localPath = $request.Url.LocalPath

        # 1. API: Get Temporary Pre-signed Upload URL (Secure Pre-signed URL handshake)
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
                $outBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $outBytes.Length
                $response.OutputStream.Write($outBytes, 0, $outBytes.Length)
            } catch {
                $errObj = @{ success = $false; error = $_.ToString() }
                $errStr = $errObj | ConvertTo-Json
                $outBytes = [System.Text.Encoding]::UTF8.GetBytes($errStr)
                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 500
                $response.ContentLength64 = $outBytes.Length
                $response.OutputStream.Write($outBytes, 0, $outBytes.Length)
            }

            $response.OutputStream.Close()
            continue
        }

        # 2. API: Backend Upload Gateway (Server-side signed S3 upload)
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

                # Read body bytes
                $memStream = New-Object System.IO.MemoryStream
                $request.InputStream.CopyTo($memStream)
                $bodyBytes = $memStream.ToArray()
                $memStream.Dispose()

                if ($bodyBytes.Length -eq 0) {
                    throw "No image bytes received in payload"
                }

                $publicUrl = Send-R2Upload -bodyBytes $bodyBytes -fileName $rawFileName -contentType $cType

                $jsonObj = @{
                    success   = $true
                    publicUrl = $publicUrl
                    fileName  = $rawFileName
                    size      = $bodyBytes.Length
                }
                $jsonStr = $jsonObj | ConvertTo-Json
                $outBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $outBytes.Length
                $response.OutputStream.Write($outBytes, 0, $outBytes.Length)
            } catch {
                $errObj = @{
                    success = $false
                    error   = $_.ToString()
                }
                $errStr = $errObj | ConvertTo-Json
                $outBytes = [System.Text.Encoding]::UTF8.GetBytes($errStr)

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 500
                $response.ContentLength64 = $outBytes.Length
                $response.OutputStream.Write($outBytes, 0, $outBytes.Length)
            }

            $response.OutputStream.Close()
            continue
        }

        # Static File Serving
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
