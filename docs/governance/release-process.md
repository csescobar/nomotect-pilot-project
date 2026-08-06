# Release Process

## Goals

The release process must provide repeatability, traceability, rollback information and timely delivery of security fixes.

## Release types

- **Patch:** compatible bug fixes, documentation corrections and security updates.
- **Minor:** backward-compatible capabilities, components and extension points.
- **Major:** intentionally incompatible contracts or architectural changes.

## Required release evidence

Before a release is published, maintainers must confirm:

- Automated tests and required status checks pass.
- Static analysis and dependency security checks pass.
- Database migrations have a reviewed deployment and rollback strategy.
- Public contracts and configuration changes are documented.
- Translation keys and accessibility impact are reviewed.
- Security and privacy impact are documented.
- Upgrade instructions exist when user action is required.

## Candidate workflow

1. Create or update the release milestone.
2. Confirm that included pull requests use appropriate labels and changelog categories.
3. Prepare a release branch only when stabilization requires it; otherwise release from `main`.
4. Generate release notes from merged pull requests and manually verify them.
5. Run the complete CI and security pipeline against the release commit.
6. Create a signed version tag when signing infrastructure is available.
7. Publish artifacts and documentation.
8. Verify the installation or upgrade path in a clean environment.
9. Monitor errors and security signals after publication.

## Security releases

Security fixes may use a private preparation process until coordinated disclosure is appropriate. Release notes must explain impact and upgrade urgency without exposing unnecessary exploitation detail.

## Rollback

Every release that changes persistence, queues, storage or public configuration must document:

- Whether application rollback is safe.
- Whether schema rollback is safe.
- Whether data transformation is reversible.
- Which feature flags can reduce impact.
- How to verify recovery.

## Release ownership

A designated maintainer approves each release. The release record should identify the version, commit, approver, validation evidence and known limitations.
