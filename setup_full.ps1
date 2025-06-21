# Включаем поддержку TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function SmartDownload {
    param (
        [string]$url,
        [string]$output
    )
    Write-Host "⬇️ Загружаю: $url"
    try {
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $url -Destination $output -ErrorAction Stop
            return
        }
    } catch {
        Write-Host "⚠️ BITS не сработал, пробуем WebClient..."
    }
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("user-agent", "PowerShell")
        $wc.DownloadFile($url, $output)
    } catch {
        Write-Error "❌ Ошибка при скачивании ${url}: ${_}"
        throw
    }
}

$arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
$is64bit = $arch -like "*64*"

function InstallPython {
    Write-Host "🧪 Проверяю Python..."
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "⚙️ Устанавливаю Python ($arch)..."
        $installer = "$env:TEMP\python-installer.exe"
        $url = if ($is64bit) {
            "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
        } else {
            "https://www.python.org/ftp/python/3.12.0/python-3.12.0.exe"
        }
        SmartDownload $url $installer
        Start-Process -FilePath $installer -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
        Remove-Item $installer -Force
    } else {
        Write-Host "✅ Python уже установлен."
    }
}

function InstallGit {
    Write-Host "🧪 Проверяю Git..."
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "⚙️ Устанавливаю Git ($arch)..."
        $installer = "$env:TEMP\git-installer.exe"
        $url = if ($is64bit) {
            "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.1/Git-2.42.0-64-bit.exe"
        } else {
            "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.1/Git-2.42.0-32-bit.exe"
        }
        SmartDownload $url $installer
        Start-Process -FilePath $installer -ArgumentList "/VERYSILENT" -Wait
        Remove-Item $installer -Force
    } else {
        Write-Host "✅ Git уже установлен."
    }
}

function InstallMitmproxy {
    Write-Host "⚙️ Устанавливаю mitmproxy..."
    & python -m pip install --upgrade pip
    & python -m pip install mitmproxy --quiet

    Write-Host "🚀 Запускаю mitmproxy для генерации сертификата..."
    Start-Process -FilePath "mitmproxy" -ArgumentList "--quit" -NoNewWindow -Wait
}

function InstallMitmproxyCert {
    Write-Host "🔒 Устанавливаю сертификат mitmproxy..."

    $mitmproxyCertDir = "$env:USERPROFILE\.mitmproxy"
    $certFile = Join-Path $mitmproxyCertDir "mitmproxy-ca-cert.pem"

    $timeout = 30
    $elapsed = 0
    while (-not (Test-Path $certFile) -and ($elapsed -lt $timeout)) {
        Start-Sleep -Seconds 1
        $elapsed++
    }

    if (Test-Path $certFile) {
        Import-Certificate -FilePath $certFile -CertStoreLocation Cert:\CurrentUser\Root
        Write-Host "✅ Сертификат установлен."
    }
    else {
        Write-Warning "⚠️ Сертификат mitmproxy не найден в $certFile после ожидания $timeout сек."
    }
}

function CloneRepo {
    $repoUrl = "https://github.com/adamtuwima/bandana.git"
    $cloneDir = "$env:USERPROFILE\mitmproxy-config"
    if (Test-Path $cloneDir) {
        Remove-Item -Recurse -Force $cloneDir
    }
    git clone $repoUrl $cloneDir
    return $cloneDir
}

function RunMitmproxy($cloneDir) {
    Write-Host "🚀 Запускаю mitmproxy..."
    $scriptPath = Join-Path $cloneDir "live_script.py"
    Start-Process -NoNewWindow -FilePath "mitmproxy" -ArgumentList "--scripts", $scriptPath
    Write-Host "✅ Mitmproxy запущен."
}

try {
    InstallPython
    InstallGit
    InstallMitmproxy
    InstallMitmproxyCert
    $dir = CloneRepo
    RunMitmproxy $dir
}
catch {
    Write-Error "❌ Произошла ошибка: ${_}"
}