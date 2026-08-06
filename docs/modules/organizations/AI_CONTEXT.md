# Organizations AI Context

## Purpose

Organizations are the platform's workspace and tenancy boundary. Users gain access only through memberships or by accepting a valid invitation sent to their account email address.

## Owned paths

- `app/models/organization.rb`
- `app/models/membership.rb`
- `app/models/organization_invitation.rb`
- organization, membership, and invitation controllers
- `app/policies/organization_policy.rb`
- `app/views/organizations/**`
- organization migrations, tests, and locale files

## Invariants

1. Every organization creator receives an owner membership in the same transaction.
2. Organization queries exposed to users are scoped through memberships.
3. Membership roles are `owner`, `admin`, or `member`.
4. Owners and administrators may invite people, update regular memberships, and remove regular members.
5. Only owners may promote someone to owner or modify an existing owner membership.
6. An organization must always retain at least one owner.
7. Invitations are limited to `admin` and `member` roles, expire after seven days, and can only be accepted by a user with the invited email address.
8. Accepted or revoked invitations cannot be reused.
9. A user without a membership cannot view the organization.
10. Visible copy is localized in English and Brazilian Portuguese.

## Current boundary

This slice provides invitation creation, acceptance, revocation, role changes, member removal, and owner protections. Email delivery, ownership-transfer confirmation, active-organization selection, and organization-scoped product records remain future focused slices.
