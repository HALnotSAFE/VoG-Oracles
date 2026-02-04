param(
    [switch]$TestMode
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$SingleScript = Join-Path $ScriptDir "Oracle Sound Trainer.ps1"
$RoundScript  = Join-Path $ScriptDir "Oracle Round Trainer.ps1"

function Assert-FileExists([string]$path, [string]$label) {
    if (-not (Test-Path $path)) {
        throw "$label not found: $path"
    }
}

Assert-FileExists $SingleScript "Single trainer script"
Assert-FileExists $RoundScript  "Round trainer script"

function Show-Menu {
    Clear-Host
    Write-Host "=== VoG Oracle Trainer ===" -ForegroundColor Cyan
    Write-Host "Select a mode:" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1) Note Trainer (single note: number + side)" -ForegroundColor White
    Write-Host "  2) Round Trainer (encounter-style: batch play -> quiz)" -ForegroundColor White
    Write-Host ""
    Write-Host "  T) Toggle TestMode (currently: $($script:TestModeEnabled))" -ForegroundColor Yellow
    Write-Host "  Q) Quit" -ForegroundColor DarkGray
    Write-Host ""
}

# Keep state for toggling while menu is open
$script:TestModeEnabled = [bool]$TestMode

while ($true) {
    Show-Menu
    $choice = (Read-Host "Choice").Trim().ToLower()

    switch ($choice) {
        "1" {
            # Run single trainer
            if ($script:TestModeEnabled) {
                & $SingleScript -TestMode
            } else {
                & $SingleScript
            }

            Write-Host "`nPress Enter to return to menu..." -ForegroundColor DarkGray
            [void](Read-Host)
        }
        "2" {
            # Run round trainer
            if ($script:TestModeEnabled) {
                & $RoundScript -TestMode
            } else {
                & $RoundScript
            }

            Write-Host "`nPress Enter to return to menu..." -ForegroundColor DarkGray
            [void](Read-Host)
        }
        "t" {
            $script:TestModeEnabled = -not $script:TestModeEnabled
        }
        "q" {
            break
        }
        default {
            Write-Host "Invalid choice. Use 1, 2, T, or Q." -ForegroundColor Red
            Start-Sleep -Milliseconds 700
        }
    }
}
