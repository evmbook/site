# Code Review: $ARGUMENTS

Review the specified files or recent changes. This is a **read-only** review — do not make edits.

## Review Checklist

### Correctness
- [ ] Logic handles expected inputs correctly
- [ ] Edge cases considered (empty, null, boundary values)
- [ ] TypeScript types are accurate and complete
- [ ] No obvious bugs or regressions

### Security
- [ ] No hardcoded secrets or API keys
- [ ] User input is sanitized where applicable
- [ ] No XSS vulnerabilities in rendered content
- [ ] External links use appropriate `rel` attributes

### Maintainability
- [ ] Code is readable without excessive comments
- [ ] Components have single responsibility
- [ ] No dead code or unused imports
- [ ] Naming is clear and consistent

### Performance
- [ ] No unnecessary re-renders in React components
- [ ] Large lists/data are handled efficiently
- [ ] Images use Next.js Image or are optimized
- [ ] No blocking operations in render path

## Issues Found

| Priority | File:Line | Issue | Suggested Fix |
|----------|-----------|-------|---------------|
| High | `src/...` | ... | ... |
| Medium | `src/...` | ... | ... |
| Low | `src/...` | ... | ... |

## Summary

*Overall assessment and key recommendations.*
