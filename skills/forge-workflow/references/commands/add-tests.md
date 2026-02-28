---
description: Generate unit and integration tests for changed code
---
# /add-tests - Generate Test Coverage

Heavy test coverage without browser-based tests. Called automatically by `/forge:finish`.

## Step 1: Detect Project Test Patterns
```bash
find . -name "*_test.py" -o -name "test_*.py" -o -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | head -20
grep -l "pytest\|unittest\|jest\|vitest\|mocha" package.json pyproject.toml setup.py 2>/dev/null
```
Read 2-3 existing tests to learn: file location, naming conventions, fixture/mock patterns, assertion style.

## Step 2: Identify What Needs Tests
```bash
git diff staging...HEAD --name-only
git diff --name-only
git diff --cached --name-only
```

| Type | Test | Priority |
|------|------|----------|
| New functions/methods | Unit tests per public function | High |
| API endpoints | Integration with test client | High |
| Data pipelines | Integration with sample data | High |
| Config/env changes | Validation tests | Medium |
| Bug fixes | Regression test proving fix | High |

## Step 3: Generate Tests

**Unit**: Individual functions in isolation, mock external deps, happy path + edge cases + error cases.
**Integration**: Full pipeline flows (no browser), real test DB where possible, test HTTP client for services.
**NOT**: Browser e2e (Playwright/Cypress/Selenium), UI screenshots, manual QA.

Use descriptive names: `test_<function>_<scenario>_<expected_result>`

## Step 4: Run and Verify
```bash
pytest tests/ -v --tb=short  # or: npm test / go test ./...
```
All new tests must pass. Existing tests must not break. Fix before proceeding.

## Step 5: Commit
```bash
git add -A
git commit -m "test: add coverage for [feature-name]

- Unit tests for [components]
- Integration tests for [pipelines/services]
- Covers [X] new functions/endpoints"
```

## Output
Report: `| File | Tests | Coverage |` table. All tests passing status.

## Error Handling
- No changes detected → "No new code to test" | Tests fail → fix and retry | Can't detect framework → ask user
