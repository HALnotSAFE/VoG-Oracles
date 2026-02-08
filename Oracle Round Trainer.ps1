param(
    [switch]$TestMode,
    [int]$NoteDelayMs = 450,
    [int]$FailLimit = 3
)

# Resolve Sounds folder next to script
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

function Read-OracleNumber {
    param([string]$Prompt)

    while ($true) {
        $ans = Read-Host $Prompt
        if ($ans -match '^[Qq]$') { return $null }

        $num = $ans -as [int]
        if ($num -ge 1 -and $num -le 7) { return $num }

        Write-Host "Enter a number 1-7 (or Q to quit)." -ForegroundColor DarkYellow
    }
}

function Invoke-BatchRound {
    param(
        [int[]]$Sequence
    )

    $count = $Sequence.Count

    Write-Host ""
    Write-Host ("Playing {0} notes..." -f $count) -ForegroundColor Cyan
    Start-Sleep -Milliseconds 200

    # Play phase
    for ($i = 0; $i -lt $count; $i++) {
        $oracle = $Sequence[$i]

        if ($TestMode) {
            Write-Host ("[TEST] Note {0}: Oracle {1}" -f ($i+1), $oracle) -ForegroundColor Yellow
        }

        Play-OracleSound -OracleNumber $oracle
        Start-Sleep -Milliseconds $NoteDelayMs
    }

    Write-Host ""
    Write-Host "Quiz time. Answer the notes in order." -ForegroundColor Cyan

    # Quiz phase
    for ($i = 0; $i -lt $count; $i++) {
        $guess = Read-OracleNumber -Prompt ("Note {0} oracle number?" -f ($i+1))
        if ($null -eq $guess) {
            return @{ Quit = $true; Passed = $false; WrongIndex = ($i + 1) }
        }

        if ($guess -ne $Sequence[$i]) {
            return @{ Quit = $false; Passed = $false; WrongIndex = ($i + 1) }
        }
    }

    return @{ Quit = $false; Passed = $true; WrongIndex = 0 }
}

# Main
Assert-SoundFilesExist

Write-Host "=== VoG Round Trainer (Encounter Style, Numbers Only + Audio) ===" -ForegroundColor Cyan
Write-Host ("Rounds: 3,4,5,6,7 notes. Fail = replay same sequence. {0} fails in a row = LOST TO TIME." -f $FailLimit) -ForegroundColor DarkGray
Write-Host "Type Q at any prompt to quit." -ForegroundColor DarkGray
if ($TestMode) { Write-Host "TestMode ON (shows oracle numbers during playback)." -ForegroundColor Yellow }

$roundSizes = @(3,4,5,6,7)
$points = 0
$consecutiveRoundFails = 0

for ($roundIndex = 0; $roundIndex -lt $roundSizes.Count; $roundIndex++) {
    $roundNum = $roundIndex + 1
    $needed = $roundSizes[$roundIndex]

    # Generate once per round; reuse on retries
    $sequence = (1..7 | Get-Random -Count $needed)

    while ($true) {
        Write-Host ""
        Write-Host ("--- Round {0} ({1} notes) ---" -f $roundNum, $needed) -ForegroundColor Cyan
        Write-Host ("Score: {0} | Consecutive round fails: {1}/{2}" -f $points, $consecutiveRoundFails, $FailLimit) -ForegroundColor DarkGray

        $result = Invoke-BatchRound -Sequence $sequence
        if ($result.Quit) { return }

        if ($result.Passed) {
            $points++
            $consecutiveRoundFails = 0
            Write-Host ""
            Write-Host ("Round {0} CLEARED. +1 point. (Total: {1})" -f $roundNum, $points) -ForegroundColor Green
            break
        }
        else {
            $consecutiveRoundFails++
            Write-Host ""
            Write-Host ("Note {0} was incorrect." -f $result.WrongIndex) -ForegroundColor Red
            Write-Host ("Replaying the SAME sequence for Round {0}..." -f $roundNum) -ForegroundColor Yellow

            if ($consecutiveRoundFails -ge $FailLimit) {
                Write-Host ""
                Write-Host "YOU HAVE BEEN LOST TO TIME." -ForegroundColor Magenta
                Write-Host ("Final Score: {0} / {1}" -f $points, $roundSizes.Count) -ForegroundColor Cyan
                return
            }
        }
    }
}

Write-Host ""
Write-Host ("ALL ROUNDS CLEARED. Final Score: {0} / {1}" -f $points, $roundSizes.Count) -ForegroundColor Green
