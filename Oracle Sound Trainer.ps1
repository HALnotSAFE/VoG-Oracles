param(
    [switch]$TestMode
)

# -------------------------
# Resolve Sounds folder next to script
# -------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SoundFolder = Join-Path $ScriptDir "Sounds"

if (-not (Test-Path $SoundFolder)) {
    throw "Sounds folder not found next to script. Expected: $SoundFolder"
}

function Get-OracleSoundPath {
    param([int]$OracleNumber)
    Join-Path $SoundFolder ("oracle{0}.wav" -f $OracleNumber)
}

function Assert-SoundFilesExist {
    $missing = @()
    foreach ($n in 1..7) {
        $p = Get-OracleSoundPath $n
        if (-not (Test-Path $p)) { $missing += $p }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Missing required sound files:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
        throw "Create oracle1.wav .. oracle7.wav inside the Sounds folder."
    }
}

function Play-OracleSound {
    param([int]$OracleNumber)

    $path = Get-OracleSoundPath $OracleNumber
    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $path
    $player.Load()
    $player.PlaySync()
}

function Normalize-Side([string]$side) {
    $s = $side.Trim().ToLower()
    switch ($s) {
        "l" { "left" }
        "left" { "left" }
        "r" { "right" }
        "right" { "right" }
        "m" { "middle" }
        "mid" { "middle" }
        "middle" { "middle" }
        default { $s }
    }
}

Assert-SoundFilesExist

# Oracle side mapping
$oracleMap = @{
    1 = "Middle"
    2 = "Left"
    3 = "Right"
    4 = "Left"
    5 = "Right"
    6 = "Left"
    7 = "Right"
}

Write-Host "=== VoG Oracle Trainer (Single Note + Audio) ===" -ForegroundColor Cyan
Write-Host "Sounds folder: $SoundFolder" -ForegroundColor DarkGray
Write-Host "Type Q at any time to quit.`n" -ForegroundColor DarkGray
if ($TestMode) { Write-Host "TestMode ON (shows oracle number after playback)" -ForegroundColor Yellow }

while ($true) {
    # Pick random oracle
    $oracle = Get-Random -Minimum 1 -Maximum 8
    $correctSide = $oracleMap[$oracle]

    # Play sound
    Play-OracleSound -OracleNumber $oracle

    if ($TestMode) {
        Write-Host "`n[TEST] Oracle $oracle triggered." -ForegroundColor Yellow
    }

    # Ask for number
    $numAnswer = Read-Host "Which oracle number was it (1-7)?"
    if ($numAnswer -match '^[Qq]$') { break }

    # Ask for side
    $sideAnswer = Read-Host "Which side (Left / Right / Middle)?"
    if ($sideAnswer -match '^[Qq]$') { break }

    # Normalize + validate
    $numCorrect  = ($numAnswer -as [int]) -eq $oracle
    $sideCorrect = (Normalize-Side $sideAnswer) -eq $correctSide.ToLower()

    if ($numCorrect -and $sideCorrect) {
        Write-Host "✅ Correct! Oracle $oracle is $correctSide." -ForegroundColor Green
    }
    else {
        Write-Host "❌ Not quite." -ForegroundColor Red
        Write-Host "   Correct answer: Oracle $oracle — $correctSide" -ForegroundColor Cyan
    }
}
