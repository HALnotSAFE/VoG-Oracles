param(
    [switch]$TestMode,
    [int]$NoteDelayMs = 450
)

# -------------------------
# Resolve Sounds folder next to script
# -------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SoundFolder = Join-Path $ScriptDir "Sounds"

if (-not (Test-Path $SoundFolder)) {
    throw "Sounds folder not found next to script. Expected: $SoundFolder"
}

# -------------------------
# Helpers
# -------------------------
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

function Read-OracleNumber([string]$prompt) {
    while ($true) {
        $ans = Read-Host $prompt
        if ($ans -match '^[Qq]$') { return $null }
        $num = $ans -as [int]
        if ($num -ge 1 -and $num -le 7) { return $num }
        Write-Host "Enter a number 1-7 (or Q to quit)." -ForegroundColor DarkYellow
    }
}

function Invoke-BatchRound {
    param([int[]]$sequence)

    $count = $sequence.Count

    Write-Host "`n🎵 Playing $count notes..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 250

    # PLAY PHASE
    for ($i = 0; $i -lt $count; $i++) {
        $oracle = $sequence[$i]

        if ($TestMode) {
            Write-Host ("[TEST] NOTE {0}: Oracle {1}" -f ($i+1), $oracle) -ForegroundColor Yellow
        }

        Play-OracleSound $oracle
        Start-Sleep -Milliseconds $NoteDelayMs
    }

    Write-Host "`n❓ Quiz time. Answer the notes in order." -ForegroundColor Cyan

    # QUIZ PHASE
    for ($i = 0; $i -lt $count; $i++) {
        $guess = Read-OracleNumber "Note $($i+1) oracle number?"
        if ($null -eq $guess) { return @{ Quit = $true; Passed = $false; WrongIndex = $i + 1 } }

        if ($guess -ne $sequence[$i]) {
            return @{ Quit = $false; Passed = $false; WrongIndex = $i + 1 }
        }
    }

    return @{ Quit = $false; Passed = $true; WrongIndex = 0 }
}

# -------------------------
# Main
# -------------------------
Assert-SoundFilesExist

Write-Host "=== VoG Round Trainer (Encounter Style + Audio) ===" -ForegroundColor Cyan
Write-Host "Rounds: 3,4,5,6,7 notes. Fail = replay same sequence. 3 fails in a row = LOST TO TIME." -ForegroundColor DarkGray
if ($TestMode) { Write-Host "TestMode ON (oracle numbers shown during playback)" -ForegroundColor Yellow }
Write-Host ""

$roundSizes = @(3,4,5,6,7)
$points = 0
$consecutiveRoundFails = 0

for ($roundIndex = 0; $roundIndex -lt $roundSizes.Count; $roundIndex++) {
    $roundNum = $roundIndex + 1
    $needed = $roundSizes[$roundIndex]

    $sequence = (1..7 | Get-Random -Count $needed)

    while ($true) {
        Write-Host "`n--- Round $roundNum ($needed notes) ---" -ForegroundColor Cyan
        Write-Host "Score: $points | Consecutive round fails: $consecutiveRoundFails/3" -ForegroundColor DarkGray

        $result = Invoke-BatchRound -sequence $sequence
        if ($result.Quit) { return }

        if ($result.Passed) {
            $points++
            $consecutiveRoundFails = 0
            Write-Host "`n🏆 Round $roundNum CLEARED. +1 point. (Total: $points)" -ForegroundColor Green
            break
        }
        else {
            $consecutiveRoundFails++
            Write-Host "`n❌ Note $($result.WrongIndex) was incorrect." -ForegroundColor Red
            Write-Host "🔁 Replaying the SAME sequence..." -ForegroundColor Yellow

            if ($consecutiveRoundFails -ge 3) {
                Write-Host "`n⏳ YOU HAVE BEEN LOST TO TIME." -ForegroundColor Magenta
                Write-Host "Final Score: $points / $($roundSizes.Count)" -ForegroundColor Cyan
                return
            }
        }
    }
}

Write-Host "`n👑 ALL ROUNDS CLEARED. Final Score: $points / $($roundSizes.Count)" -ForegroundColor Green
