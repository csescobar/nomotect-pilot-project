# Platform Core AI Context

## Purpose

Provide the executable Rails foundation shared by all future platform capabilities.

## Public contracts

- `Authentication` controls session restoration, sign-in and sign-out.
- `ApplicationPolicy` is the base authorization contract.
- `Current` carries request-scoped identity and correlation metadata.
- `UI::ButtonComponent` validates the initial ViewComponent convention.
- `/health` reports database and extension lifecycle readiness with stable,
  credential-free codes.
- `bin/setup`, `bin/dev`, `bin/test`, `bin/lint`, `bin/security` and `bin/ci` are stable developer entrypoints.

## Invariants

- Protected application pages require an authenticated session.
- Passwords are never stored or logged in plain text.
- Session cookies are signed, HTTP-only and use a restrictive same-site policy.
- Authorization denies access by default.
- Request context is isolated with `ActiveSupport::CurrentAttributes`.
- Health responses do not expose credentials or internal exception messages.
- Normal application traffic is denied when required extension readiness fails.

## Allowed dependencies

The platform core may depend on Rails, PostgreSQL, Hotwire, ViewComponent and approved security and quality tooling. It must not depend on future business-domain modules.

## Human review required

Changes to authentication, sessions, password reset, authorization defaults, security headers, rate limits, logging filters or database constraints require explicit security review.

## Validation

Run `bash bin/ci`. Until a lockfile is generated in a Ruby 4.0 environment, dependency installation must also be verified in GitHub Actions.

## Known limitations

- Role and permission models are deferred to a focused authorization capability.
- Multi-factor authentication and external identity providers are future extensions.
- The initial CSS is a foundation only; the design token compiler is Epic 2.
