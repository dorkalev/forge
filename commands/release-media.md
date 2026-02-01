---
description: Generate PDF, MP3 podcast, and MP4 video from a markdown file with Mermaid diagrams
---

# /release-media - Generate Release Media

Converts a markdown file with Mermaid diagrams into shareable media formats: PDF, MP3 audio narration, and MP4 video.

## Prerequisites

The following tools must be installed (command will check and prompt to install if missing):
- `pandoc` - Markdown to HTML conversion
- `mmdc` (mermaid-cli) - Mermaid diagram rendering
- `ffmpeg` - Video generation
- Google Chrome - PDF generation via headless mode
- `gcloud` - Google Cloud TTS for audio (must be authenticated)

## Usage

```
/release-media <markdown-file> [options]
```

### Options

- `--title "Title"` - Document title for PDF (default: filename)
- `--image <path>` - Image for MP4 video background (required for video)
- `--audio-only` - Generate only MP3, skip PDF and MP4
- `--pdf-only` - Generate only PDF, skip audio and video
- `--voice <voice-id>` - Google TTS voice (default: en-US-Journey-D)
- `--output-dir <path>` - Output directory (default: same as input file)

## Your Mission

When the user runs `/release-media`, follow these steps:

### Step 1: Check Prerequisites

```bash
which pandoc mmdc ffmpeg || echo "missing tools"
```

If tools are missing, offer to install:
```bash
brew install pandoc ffmpeg
npm install -g @mermaid-js/mermaid-cli
```

### Step 2: Parse Arguments

Extract from user input:
- `INPUT_FILE` - The markdown file path
- `TITLE` - Document title (from --title or filename)
- `IMAGE` - Background image for video (from --image)
- `OUTPUT_DIR` - Output directory

### Step 3: Generate PDF

1. Render Mermaid diagrams to PNG:
```bash
mmdc -i "$INPUT_FILE" -o "$OUTPUT_DIR/temp-rendered.md" -e png
```

2. Convert to HTML with title:
```bash
pandoc "$OUTPUT_DIR/temp-rendered.md" -o "$OUTPUT_DIR/temp.html" --standalone --metadata title="$TITLE"
```

3. Print to PDF via Chrome headless:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --print-to-pdf="$OUTPUT_DIR/output.pdf" "$OUTPUT_DIR/temp.html"
```

### Step 4: Generate MP3 Audio (if not --pdf-only)

1. Extract text content from markdown, removing:
   - Code blocks (```...```)
   - Mermaid diagrams
   - Markdown formatting (links, images, tables)
   - Visual instructions ("click here", "see below", etc.)

2. Prepare audio-friendly script:
   - Replace acronyms with spoken versions (e.g., "API" → "A P I")
   - Expand abbreviations
   - Add natural pauses between sections

3. Call Google Cloud TTS:
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
with open(OUTPUT_MP3, "wb") as f:
    f.write(audio)
```

**Important**: The Google Cloud Text-to-Speech API must be enabled:
```bash
gcloud services enable texttospeech.googleapis.com
```

### Step 5: Generate MP4 Video (if --image provided)

Combine static image with audio:
```bash
ffmpeg -y -loop 1 -i "$IMAGE" -i "$OUTPUT_MP3" \
  -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
  -pix_fmt yuv420p -shortest "$OUTPUT_DIR/output.mp4"
```

### Step 6: Cleanup

Remove temporary files:
```bash
rm -f "$OUTPUT_DIR/temp-rendered.md" "$OUTPUT_DIR/temp.html" "$OUTPUT_DIR"/*.png
```

## Output Format

```
Generated release media:
  PDF:   /path/to/output.pdf (XXX KB)
  MP3:   /path/to/output.mp3 (XXX KB, X:XX duration)
  MP4:   /path/to/output.mp4 (X.X MB, X:XX duration)
```

## Examples

Generate all formats:
```
/release-media docs/release-notes.md --title "January Release" --image assets/og-image.png
```

PDF only:
```
/release-media docs/architecture.md --pdf-only --title "System Architecture"
```

Audio podcast only:
```
/release-media docs/changelog.md --audio-only --voice en-US-Journey-F
```

## Available Voices

Popular Google Cloud TTS voices:
- `en-US-Journey-D` - Male, natural conversational (default)
- `en-US-Journey-F` - Female, natural conversational
- `en-US-Neural2-D` - Male, neural
- `en-US-Neural2-F` - Female, neural
- `en-GB-Neural2-B` - British male
- `en-AU-Neural2-B` - Australian male

## Notes

- Mermaid diagrams are rendered as PNG images in the PDF
- Audio script is automatically cleaned for spoken narration
- MP4 uses H.264 encoding for broad compatibility
- All outputs are placed in the same directory as the input file unless --output-dir is specified
