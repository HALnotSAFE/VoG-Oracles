param(
    [switch]$TestMode
)

# Resolve Sounds folder next to script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SoundFolder = Join-Path $ScriptDir "Sounds"

if (-not (Test-Path $SoundFolder)) {
    throw ("Sounds folder not found next to script. Expected: {0}" -f $SoundFolder)
}

function Get-OracleSoundPath {
    param([int]$OracleNumber)
    Join-Path $SoundFolder ("oracle{0}.wav" -f $OracleNumber)
}

function Assert-SoundFilesExist {
    $missing = @()
    foreach ($n in 1..7) {
        $p = Get-OracleSoundPath -OracleNumber $n
        if (-not (Test-Path $p)) { $missing += $p }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Missing required sound files:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host (" - {0}" -f $_) -ForegroundColor Red }
        throw "Create oracle1.wav .. oracle7.wav inside the Sounds folder."
    }
}

function Play-OracleSound {
    param([int]$OracleNumber)

    $path = Get-OracleSoundPath -OracleNumber $OracleNumber
    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $path
    $player.Load()
    $player.PlaySync()
}

function Normalize-Side {
    param([string]$Side)

    $s = $Side.Trim().ToLower()
    switch ($s) {
        "l" { return "left" }
        "left" { return "left" }
        "r" { return "right" }
        "right" { return "right" }
        "m" { return "middle" }
        "mid" { return "middle" }
        "middle" { return "middle" }
        default { return $s }
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
Write-Host ("Sounds folder: {0}" -f $SoundFolder) -ForegroundColor DarkGray
Write-Host "Type Q at any prompt to quit." -ForegroundColor DarkGray
if ($TestMode) { Write-Host "TestMode ON (shows oracle number after playback)." -ForegroundColor Yellow }

while ($true) {
    # Pick random oracle
    $oracle = Get-Random -Minimum 1 -Maximum 8
    $correctSide = $oracleMap[$oracle]

    # Play sound
    Play-OracleSound -OracleNumber $oracle

    if ($TestMode) {
        Write-Host ("[TEST] Oracle {0} triggered." -f $oracle) -ForegroundColor Yellow
    }

    # Ask for number
    $numAnswer = Read-Host "Which oracle number was it (1-7)?"
    if ($numAnswer -match '^[Qq]$') { break }

    # Ask for side
    $sideAnswer = Read-Host "Which side (Left / Right / Middle)? (L/R/M ok)"
    if ($sideAnswer -match '^[Qq]$') { break }

    # Normalize + validate
    $numCorrect  = ($numAnswer -as [int]) -eq $oracle
    $sideCorrect = (Normalize-Side -Side $sideAnswer) -eq $correctSide.ToLower()

    if ($numCorrect -and $sideCorrect) {
        Write-Host ("Correct! Oracle {0} is {1}." -f $oracle, $correctSide) -ForegroundColor Green
    }
    else {
        Write-Host "Not quite." -ForegroundColor Red
        Write-Host ("Correct answer: Oracle {0} - {1}" -f $oracle, $correctSide) -ForegroundColor Cyan
    }
}
