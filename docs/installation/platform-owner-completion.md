# Platform Administrator and Installation Completion

The final Phase 1 installation step creates the first global platform administrator and the initial tenant in the provisioned application database.

## Authority model

The first user receives two separate assignments:

- a global `platform_admin` role stored in `platform_roles`;
- an organization-scoped `owner` membership for the initial tenant.

Tenant roles remain isolated in `memberships`. An organization owner does not receive platform-wide authority unless a separate `platform_roles` record grants it.

## Inputs

- Initial organization name
- Platform administrator email address
- Password and confirmation

Passwords are write-only request data. They are never written to local installation state, progress events or database installation metadata.

## Idempotency

The completion service normalizes and reuses the administrator by email, reconciles a unique `platform_admin` role, reuses the organization by deterministic slug, and reconciles the initial tenant membership to `owner`. Retrying the step does not create duplicate principals or authority assignments.

## Completion evidence

After the transaction succeeds, the latest environment installation record is updated to `completed` and records only the platform administrator user ID, platform-role ID, initial organization ID and initial owner-membership ID. The local installation state then transitions from `platform_owner` to the terminal `completed` state.

## Security boundary

- Minimum password length is 12 characters.
- Password confirmation must match using constant-time comparison.
- Progress output contains no account credentials.
- Bootstrap session authorization is removed after completion.
- Completed installations bypass all installer routes through the existing installation gate.
