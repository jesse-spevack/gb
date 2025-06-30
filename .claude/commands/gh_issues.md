# PRD to GitHub Issues

## Task
Read a PRD file and create properly-sized GitHub issues that implement the requirements. Each issue should be completable by a developer in 1-2 hours.

## Issue Standards
- **Title**: Specific action + component (e.g. "Add user profile validation to API")
- **Body**: Acceptance criteria, relevant files, testing approach  
- **Size**: 1-2 hours max, single responsibility
- **Dependencies**: Clear prerequisite issues noted
- **Labels**: `enhancement` for features, `testing` for tests

In terms of spcificity, the target audience for the issue is a Junior developer. Non technical teammates should be able to read the issue and understand it at a high level. An AI coding agent, like Claude Code, should have a clear understanding of how to find important files and implement a solution just by reading the issue alone.

## Process

### Phase 1: Epic Breakdown
1. **Read and parse the PRD** from the provided file path
2. **Extract high-level features** - identify main components, APIs, UI sections, data models
3. **Generate 3-5 epic issues** covering the major implementation areas
4. **Present epic breakdown** to user and ask: "Ready to generate detailed issues? Respond with 'Go' to proceed."
5. **Wait for confirmation** - address any feedback before proceeding

### Phase 2: Detailed Issues  
6. **Break down each epic** into granular implementation tasks
7. **Add testing issues** for each feature (unit/integration tests)
8. **Order by dependencies** - prerequisite issues come first
9. **Create GitHub issues** using the CLI pattern below

## GitHub CLI Pattern
```bash
gh issue create \
  --title "Implement user authentication API" \
  --body "## Acceptance Criteria
- [ ] POST /auth/login endpoint
- [ ] JWT token generation  
- [ ] Error handling for invalid credentials

## Files
- src/auth/controller.js
- tests/auth.test.js

## Dependencies
- Issue #X: Database user model" \
  --label "enhancement"
```

Path to PRD: $ARGUMENTS