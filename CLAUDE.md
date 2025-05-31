# Claude Code Instructions

## Pre-commit Requirements

**IMPORTANT**: Always run `bin/check` before committing any changes. Only commit when `bin/check` returns all green (passes all checks).

### What `bin/check` does:
1. **Brakeman security checks** - Scans for security vulnerabilities
2. **Rubocop with auto-correct** - Enforces Ruby style guide and auto-fixes issues
3. **Rails tests** - Runs the full test suite

### Usage:
```bash
bin/check
```

If any check fails, fix the issues before attempting to commit.

## Project-Specific Guidelines

### Code Style
- Follow Ruby style guide enforced by Rubocop
- Use proper indentation (2 spaces)
- Keep methods focused and single-purpose
- Add meaningful test coverage for new features

### Testing
- Write tests for all new functionality
- Ensure existing tests continue to pass
- Use meaningful test descriptions

### Security
- Never commit sensitive information (keys, passwords, etc.)
- Follow security best practices identified by Brakeman