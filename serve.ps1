# Kiszolgálja a Quest demót a gépedről egy ideiglenes HTTPS-címen (cloudflared).
#
# FIGYELEM: ez a szkript Windows PowerShellre készült, de a fejlesztői
# környezetben nem volt mód lefuttatni. Ha bármi gond van vele, használd
# a README.md-ben leírt kétparancsos kézi megoldást — az egyenértékű.
#
# Használat:
#   .\serve.ps1
#   .\serve.ps1 -Src C:\ut\quest-mr-demo.html
#   .\serve.ps1 -Port 9000

param(
  [string]$Src = "",
  [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

# --- a kiszolgálandó fájl ---
if ([string]::IsNullOrWhiteSpace($Src)) {
  foreach ($cand in @("quest-mr-demo.html", "index.html",
                      (Join-Path $PSScriptRoot "quest-mr-demo.html"),
                      (Join-Path $PSScriptRoot "index.html"))) {
    if (Test-Path $cand) { $Src = (Resolve-Path $cand).Path; break }
  }
}
if ([string]::IsNullOrWhiteSpace($Src) -or -not (Test-Path $Src)) {
  Write-Error "Nem talalom a HTML fajlt. Add meg: .\serve.ps1 -Src C:\ut\quest-mr-demo.html"
  exit 1
}

# --- python megkeresese ---
$py = $null; $pyArgs = @()
if (Get-Command python -ErrorAction SilentlyContinue)   { $py = "python" }
elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $py = "python3" }
elseif (Get-Command py -ErrorAction SilentlyContinue)   { $py = "py"; $pyArgs = @("-3") }
else { Write-Error "Nincs python a PATH-on. Telepitsd: winget install Python.Python.3.12"; exit 1 }

if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
  Write-Error "Nincs cloudflared. Telepitsd: winget install --id Cloudflare.cloudflared"
  exit 1
}

# --- tiszta kiszolgalo mappa: a demo index.html neven ---
$www = Join-Path $env:TEMP ("questxr-" + [System.IO.Path]::GetRandomFileName().Substring(0,8))
New-Item -ItemType Directory -Path $www -Force | Out-Null
Copy-Item $Src (Join-Path $www "index.html") -Force
$chk = Join-Path $PSScriptRoot "check.html"
if (Test-Path $chk) { Copy-Item $chk (Join-Path $www "check.html") -Force }

$log = Join-Path $www "tunnel.log"
$httpProc = $null
$tunProc = $null

try {
  Write-Host "Kiszolgalas: $Src"
  $httpProc = Start-Process -FilePath $py `
    -ArgumentList ($pyArgs + @("-m","http.server","$Port","--bind","127.0.0.1","--directory","$www")) `
    -NoNewWindow -PassThru
  Start-Sleep -Seconds 2
  if ($httpProc.HasExited) {
    Write-Error "A helyi szerver nem indult el (foglalt a $Port port?). Probald: .\serve.ps1 -Port 9000"
    exit 1
  }
  Write-Host "Helyi szerver fut:  http://127.0.0.1:$Port  (csak a gepedrol)"

  Write-Host "Tunnel inditasa (cloudflared)..."
  $tunProc = Start-Process -FilePath "cloudflared" `
    -ArgumentList @("tunnel","--url","http://127.0.0.1:$Port","--no-autoupdate") `
    -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"

  $url = $null
  for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    foreach ($f in @($log, "$log.err")) {
      if (Test-Path $f) {
        $m = Select-String -Path $f -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -AllMatches |
             Select-Object -First 1
        if ($m) { $url = $m.Matches[0].Value; break }
      }
    }
    if ($url) { break }
    if ($tunProc.HasExited) { break }
  }

  if (-not $url) {
    Write-Error "Nem kaptam trycloudflare URL-t. Tunnel log:"
    if (Test-Path "$log.err") { Get-Content "$log.err" -Tail 25 }
    exit 1
  }

  Write-Host ""
  Write-Host "============================================================"
  Write-Host "  Ird be a Quest bongeszojenek cimsoraba:"
  Write-Host ""
  Write-Host "      $url"
  Write-Host ""
  Write-Host "  Diagnosztika:  $url/check.html"
  Write-Host "============================================================"
  Write-Host ""
  Write-Host "A szkript futasa alatt el a cim. Leallitas: Ctrl+C"

  Wait-Process -Id $tunProc.Id
}
finally {
  foreach ($p in @($tunProc, $httpProc)) {
    if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  }
  Remove-Item $www -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host ""
  Write-Host "Leallitva."
}
