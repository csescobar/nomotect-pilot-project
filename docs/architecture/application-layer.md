# Application Layer

ADR 0005 assigns product-specific source to `/application`. This document describes the implemented Rails bootstrap and the role and Grid Engine registration surfaces governed by ADR 0006.

## Loaded paths

NomoTect registers the following application-owned paths with Rails:

- `application/app/controllers`
- `application/app/helpers`
- `application/app/jobs`
- `application/app/models`
- `application/app/operations`
- `application/app/policies`
- `application/app/views`
- `application/config/initializers`
- `application/config/locales`
- `application/config/routes`
- `application/db/migrate`
- `application/test`

Ruby source directories participate in autoloading and eager loading. Views, initializers, locales and migrations use their native Rails path contracts. `bin/test` includes `application/test` in the default suite while preserving explicit test arguments.

## Routes

Product routes belong in `application/config/routes/application.rb`. The shared router calls `draw :application` only when that fixed file exists. Do not edit `config/routes.rb` to add product routes and do not load route files from user-controlled paths.

## Ownership

The `/application` directory owns product behavior. Shared platform code may expose registration and discovery contracts but must not reference product-specific constants. Product code may use public NomoTect operations, policies, components and registries.

Generic platform behavior remains in shared `app/`, `config/`, `lib/` and `test/` paths. File location is determined by ownership and reuse, not by whether AI assisted the contribution.

## Fixed registration files

Product roles are registered in `application/config/roles.rb`. Every custom role declares an explicit permission list. The protected `owner`, `admin` and `member` registrations cannot be replaced, and a custom role never receives administrative behavior implicitly.

Product grids are registered in `application/config/grids.rb`. A grid registration combines a `GridEngine::Definition` with a callable `scope`. The scope receives the authenticated `user` and active `organization` and must return an already-authorized relation. Registration fails when the scope is absent or when a protected key is replaced.

Both files load once during initialization from fixed paths. The registries are sealed immediately afterward, so application requests cannot mutate authorization or grid behavior at runtime.

## Application-owned extensions

Product extension declarations belong in `application/config/extensions.yml`, and local packages belong in `application/extensions/<package>`. The runtime combines application declarations with the platform extension configuration, rejects duplicate identities and resolves local packages only inside the fixed application directory.

The tracked `sample-audit` package is disabled by default. Its integration test exercises community fallback, discovery, compatibility preflight, loading and registration. It is an authoring example, not a production audit implementation.

## Policy and view integration

Application policies belong in `application/app/policies` and may ask the tenant membership for an explicit permission:

```ruby
class RiskPolicy < ApplicationPolicy
  def update?
    membership = record.organization.membership_for(user)
    membership&.admin? || membership&.permitted?("risks.manage")
  end
end
```

Controllers must continue to call `authorize!`. Application views may use the public `allowed_to?(record, query)` helper to present policy-consistent controls; hiding a control is not a substitute for controller authorization. Existing owner and administrator behavior remains explicit through `Membership#owner?` and `Membership#admin?`; registered permissions do not silently grant either status. Role labels belong in application locale files under `organizations.roles.<role_key>`.

## Starter and CI

The Application Starter includes the tracked skeleton so a newly initialized private repository has the boundary before product development begins. Empty directories use `.keep` files and can be replaced by product source over time.

The default CI entrypoint reaches application tests through `bin/test`. A product must not introduce a separate test command that bypasses platform security, release or Repository Intelligence checks.

## Phase 3 certification

`ApplicationLayer::Certification` aggregates the implemented bootstrap, role, authorized-grid, policy/view, community-fallback and extension-preflight evidence. The report is deterministic, credential-free, bound to a full source commit and unable to authorize publication.

The certification verifies public contracts without activating the sample extension or adding product roles and grids to the starter defaults. Individual contract tests remain authoritative for runtime behavior and adversarial path checks.

The workflow executes certification against the checked-out Git commit and its baseline, writes `tmp/ci/application-layer-certification.json`, records the fixed application registration files loaded during initialization and derives protected-core changes from the Git diff. Protected changes remain valid only when the report declares the architecture-review boundary; application-only adoption reports no protected paths.
