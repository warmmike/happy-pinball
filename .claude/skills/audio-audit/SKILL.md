---
name: Pinball Audio Audit
description: Measure and adjust MP3 volume levels for pinball sounds. Use when user wants to review, compare, or change audio volumes for music or effects.
---

# Pinball Audio Audit

## When to use this skill
- User wants to audit, standardize, or adjust sound/music volumes
- User notices something sounds too loud or too quiet on hardware
- Adding new MP3 files that need volume-matching
- User says "check audio", "normalize sounds", "adjust volume", "music too quiet", etc.

This skill covers two modes:
- **Audit only** — measure all files, report levels and config settings, discuss with user
- **Audit + fix** — measure, then apply targeted ffmpeg adjustments based on user observations

Always audit first, discuss observations, then fix. Volume decisions are observation-driven.

## Workflow

1. **Audit** — measure all files and show MPF volume settings
2. **Discuss** — user gives observations (too loud, too quiet, placeholder, artifacts, etc.)
3. **Choose method** — loudnorm for most files; fixed-dB for short or highly dynamic tracks
4. **Fix** — apply ffmpeg, verify levels, commit and push

---

## Step 1: Full audio audit

```bash
SOUNDS=/Users/mike/Documents/work/pinball/happy-pinball/sounds

echo "=== EFFECTS ==="
for f in $SOUNDS/effects/*.mp3; do
  mean=$(ffmpeg -i "$f" -af volumedetect -f null /dev/null 2>&1 | grep mean_volume | awk '{print $5, $6}')
  max=$(ffmpeg -i "$f" -af volumedetect -f null /dev/null 2>&1 | grep max_volume | awk '{print $5, $6}')
  echo "$(basename $f): mean=$mean  max=$max"
done

echo ""
echo "=== MUSIC ==="
for f in $SOUNDS/music/*.mp3; do
  mean=$(ffmpeg -i "$f" -af volumedetect -f null /dev/null 2>&1 | grep mean_volume | awk '{print $5, $6}')
  max=$(ffmpeg -i "$f" -af volumedetect -f null /dev/null 2>&1 | grep max_volume | awk '{print $5, $6}')
  echo "$(basename $f): mean=$mean  max=$max"
done
```

Check current MPF volume settings:
```bash
grep -r "volume:" /Users/mike/Documents/work/pinball/happy-pinball/modes/ --include="*.yaml" -n
```

---

## Step 2: Genre map and known notes

