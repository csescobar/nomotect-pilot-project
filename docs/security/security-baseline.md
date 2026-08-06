# Security Baseline

## Secure defaults

- HTTPS and HSTS in production
- Secure, HttpOnly and SameSite session cookies
- CSRF protection
- Restrictive Content Security Policy
- Clickjacking protection
- Request body and upload limits
- Authentication throttling
- Session expiration and revocation
- Least-privilege database credentials
- Structured logs with sensitive-data filtering

## Application security

- Authorization on every protected operation
- Tenant isolation before filtering and pagination
- Explicit domain transitions instead of direct state mutation
- Optimistic locking for concurrent edits where required
- Idempotency for critical commands
- Output escaping and restricted HTML sanitization
- Private files and temporary download URLs

## Supply-chain controls

- Locked dependencies
- Brakeman
- bundler-audit
- RuboCop security rules
- Dependabot or Renovate
- SBOM generation
- Review process for new dependencies

## Security testing

- Unit tests for policies and domain invariants
- Cross-tenant isolation tests
- Request tests for authentication and authorization
- XSS, CSRF and unsafe redirect tests
- Grid query injection tests
- Upload validation tests

## ISO/IEC 15408 alignment

The platform does not claim certification. It aims to make security requirements, architecture, configuration, tests and release evidence easier to trace and review.
