# Git
This project uses git for version control and github for code hosting.

## Branching
- Branches are named descriptively and use snake_case.
- Branches are prefixed with the type of change (feature, bugfix, etc.)

**Examples**
- feature/gradebot-rubric-generation
- bugfix/gradebot-feedback-display
- test/gradebot-rubric-generation
- chore/gradebot-chore

## Commit Messages
- Commit messages are to be used as the title of PRs
- Commit messages are to be used as the title of changelogs
- When appropriate, they should reference task ids

**Examples**
- FEATURE #123 Add login with Google
- FIX #123 Fix login with Google
- TEST #123 Add login with Google tests
- CHORE #123 Add login with Google chore

## Pull Requests
- When creating a pull request, use this template in the PR description:

```markdown
# Description
Description of the changes made in github friendly markdown.

# Task
Task ID number

# Testing
Description of tests run to verify the changes.
```
