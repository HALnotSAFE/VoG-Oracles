# VoG Oracle Sound Trainer

PowerShell training tool for memorizing Vault of Glass oracle callouts.
This project helps you train oracle recognition for the Destiny 2 raid Vault of Glass using real audio cues and memory drills.
It simulates how oracles play in the encounter and quizzes you on what you heard.

## Two Training Modes
### 1) Note Trainer (Single Oracle)
Plays one oracle sound <br>
You answer:
- Which oracle number?
- Which side? (Left / Right / Middle)

Great for learning base mapping

### 2) Round Trainer (Encounter Style)
Plays multiple notes first (like the real encounter)
Then quizzes you in order
Same sequence replays on failure (just like VoG)

5 escalating rounds:
- Round 1 → 3 notes
- Round 2 → 4 notes
- Round 3 → 5 notes
- Round 4 → 6 notes
- Round 5 → 7 notes (full set)

Encounter Rules Simulated
- Mistakes do not reveal the correct oracle
- 3 failed rounds in a row = LOST TO TIME
- Batch playback → quiz format (memory training)

Test Mode
Shows which oracle is being played
Great for verifying sound mapping
