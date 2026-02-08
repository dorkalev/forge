---
description: Generate PDF, MP3 podcast, and MP4 video from markdown or ticket diffs
---
# /release-media - Generate Release Media

Generates PDF, MP3, MP4 from markdown files or ticket diffs.

**Prerequisites**: `pandoc`, `mmdc` (mermaid-cli), `ffmpeg`, Google Chrome, `gcloud` (authenticated).

```
/release-media <markdown-file> [options]
/release-media --tickets BOL-123,BOL-456 [options]
```

**Options**: `--title "Title"`, `--image <path>` (for MP4), `--audio-only`, `--pdf-only`, `--voice <voice-id>` (default: en-US-Journey-D), `--output-dir <path>`, `--base <branch>` (default: staging), `--folders <paths>`

## Ticket Mode (--tickets)

**T1** Resolve branches: `git branch -a | grep -i "BOL-123"` or Linear MCP.
**T2** Get diff: `git diff $BASE...$TICKET_BRANCH --stat -- $FOLDERS`
**T3** Analyze changes using Task/Explore agent: components changed, product impact, new data models, new APIs, infrastructure changes.
**T4** Generate markdown with: Title/Overview, Architecture Diagrams (Mermaid), Data Model Diagrams (Mermaid ERD), Component Diagrams (Mermaid flowchart), Product Description (6-8 paragraphs, audio-friendly: no "click here"/"see below", spell out acronyms, avoid jargon, focus on user value).
**T5** Continue to PDF/Audio/Video generation below.

## File Mode / Generation

### Step 1: Check Prerequisites
```bash
which pandoc mmdc ffmpeg || echo "missing tools"
# Install: brew install pandoc ffmpeg && npm install -g @mermaid-js/mermaid-cli
```

### Step 2: Generate PDF
```bash
mmdc -i "$INPUT_FILE" -o "temp-rendered.md" -e png
pandoc "temp-rendered.md" -o "temp.html" --standalone --metadata title="$TITLE"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --print-to-pdf="output.pdf" "temp.html"
```

### Step 3: Generate MP3 (if not --pdf-only)
Extract text (remove code blocks, Mermaid, markdown formatting, visual instructions). Prepare audio-friendly script (expand abbreviations, add natural pauses).

Call Google Cloud TTS:
```python
import base64, json, subprocess
token = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()
project = subprocess.check_output(["gcloud", "config", "get-value", "project"], text=True).strip()
request = {
    "input": {"text": SCRIPT},
    "voice": {"languageCode": "en-US", "name": VOICE},
    "audioConfig": {"audioEncoding": "MP3", "speakingRate": 0.95}
}
result = subprocess.run([
    "curl", "-s", "-X", "POST",
    "-H", f"Authorization: Bearer {token}",
    "-H", "Content-Type: application/json",
    "-H", f"x-goog-user-project: {project}",
    "-d", json.dumps(request),
    "https://texttospeech.googleapis.com/v1/text:synthesize"
], capture_output=True, text=True)
audio = base64.b64decode(json.loads(result.stdout)["audioContent"])
with open("output.mp3", "wb") as f:
    f.write(audio)
```
Enable API if needed: `gcloud services enable texttospeech.googleapis.com`

### Step 4: Generate MP4 (if --image provided)
```bash
ffmpeg -y -loop 1 -i "$IMAGE" -i "output.mp3" \
  -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
  -pix_fmt yuv420p -shortest "output.mp4"
```

### Step 5: Cleanup
```bash
rm -f temp-rendered.md temp.html *-1.png *-2.png *-3.png *-4.png *-5.png *-6.png
```

Report generated files with sizes and durations.

## Popular Voices
`en-US-Journey-D` (male, default), `en-US-Journey-F` (female), `en-US-Neural2-D`/`F`, `en-GB-Neural2-B` (British), `en-AU-Neural2-B` (Australian)
