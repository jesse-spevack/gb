# Changelog
All notable changes to this project will be documented in this file.

## [2025-05-03]

### Removed
- Removed all classes from `application.html.erb` and `home/index.html.erb`, created backups of each.
- Added remote build to `deploy.yml`.

## [2025-05-02]

### Added

- Created `UserToken` model with `access_token`, `refresh_token`, `expires_at`, validations, `default_scope`, and `most_recent_for` method.
- Added migration to create `user_tokens` table with references to `users` and timestamps.
- Added tests for `UserToken` covering `most_recent_for`, validations, default scope ordering, `expired?`, and `will_expire_soon?` methods.
- Added `Current` module to manage the current session and user.
- Added `Authentication` concern to handle authentication.
- Added `SessionsController` to handle session creation and destruction.
- Added `Authorization::UserService` to handle user authentication.

## [2025-05-01]

### Added

- Initial commit
- Root route to "coming soon" page
- Prefixes for ids
- Added tasks.json
- Generated User model with validations for email, name, and google_uid
- Added test fixtures for admin and teacher users
- Created bin/check script for running Brakeman, Rubocop, and Rails tests
- Created Session model with user, user_agent, and ip_address attributes
- Added Session model validations and tests
- Added test fixtures for user sessions