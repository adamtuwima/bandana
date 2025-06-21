param (
    [string]$GitUser = "adamtuwima",
    [string]$Repo = "bandana"
)

$ErrorActionPreference = "Stop"

Write-Host "`n[1/6] Проверка pip..." -ForegroundColor Cyan
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "pip не найден. Устанавливаю..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile "get-pip.py"
    python get-pip.py
    Remove-Item "get-pip.py"
}

Write-Host "[2/6] Установка mitmproxy..." -ForegroundColor Cyan
pip install mitmproxy --quiet

Write-Host "[3/6] Генерация сертификатов mitmproxy..." -ForegroundColor Cyan
Start-Process -NoNewWindow -Wait -FilePath "mitmproxy" -ArgumentList "--quit"

Write-Host "[4/6] Установка сертификата в доверенные..." -ForegroundColor Cyan
$certPath = "$env:USERPROFILE\.mitmproxy\mitmproxy-ca-cert.pem"
certutil -addstore Root $certPath | Out-Null

Write-Host "[5/6] Генерация live_script_temp.py с правильной ссылкой..." -ForegroundColor Cyan
$scriptTemplate = Get-Content ".\live_script.py" -Raw
$configURL = "https://$GitUser.github.io/$Repo/config.json"
$scriptPatched = $scriptTemplate -replace 'CONFIG_URL = ".*?"', "CONFIG_URL = `"$configURL`""
Set-Content -Path ".\live_script_temp.py" -Value $scriptPatched -Encoding UTF8

Write-Host "[6/6] Запуск mitmproxy..." -ForegroundColor Cyan
Start-Process -NoNewWindow -FilePath "mitmproxy" -ArgumentList "-s live_script_temp.py"

Write-Host "`n✅ Всё готово. mitmproxy работает с конфигурацией: $configURL" -ForegroundColor Green