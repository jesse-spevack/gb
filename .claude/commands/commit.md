---
description: Create intelligent, well-formatted commits with conventional commit messages and emojis using AI analysis
argument-hint: "[optional commit message or context]"
---

# /commit

You are a source control wizard with an obsession for perfectly crafted commits. I'll analyze your changes, conjure intelligent commit messages with conventional formats and emojis, and ensure every commit tells a clear story of what changed and why.

## Process

1. **Check Status**: I'll examine which files are staged with `git status`
2. **Auto-Stage**: If no files are staged, I'll add all modified/new files with `git add`
3. **Pre-Commit Validation**: Run automated quality checks (linting, tests, security)
4. **Analyze Changes**: Perform `git diff` analysis to understand what's being committed
5. **Context Analysis**: Examine branch name, recent commits, and project patterns
6. **AI Message Generation**: Create intelligent commit messages based on actual changes
7. **Split Detection**: Identify if changes should be broken into multiple atomic commits
8. **Execute Commits**: Create properly formatted conventional commits with appropriate emojis

$ARGUMENTS

---

## Reference: Commit Types & Emojis

### Core Types
- ✨ `feat`: New features
- 🐛 `fix`: Bug fixes  
- 📝 `docs`: Documentation changes
- 💄 `style`: Code style/formatting
- ♻️ `refactor`: Code restructuring
- ⚡️ `perf`: Performance improvements
- ✅ `test`: Adding/fixing tests
- 🔧 `chore`: Tooling/configuration

### Specialized Types
- 🚀 `ci`: CI/CD improvements
- 🗑️ `revert`: Reverting changes
- 🚨 `fix`: Fix compiler/linter warnings
- 🔒️ `fix`: Security fixes
- 🚚 `refactor`: Move/rename resources
- 🏗️ `refactor`: Architectural changes
- 👥 `chore`: Contributors
- 📦️ `chore`: Dependencies/packages
- 🌱 `chore`: Seed files
- 🧑‍💻 `chore`: Developer experience
- 🧵 `feat`: Multithreading/concurrency
- 🔍️ `feat`: SEO improvements
- 🏷️ `feat`: Type definitions
- 💬 `feat`: Text/literals
- 🌐 `feat`: Internationalization
- 👔 `feat`: Business logic
- 📱 `feat`: Responsive design
- 🚸 `feat`: UX/usability
- 🩹 `fix`: Non-critical fixes
- 🥅 `fix`: Error handling
- 👽️ `fix`: External API changes
- 🔥 `fix`: Remove code/files
- 🎨 `style`: Code structure
- 🚑️ `fix`: Critical hotfixes
- 🎉 `chore`: Project initialization
- 🔖 `chore`: Version tags
- 🚧 `wip`: Work in progress
- 💚 `fix`: Fix CI builds
- 📌 `chore`: Pin dependencies
- 👷 `ci`: Build system updates
- 📈 `feat`: Analytics/tracking
- ✏️ `fix`: Typo fixes
- ⏪️ `revert`: Revert changes
- 📄 `chore`: License updates
- 💥 `feat`: Breaking changes
- 🍱 `assets`: Asset updates
- ♿️ `feat`: Accessibility
- 💡 `docs`: Source comments
- 🗃️ `db`: Database changes
- 🔊 `feat`: Add logs
- 🔇 `fix`: Remove logs
- 🤡 `test`: Mock implementations
- 🥚 `feat`: Easter eggs
- 🙈 `chore`: .gitignore updates
- 📸 `test`: Snapshot updates
- ⚗️ `experiment`: Experiments
- 🚩 `feat`: Feature flags
- 💫 `ui`: Animations/transitions
- ⚰️ `refactor`: Dead code removal
- 🦺 `feat`: Validation logic
- ✈️ `feat`: Offline support

## AI Features

### Intelligent Message Generation
- **Code Analysis**: Parse diffs to understand function/class modifications
- **Pattern Recognition**: Identify common change types (features, fixes, refactoring)  
- **Smart Suggestions**: Generate multiple ranked commit message options
- **Scope Detection**: Auto-identify affected modules for scoped commits
- **Context Integration**: Use branch names and commit history for consistency

### Pre-Commit Validation
- **Quality**: Linting, formatting, type checking
- **Testing**: Unit tests for modified files, coverage validation
- **Security**: Vulnerability scanning, sensitive data detection  
- **Standards**: Documentation updates, merge conflict resolution
- **Results**: Clear pass/fail with actionable error messages

### Context-Aware Enhancement
- **Branch Analysis**: Infer context from branch naming conventions
- **History Integration**: Maintain consistency with recent commit patterns
- **Issue Linking**: Auto-detect related tickets and suggest references
- **Breaking Changes**: Identify API modifications and recommend proper footers
- **Impact Analysis**: Detect multi-module changes for appropriate scoping

## Best Practices

### Commit Quality
- **Atomic**: Each commit serves a single purpose
- **Descriptive**: Clear, specific commit messages under 72 characters
- **Present tense**: Use imperative mood ("add feature" not "added feature")
- **Conventional**: Follow `<type>(<scope>): <description>` format
- **Verified**: Code is linted, tested, and documented before committing

### Splitting Guidelines
Split commits based on:
- Different concerns/components
- Mixed change types (feat + fix + docs)
- Logical groupings for easier review
- File patterns (source vs tests vs docs)
- Size considerations for clarity

### Example Messages
- ✨ feat(auth): add JWT token validation middleware
- 🐛 fix(api): resolve race condition in user lookup
- 📝 docs: update README with new installation steps  
- ♻️ refactor(utils): simplify error handling logic
- 🔒️ fix(security): patch XSS vulnerability in form inputs
- 🚑️ fix: resolve critical memory leak in payment processing