---
description: Generate PDF, MP3 podcast, and MP4 video from markdown or ticket diffs
---

# /release-media - Generate Release Media

Generates shareable release media (PDF, MP3, MP4) from either:
1. An existing markdown file with Mermaid diagrams
2. Ticket numbers (auto-generates content from git diff)

## Prerequisites

The following tools must be installed (command will check and prompt to install if missing):
- `pandoc` - Markdown to HTML conversion
- `mmdc` (mermaid-cli) - Mermaid diagram rendering
- `ffmpeg` - Video generation
- Google Chrome - PDF generation via headless mode
- `gcloud` - Google Cloud TTS for audio (must be authenticated)

## Usage

### Mode 1: From Markdown File
```
/release-media <markdown-file> [options]
```

### Mode 2: From Ticket Numbers
```
/release-media --tickets BOL-123,BOL-456 [options]
/release-media --tickets BOL-123 --base main [options]
```

### Options

- `--title "Title"` - Document title for PDF (default: filename or "Release Notes")
- `--image <path>` - Image for MP4 video background (required for video)
- `--audio-only` - Generate only MP3, skip PDF and MP4
- `--pdf-only` - Generate only PDF, skip audio and video
- `--voice <voice-id>` - Google TTS voice (default: en-US-Journey-D)
- `--output-dir <path>` - Output directory (default: current directory)
- `--tickets <ids>` - Comma-separated ticket IDs (e.g., BOL-123,BOL-456)
- `--base <branch>` - Base branch to diff against (default: staging, or main)
- `--folders <paths>` - Limit diff to specific folders (e.g., web/,vlad/,infra/)

## Your Mission

When the user runs `/release-media`, follow these steps:

### Step 0: Determine Mode

Check if `--tickets` is provided:
- If yes: Use **Ticket Mode** (generate content from diff)
- If no: Use **File Mode** (convert existing markdown)

---

## Ticket Mode: Generate from Git Diff

### Step T1: Resolve Ticket Branches

For each ticket ID, find the associated branch:

```bash
# Option 1: Check for branch matching ticket pattern
git branch -a | grep -i "BOL-123"

# Option 2: Use Linear API to get branch name
# (via MCP Linear tools if available)
```

Common branch patterns:
- `BOL-123-feature-name`
- `feature/BOL-123-name`
- `bol-123-name`

### Step T2: Get Diff Stats

```bash
# Diff ticket branch against base
git diff $BASE...$TICKET_BRANCH --stat -- $FOLDERS

# Get changed files
git diff $BASE...$TICKET_BRANCH --name-only -- $FOLDERS
```

### Step T3: Analyze Changes

Use the Task tool with Explore agent to understand the changes:

1. **What components changed?** (folders, modules, services)
2. **What's the product impact?** (new features, fixes, improvements)
3. **Are there new data models?** (database tables, schemas)
4. **Are there new APIs or routes?**
5. **Are there infrastructure changes?**

### Step T4: Generate Markdown Document

Create a markdown file with:

1. **Title and Overview** - What this release brings
2. **Architecture Diagrams** (Mermaid) - System overview, data flow
3. **Data Model Diagrams** (Mermaid ERD) - New/changed tables
4. **Component Diagrams** (Mermaid flowchart) - How pieces connect
5. **Product Description** - 6-8 paragraphs explaining changes from user perspective

**Important for audio generation:**
- Write descriptions that make sense when spoken (no "click here", "see below")
- Spell out acronyms that should be pronounced (e.g., "Bolt X" not "BOLTX")
- Avoid technical jargon in product descriptions
- Focus on user value, not implementation details

### Step T5: Continue to PDF/Audio/Video Generation

Proceed to Step 1 below with the generated markdown.

---

## File Mode: Convert Existing Markdown

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
cd "$OUTPUT_DIR"
mmdc -i "$INPUT_FILE" -o "temp-rendered.md" -e png
```

2. Convert to HTML with title:
```bash
pandoc "temp-rendered.md" -o "temp.html" --standalone --metadata title="$TITLE"
```

3. Print to PDF via Chrome headless:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --print-to-pdf="output.pdf" "temp.html"
```

### Step 4: Generate MP3 Audio (if not --pdf-only)

1. Extract text content from markdown, removing:
   - Code blocks (```...```)
   - Mermaid diagrams
   - Markdown formatting (links, images, tables)
   - Visual instructions ("click here", "see below", etc.)

2. Prepare audio-friendly script:
   - Replace brand names with spoken versions
   - Expand abbreviations naturally
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
with open("output.mp3", "wb") as f:
    f.write(audio)
```

**Important**: The Google Cloud Text-to-Speech API must be enabled:
```bash
gcloud services enable texttospeech.googleapis.com
```

### Step 5: Generate MP4 Video (if --image provided)

Combine static image with audio:
```bash
ffmpeg -y -loop 1 -i "$IMAGE" -i "output.mp3" \
  -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
  -pix_fmt yuv420p -shortest "output.mp4"
```

### Step 6: Cleanup

Remove temporary files:
```bash
rm -f temp-rendered.md temp.html *-1.png *-2.png *-3.png *-4.png *-5.png *-6.png
```

## Output Format

```
Generated release media:
  PDF:   /path/to/output.pdf (XXX KB)
  MP3:   /path/to/output.mp3 (XXX KB, X:XX duration)
  MP4:   /path/to/output.mp4 (X.X MB, X:XX duration)
```

## Examples

### From Tickets
```
/release-media --tickets BOL-396 --title "January Release" --image web/static/og-image.png
```

```
/release-media --tickets BOL-123,BOL-124,BOL-125 --base main --folders web/,api/
```

### From Existing Markdown
```
/release-media docs/release-notes.md --title "January Release" --image assets/og-image.png
```

```
/release-media docs/architecture.md --pdf-only --title "System Architecture"
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
- Ticket mode uses git branch naming conventions to find branches
- Product descriptions should focus on user value, not technical details
- When generating from tickets, explore the codebase to understand changes before writing descriptions
