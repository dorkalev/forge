---
description: Fix CodeRabbit findings from GitHub PR
---

# /fix-pr - Fix CodeRabbit Findings

You are an automated CodeRabbit Fixer. Your mission is to fetch CodeRabbit review comments from the GitHub PR and fix Major/Critical issues.

**Prerequisites**:
- GitHub API access (token in `.forge` file)
- CodeRabbit enabled on repository (GitHub app)

## Usage

```
/fix-pr
```

## Workflow

### Phase 1: Setup

1. Get current branch: `git branch --show-current`
2. Find the PR using GitHub API:
   ```bash
   curl -s -H "Authorization: token $GITHUB_TOKEN" \
     "https://api.github.com/repos/{owner}/{repo}/pulls?head={owner}:{branch}&base=staging"
   ```
3. Extract PR number and URL

### Phase 2: Fetch CodeRabbit Comments

Fetch all review comments from the PR:

```bash
# Get inline review comments
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/pulls/{pr-number}/comments"

# Get issue comments (main thread)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/issues/{pr-number}/comments"
```

Filter for comments from `coderabbitai[bot]`.

**Severity markers:**
- **Critical**: `_Critical_` or `**Critical**` - MUST fix
- **Major**: `_Major_` or `**Major**` or `Potential issue` - MUST fix
- **Minor**: `_Minor_` - skip
- **Trivial**: `_Trivial_` or `Nitpick` - skip

If no Major/Critical issues found, report success and exit.

### Phase 3: Fix CodeRabbit Issues

**IMPORTANT: Show detailed explanations for each fix to the developer.**

For each Major/Critical issue, display a clear summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 CRITICAL: {short title from CodeRabbit}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 File: {file}:{line}

🔍 Problem:
   {Explain what CodeRabbit found - in plain language}

💡 Root Cause:
   {Why this is happening - explain the underlying issue}

✅ Fix Applied:
   {Describe the exact change being made}

📝 Code Change:
   Before: {old code snippet}
   After:  {new code snippet}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then:
1. Read the affected file at the specified line
2. Understand the problem from CodeRabbit's description
3. Apply the fix
4. Verify syntax is correct

**For design questions** ("confirm whether", "is this acceptable", "consider whether"):
Ask the user:
```
CodeRabbit asks: {description}
File: {file}:{line}

Options:
[A] Acknowledge (keep as-is, reply explaining why)
[F] Fix it (apply the suggestion)
[S] Skip (don't reply)
```

### Phase 4: Commit and Push

```bash
git add -A
git commit -m "fix: address CodeRabbit findings

- [list each fix applied]"
git push
```

### Phase 5: Reply to Comments

For each fixed issue, reply to the CodeRabbit comment:

```bash
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/{owner}/{repo}/pulls/{pr-number}/comments/{commentId}/replies" \
  -d '{"body": "Fixed in commit {hash}"}'
```

For acknowledged (kept as-is) issues, reply with the explanation.

### Phase 5.5: Resolve Review Threads

After replying, resolve/fold the review threads using GraphQL:

1. First, get all review thread IDs and their resolution status:
```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {pr-number}) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { path }
          }
        }
      }
    }
  }
}'
```

2. For each unresolved thread that was addressed, resolve it:
```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "{thread-id}"}) {
    thread { isResolved }
  }
}'
```

Note: CodeRabbit often auto-resolves threads when it detects fixes, but this ensures all addressed threads are collapsed.

### Phase 6: Wait for CodeRabbit to Finish

**Don't use a static sleep!** Instead, poll until CodeRabbit finishes processing:

1. Check if CodeRabbit is still processing by looking for the "processing" indicator in PR comments:
```bash
gh pr view {pr-number} --repo {owner}/{repo} --json comments \
  --jq '.comments | map(select(.author.login == "coderabbitai")) | .[-1].body' \
  | grep -q "Currently processing"
```

2. **Polling loop** (repeat every 30 seconds, max 10 minutes):
```bash
MAX_WAIT=600  # 10 minutes
INTERVAL=30
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  # Check latest CodeRabbit comment
  LATEST=$(gh pr view {pr-number} --json comments \
    --jq '.comments | map(select(.author.login == "coderabbitai")) | .[-1].body')

  # If NOT processing, CodeRabbit is done
  if ! echo "$LATEST" | grep -q "Currently processing"; then
    echo "CodeRabbit finished reviewing"
    break
  fi

  echo "CodeRabbit still processing... waiting ${INTERVAL}s"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
```

3. Once CodeRabbit finishes, re-fetch comments and check for new Major/Critical issues.

4. **Repeat the entire workflow** if new Critical/Major issues are found.

**Important**: If CodeRabbit finds new issues after your fixes, you must address those too. Keep looping until no new Critical/Major issues appear.

---

## Summary Flow

```
/fix-pr
   │
   ├─► Fetch CodeRabbit comments from GitHub PR
   │
   ├─► Filter for Major/Critical severity
   │
   ├─► Fix each issue
   │
   ├─► Commit, push, reply to comments
   │
   ├─► Resolve/fold addressed review threads
   │
   └─► Wait for re-review, repeat if new issues
```

## Stopping

The loop stops when:
- No Major/Critical CodeRabbit issues remain
- User types "stop" or Ctrl+C
- GitHub API errors after 3 retries

## Example Session

```
Starting CodeRabbit fix loop for PR #44

[Iteration 1]
Fetching CodeRabbit comments...
Found 4 comments (2 Major, 1 Critical, 1 Minor)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 CRITICAL: XSS vulnerability in innerHTML assignment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 File: src/components/UserCard.tsx:45

🔍 Problem:
   Using innerHTML with user-provided content allows attackers to inject
   malicious scripts that execute in users' browsers.

💡 Root Cause:
   The username is fetched from an API and directly inserted via innerHTML
   without sanitization. If an attacker sets their username to contain
   <script> tags, it will execute.

✅ Fix Applied:
   Changed from innerHTML to textContent which treats input as plain text,
   preventing any HTML/script execution.

📝 Code Change:
   Before: element.innerHTML = user.name
   After:  element.textContent = user.name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟠 MAJOR: Missing null check causes runtime crash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 File: src/api/client.ts:128

🔍 Problem:
   Accessing response.data.user.id without null checks will throw
   "Cannot read property 'id' of undefined" when user is missing.

💡 Root Cause:
   The API can return null for user when the session expires, but the code
   assumes user always exists.

✅ Fix Applied:
   Added optional chaining (?.) to safely access nested properties.

📝 Code Change:
   Before: const userId = response.data.user.id
   After:  const userId = response.data?.user?.id
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... more issues ...]

Committed: abc1234
Replied to 3 comments.
Resolved 3 review threads.

Polling for CodeRabbit re-review...
  CodeRabbit still processing... waiting 30s
  CodeRabbit still processing... waiting 30s
  CodeRabbit finished reviewing

[Iteration 2]
Fetching CodeRabbit comments...
No new Major/Critical issues.

✅ CodeRabbit review complete! All Critical/Major issues addressed.
```

## Error Handling

- **API rate limit**: Wait 60s and retry
- **File not found**: Skip issue, report, continue
- **Git conflict**: Stop, await user instruction
- **Network error**: Retry 3x, then stop
- **CodeRabbit timeout** (10+ min): Report timeout, ask user if they want to continue waiting or proceed
- **CodeRabbit not responding**: Check if CodeRabbit app is enabled on repo
