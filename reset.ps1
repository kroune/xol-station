$ErrorActionPreference = 'Stop'
$StationName = 'xol-station'
$ArchiveUrl = 'https://github.com/kroune/xol-tasks/archive/refs/heads/main.zip'
$TemporaryRoot = $null

try {
    $CurrentPath = [IO.Path]::GetFullPath((Get-Location).Path).TrimEnd('\', '/')
    $Destination = [IO.Path]::GetFullPath((Join-Path $CurrentPath $StationName)).TrimEnd('\', '/')
    $DestinationPrefix = $Destination + [IO.Path]::DirectorySeparatorChar

    if ($CurrentPath.Equals($Destination, [StringComparison]::OrdinalIgnoreCase) -or
        $CurrentPath.StartsWith($DestinationPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Запустите команду из родительской папки, а не изнутри $StationName."
    }

    $TemporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("xol-station-reset-" + [Guid]::NewGuid().ToString('N'))
    $Archive = Join-Path $TemporaryRoot 'tasks.zip'
    $Extracted = Join-Path $TemporaryRoot 'extracted'
    New-Item -ItemType Directory -Path $Extracted -Force | Out-Null

    Write-Host 'Скачивание задач XOL...'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {
        # В новых версиях PowerShell настройка TLS уже управляется системой.
    }
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $Archive -UseBasicParsing
    Expand-Archive -LiteralPath $Archive -DestinationPath $Extracted -Force

    $Source = Join-Path $Extracted 'xol-tasks-main'
    $RequiredFiles = @('easy/main.xol', 'medium/main.xol', 'hard/main.xol')
    foreach ($RelativeFile in $RequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Source $RelativeFile) -PathType Leaf)) {
            throw 'Архив имеет неожиданную структуру. Существующая папка не изменена.'
        }
    }

    if (Test-Path -LiteralPath $Destination) {
        Write-Host "Удаление старой папки $Destination..."
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse

    foreach ($RelativeFile in $RequiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Destination $RelativeFile) -PathType Leaf)) {
            throw 'Папка создана не полностью. Повторите команду.'
        }
    }

    Write-Host "`nГотово: $Destination" -ForegroundColor Green
    Write-Host 'Решения и тесты сброшены.'
    Write-Host "`nЗапуск тестов (нужен Node.js 20+):"
    Write-Host "  node $StationName/easy/test.js"
    Write-Host "  node $StationName/medium/test.js"
    Write-Host "  node $StationName/hard/test.js"
} catch {
    Write-Host "`nОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Проверьте интернет, доступ к github.com и права на текущую папку.'
    exit 1
} finally {
    if ($TemporaryRoot -and (Test-Path -LiteralPath $TemporaryRoot)) {
        Remove-Item -LiteralPath $TemporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
