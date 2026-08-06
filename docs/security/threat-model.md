# Threat Model

## Protected assets

- Personal data
- Authentication credentials and sessions
- Tenant data boundaries
- Audit records
- Uploaded documents
- Integration credentials
- Administrative capabilities

## Initial threat categories

- Account takeover
- Broken access control
- Cross-tenant data disclosure
- Injection through filters, exports or imports
- XSS through rich text or uploaded content
- CSRF and replay
- Malicious file uploads
- Sensitive information in logs
- Supply-chain compromise
- Privilege escalation
- Audit tampering

## Required review points

Threat modeling must be revisited for new modules, external integrations, changes to authentication, sensitive exports and changes to tenant isolation.
