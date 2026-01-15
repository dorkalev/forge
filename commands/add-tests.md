---
description: Generate unit and integration tests for changed code
---

# /add-tests - Generate Test Coverage

You are a test engineering specialist focused on generating comprehensive test coverage.

**Goal**: Heavy test coverage without browser-based tests.

## Usage

```
/add-tests
```

Run this to generate tests for your current changes. Called automatically by `/forge:finish`.

## Step 1: Detect Project Test Patterns

```bash
# Find existing test files to understand conventions
find . -name "*_test.py" -o -name "test_*.py" -o -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | head -20

# Check test framework in use
grep -l "pytest\|unittest\|jest\|vitest\|mocha" package.json pyproject.toml setup.py 2>/dev/null
```

Read 2-3 existing test files to understand:
- Test file location pattern (e.g., `tests/`, `__tests__/`, co-located)
- Naming conventions
- Fixture/mock patterns
- Assertion style

## Step 2: Identify What Needs Tests

Analyze the changes since `staging`:

```bash
git diff staging...HEAD --name-only
git diff --name-only
git diff --cached --name-only
```

Categorize changes:

| Type | What to Test | Priority |
|------|--------------|----------|
| **New functions/methods** | Unit tests for each public function | High |
| **API endpoints** | Integration tests with test client | High |
| **Data pipelines** | Integration tests with sample data | High |
| **Config/env changes** | Validation tests | Medium |
| **Bug fixes** | Regression test proving the fix | High |
| **Refactors** | Ensure existing tests still pass | N/A |

## Step 3: Determine Test Types

**Unit Tests** (always):
- Test individual functions in isolation
- Mock external dependencies (APIs, databases, cloud services)
- Cover happy path + edge cases + error cases
- Aim for high coverage of new/changed code

**Integration Tests** (for pipelines/services):
- Test full pipeline flows without browser
- Use real (test) database connections where possible
- Test Cloud Run services with test HTTP client
- Test BigQuery operations against test dataset
- Test pub/sub message flows end-to-end

**What NOT to generate**:
- Browser-based e2e tests (Playwright, Cypress, Selenium)
- UI screenshot tests
- Manual QA scripts

## Step 4: Generate Tests

For each untested change:

1. Create test file following project conventions
2. Write tests covering:
   - Normal operation (happy path)
   - Edge cases (empty input, large input, boundary values)
   - Error handling (invalid input, service failures, timeouts)
3. Use descriptive test names: `test_<function>_<scenario>_<expected_result>`

Example structure:
```python
class TestFeatureName:
    """Tests for [feature-name] functionality."""

    def test_happy_path(self):
        """Should [expected behavior] when [condition]."""

    def test_edge_case_empty_input(self):
        """Should handle empty input gracefully."""

    def test_error_handling(self):
        """Should raise [Error] when [condition]."""
```

## Step 5: Run and Verify

```bash
# Run tests (detect runner from project)
pytest tests/ -v --tb=short
# or
npm test
# or
go test ./...
```

- All new tests must pass
- Existing tests must not break
- If tests fail, fix the code or tests before proceeding

## Step 6: Commit Tests

```bash
git add -A
git commit -m "test: add coverage for [feature-name]

- Unit tests for [components]
- Integration tests for [pipelines/services]
- Covers [X] new functions/endpoints"
```

## Output

Report what was generated:

```
## Tests Added

| File | Tests | Coverage |
|------|-------|----------|
| tests/test_feature.py | 5 | new_function, edge_cases, errors |
| tests/integration/test_pipeline.py | 3 | full flow, error handling |

All tests passing.
```

## Error Handling

- **No changes detected**: Report "No new code to test"
- **Tests fail**: Fix and retry, or report failures for user to address
- **Can't detect test framework**: Ask user which framework to use
