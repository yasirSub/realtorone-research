param(
    [string]$BaseUrl = 'https://realtorone-backend.onrender.com/api',
    [string]$CourseTitle = 'Realtor Cold Calling Mastery Program',
    [string]$ModuleTitle = 'Identity & Mindset for Cold Calling',
    [string]$LessonTitle = 'Caller Identity Reset',
    [string]$VideoPath = 'D:\SB tiger\research\courses\coldcallingmaster_program\module 1 Identity & Mindset for Cold Calling\1080.mp4',
    [string]$PdfPath = 'D:\SB tiger\research\courses\coldcallingmaster_program\module 1 Identity & Mindset for Cold Calling\fba9ecff882c49d3bea16537c8f3b643.pdf',
    [string]$BearerToken = ''
)

$ErrorActionPreference = 'Stop'

function Get-Headers {
    if ([string]::IsNullOrWhiteSpace($BearerToken)) {
        return @{}
    }

    return @{ Authorization = "Bearer $BearerToken" }
}

function Invoke-ApiJson {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [object]$Body
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = Get-Headers
        TimeoutSec  = 120
    }

    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = ($Body | ConvertTo-Json -Depth 20)
    }

    return Invoke-RestMethod @params
}

function Upload-CourseAsset {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $true)][string]$ApiBase
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "File not found: $Path"
    }

    Add-Type -AssemblyName System.Net.Http

    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromMinutes(20)

    if (-not [string]::IsNullOrWhiteSpace($BearerToken)) {
        $client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $BearerToken)
    }

    try {
        $content = [System.Net.Http.MultipartFormDataContent]::new()
        $fileBytes = [System.IO.File]::ReadAllBytes($Path)
        $fileContent = [System.Net.Http.ByteArrayContent]::new($fileBytes)
        $fileName = [System.IO.Path]::GetFileName($Path)
        $mimeType = switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
            '.mp4' { 'video/mp4' }
            '.pdf' { 'application/pdf' }
            '.png' { 'image/png' }
            default { 'application/octet-stream' }
        }

        $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($mimeType)
        $content.Add($fileContent, 'file', $fileName)
        $content.Add([System.Net.Http.StringContent]::new($Type), 'type')

        $response = $client.PostAsync("$ApiBase/admin/courses/upload", $content).GetAwaiter().GetResult()
        $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        if (-not $response.IsSuccessStatusCode) {
            throw "Upload failed for $fileName. HTTP $($response.StatusCode): $responseBody"
        }

        return $responseBody | ConvertFrom-Json
    }
    finally {
        $client.Dispose()
    }
}

$apiBase = $BaseUrl.TrimEnd('/')

Write-Host "Loading courses from $apiBase ..."
$coursesResponse = Invoke-ApiJson -Method 'GET' -Uri "$apiBase/admin/courses"
if (-not $coursesResponse.success) {
    throw 'Course list request did not succeed.'
}

$course = $coursesResponse.data | Where-Object {
    $_.title -eq $CourseTitle -or $_.title -like "*$CourseTitle*"
} | Select-Object -First 1

if (-not $course) {
    throw "Course not found: $CourseTitle"
}

Write-Host "Loading course details for [$($course.id)] $($course.title) ..."
$courseDetails = Invoke-ApiJson -Method 'GET' -Uri "$apiBase/admin/courses/$($course.id)"
if (-not $courseDetails.success) {
    throw 'Course detail request did not succeed.'
}

$module = $courseDetails.data.modules | Where-Object {
    $_.title -eq $ModuleTitle -or $_.title -like "*$ModuleTitle*"
} | Select-Object -First 1

if (-not $module) {
    throw "Module not found: $ModuleTitle"
}

$lesson = $module.lessons | Where-Object {
    $_.title -eq $LessonTitle -or $_.title -like "*$LessonTitle*"
} | Select-Object -First 1

if (-not $lesson) {
    throw "Lesson not found: $LessonTitle"
}

Write-Host "Target lesson: [$($lesson.id)] $($lesson.title)"

$videoUpload = Upload-CourseAsset -Path $VideoPath -Type 'Video' -ApiBase $apiBase
if (-not $videoUpload.success) {
    throw "Video upload failed: $($videoUpload.message)"
}

$pdfUpload = Upload-CourseAsset -Path $PdfPath -Type 'PDF' -ApiBase $apiBase
if (-not $pdfUpload.success) {
    throw "PDF upload failed: $($pdfUpload.message)"
}

$videoMaterial = $lesson.materials | Where-Object { $_.type -eq 'Video' } | Select-Object -First 1
$pdfMaterial = $lesson.materials | Where-Object { $_.type -eq 'PDF' } | Select-Object -First 1

$videoPayload = @{
    title = $videoUpload.name
    type = 'Video'
    url = $videoUpload.url
    count = 1
}

$pdfPayload = @{
    title = $pdfUpload.name
    type = 'PDF'
    url = $pdfUpload.url
    count = 1
}

if ($videoMaterial) {
    Write-Host "Updating existing video material [$($videoMaterial.id)] ..."
    $videoResult = Invoke-ApiJson -Method 'PUT' -Uri "$apiBase/admin/materials/$($videoMaterial.id)" -Body $videoPayload
}
else {
    Write-Host 'Creating new video material ...'
    $videoResult = Invoke-ApiJson -Method 'POST' -Uri "$apiBase/admin/lessons/$($lesson.id)/materials" -Body $videoPayload
}

if ($pdfMaterial) {
    Write-Host "Updating existing PDF material [$($pdfMaterial.id)] ..."
    $pdfResult = Invoke-ApiJson -Method 'PUT' -Uri "$apiBase/admin/materials/$($pdfMaterial.id)" -Body $pdfPayload
}
else {
    Write-Host 'Creating new PDF material ...'
    $pdfResult = Invoke-ApiJson -Method 'POST' -Uri "$apiBase/admin/lessons/$($lesson.id)/materials" -Body $pdfPayload
}

Write-Host ''
Write-Host 'Course assets updated.'
Write-Host ("Course : [{0}] {1}" -f $course.id, $course.title)
Write-Host ("Module : [{0}] {1}" -f $module.id, $module.title)
Write-Host ("Lesson : [{0}] {1}" -f $lesson.id, $lesson.title)
Write-Host ("Video  : {0}" -f $videoUpload.url)
Write-Host ("PDF    : {0}" -f $pdfUpload.url)
Write-Host ''
Write-Host 'Video API response:'
$videoResult | ConvertTo-Json -Depth 10
Write-Host 'PDF API response:'
$pdfResult | ConvertTo-Json -Depth 10