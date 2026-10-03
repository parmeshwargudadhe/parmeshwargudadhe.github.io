# Regenerates Parmeshwar-Gudadhe-Resume.pdf from index.html
# Run from the repo root:  .\tools\build-pdf.ps1
# Re-run this after editing the resume content, then commit the updated PDF.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$html = Join-Path $root 'index.html'
$pdf  = Join-Path $root 'Parmeshwar-Gudadhe-Resume.pdf'

$browsers = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)

$browser = $browsers | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $browser) { throw "Chrome or Edge not found." }

$uri = ([uri]$html).AbsoluteUri
$before = if (Test-Path -LiteralPath $pdf) { (Get-Item -LiteralPath $pdf).LastWriteTime } else { $null }

# Chrome reports success on stderr, which PowerShell 5.1 surfaces as a NativeCommandError.
$ErrorActionPreference = 'Continue'
& $browser --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdf" $uri 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'

# Chrome returns before the file handle is flushed; wait for it to settle.
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 250
    if (Test-Path -LiteralPath $pdf) {
        if (-not $before -or (Get-Item -LiteralPath $pdf).LastWriteTime -gt $before) { break }
    }
}

if (-not (Test-Path -LiteralPath $pdf)) { throw "PDF was not generated." }

$info = Get-Item -LiteralPath $pdf
"Built $($info.Name)  ($([math]::Round($info.Length / 1KB)) KB)"