- **hard_rock** → randomly plays song1 or song2
- **metal** → song3 only (placeholder — Luigi's Mansion audio, quiet/moody, NOT metal — exclude from normalization)
- **attract** → slick-rick-lick.mp3 (Tool — Enigma)

**Known file notes:**
- `song3.mp3` — placeholder, skip normalization until replaced with a real metal track
- `slick-rick-lick.mp3` — Tool track (Enigma), highly dynamic. **Use fixed-dB boost only** — loudnorm causes pumping/phase artifacts on this track. Restored to original 2026-08-26.
- `bumper_left.mp3` — very short (0.264s), too short for loudnorm — use fixed-dB cut/boost only
- `bumper_right.mp3` — short transient, loudnorm unreliable — use fixed-dB if further adjustment needed

---

## Step 3a: Loudnorm — for most files (two-pass, handles files at 0 dB ceiling)

Use for: longer music files and longer effects (ball_ended, entrance, plunger).
Do NOT use for: very short files (<1s) or highly dynamic tracks (see notes above).

```bash
TARGET=-11  # music target; use -12 for effects

FILE=/Users/mike/Documents/work/pinball/happy-pinball/sounds/music/song1.mp3
TMPFILE="${FILE%.mp3}_tmp.mp3"

# Pass 1
P1=$(ffmpeg -i "$FILE" -af "loudnorm=I=${TARGET}:TP=-1:LRA=11:print_format=json" -f null /dev/null 2>&1)
IL=$(echo "$P1"     | grep '"input_i"'      | grep -o '[0-9.-]*' | head -1)
ITP=$(echo "$P1"    | grep '"input_tp"'     | grep -o '[0-9.-]*' | head -1)
ILRA=$(echo "$P1"   | grep '"input_lra"'    | grep -o '[0-9.-]*' | head -1)
ITHRESH=$(echo "$P1"| grep '"input_thresh"' | grep -o '[0-9.-]*' | head -1)
OFFSET=$(echo "$P1" | grep '"target_offset"'| grep -o '[0-9.-]*' | head -1)

# Pass 2
ffmpeg -y -i "$FILE" \
  -af "loudnorm=I=${TARGET}:TP=-1:LRA=11:measured_I=${IL}:measured_TP=${ITP}:measured_LRA=${ILRA}:measured_thresh=${ITHRESH}:offset=${OFFSET}:linear=true" \
  -codec:a libmp3lame -qscale:a 2 "$TMPFILE" && mv "$TMPFILE" "$FILE"
```

Batch loudnorm for all real music files (excludes song3):
```bash
TARGET=-11
for FILE in /Users/mike/Documents/work/pinball/happy-pinball/sounds/music/song1.mp3 \
            /Users/mike/Documents/work/pinball/happy-pinball/sounds/music/song2.mp3 \
            /Users/mike/Documents/work/pinball/happy-pinball/sounds/music/c-love.mp3; do
  TMPFILE="${FILE%.mp3}_tmp.mp3"
  P1=$(ffmpeg -i "$FILE" -af "loudnorm=I=${TARGET}:TP=-1:LRA=11:print_format=json" -f null /dev/null 2>&1)
  IL=$(echo "$P1"     | grep '"input_i"'      | grep -o '[0-9.-]*' | head -1)
  ITP=$(echo "$P1"    | grep '"input_tp"'     | grep -o '[0-9.-]*' | head -1)
  ILRA=$(echo "$P1"   | grep '"input_lra"'    | grep -o '[0-9.-]*' | head -1)
  ITHRESH=$(echo "$P1"| grep '"input_thresh"' | grep -o '[0-9.-]*' | head -1)
  OFFSET=$(echo "$P1" | grep '"target_offset"'| grep -o '[0-9.-]*' | head -1)
  ffmpeg -y -i "$FILE" \
    -af "loudnorm=I=${TARGET}:TP=-1:LRA=11:measured_I=${IL}:measured_TP=${ITP}:measured_LRA=${ILRA}:measured_thresh=${ITHRESH}:offset=${OFFSET}:linear=true" \
    -codec:a libmp3lame -qscale:a 2 "$TMPFILE" && mv "$TMPFILE" "$FILE"
  echo "Done: $(basename $FILE)"
done
```

---

## Step 3b: Fixed-dB boost/cut — for short or dynamic tracks

Use for: files under ~1s, or highly dynamic music where loudnorm causes artifacts.

If file has headroom (max < -1 dB): simple boost is safe.
If file is already at 0 dB max: add a limiter to prevent clipping.

```bash
# Simple cut (safe when reducing volume)
FILE=/Users/mike/Documents/work/pinball/happy-pinball/sounds/effects/bumper_left.mp3
DB=-3  # negative = cut, positive = boost
TMPFILE="${FILE%.mp3}_tmp.mp3"
ffmpeg -y -i "$FILE" -af "volume=${DB}dB" -codec:a libmp3lame -qscale:a 2 "$TMPFILE" && mv "$TMPFILE" "$FILE"

# Boost with limiter (when file is near 0 dB max and needs boosting)
FILE=/Users/mike/Documents/work/pinball/happy-pinball/sounds/effects/bumper_right.mp3
DB=6
TMPFILE="${FILE%.mp3}_tmp.mp3"
ffmpeg -y -i "$FILE" -af "volume=${DB}dB,alimiter=level_in=1:level_out=1:limit=0.9:attack=5:release=50" \
  -codec:a libmp3lame -qscale:a 2 "$TMPFILE" && mv "$TMPFILE" "$FILE"

# Restore from backup then apply fixed boost (for tracks where loudnorm caused artifacts)
BACKUP=/Users/mike/Documents/work/pinball/backup/sounds-2026-08-26
cp "$BACKUP/music/slick-rick-lick.mp3" /Users/mike/Documents/work/pinball/happy-pinball/sounds/music/slick-rick-lick.mp3
# Then apply fixed-dB boost if needed (check level first — original may already be in range)
```

---

## Step 4: Backup before bulk changes

Always back up before a normalization pass:
```bash
DATE=$(date +%Y-%m-%d)
cp -r /Users/mike/Documents/work/pinball/happy-pinball/sounds/ \
      /Users/mike/Documents/work/pinball/backup/sounds-${DATE}/
```

Existing backup: `/Users/mike/Documents/work/pinball/backup/sounds-2026-08-26/`

---

## Step 5: Commit and push

```bash
cd /Users/mike/Documents/work/pinball/happy-pinball
git add sounds/
git commit -m "Adjust audio levels: <describe what changed>"
git push
```

The machine pulls on next boot (pinball.service ExecStartPre) and Godot reimports changed MP3s on startup.

---

## Reference: baseline levels after 2026-08-26 normalization pass

Music (~-14 dB mean target):
- song1.mp3: -13.8 dB mean
- song2.mp3: -14.0 dB mean
- slick-rick-lick.mp3: -14.4 dB mean (restored original — no loudnorm)
- c-love.mp3: -13.9 dB mean
- song3.mp3: -27.5 dB mean (placeholder, ignored)

Effects:
- bumper_left.mp3: -12.6 dB mean
- ball_ended.mp3: -14.1 dB mean
- bumper_bottom.mp3: -15.9 dB mean
- plunger.mp3: -15.7 dB mean
- entrance.mp3: -18.1 dB mean
- bumper_right.mp3: -17.7 dB mean
