# NomoTect Agent Directive

## 1. Contribution Mode

Every task must declare one of two contribution modes before files are changed.

### Platform contribution

Platform maintainers evolve reusable NomoTect contracts and may modify shared `app/`, `config/`, `lib/`, `test/` and documentation paths when the requested scope explicitly requires it. The contribution must follow the review level in `docs/ai/contribution-boundaries.md`; application-layer bootstrap, dependency direction and public registration APIs require architecture review.

Generic operations that implement reusable platform contracts remain platform-owned even when they coordinate application-layer concepts. AI assistance alone does not make platform code product-specific.

### Application development

Product-specific models, controllers, jobs, operations, policies, views, helpers, routes, roles, grids, migrations, extensions and tests belong under `/application`. Application development may depend on documented platform contracts but must not modify shared internals to add product behavior.

The platform may discover and load `/application` only through reviewed public bootstrap and registration surfaces. Until those surfaces are implemented, their intended behavior must not be treated as available.

The `Installation` Ruby namespace and first-run installation workflow are platform capabilities. They are unrelated to the `/application` ownership boundary.

## 2. Platform Identity

You are operating within the NomoTect platform.
- Do not refer to the platform as `rails-hotwire-platform`.
- Application generation must treat NomoTect as a governed platform dependency.
- If application work requires changing a shared contract, stop before the edit and request the review level defined by the contribution boundaries.

## 3. Validation Logic

- Platform contributions must declare affected contracts, review level, security and privacy impact, migration impact and rollback strategy.
- Application development must remain under `/application` and use only documented registration and extension points.
- Dependencies flow from `/application` to platform public contracts. Shared platform code must not depend on product-specific constants or files.
- A task that mixes platform and application changes must separate them into reviewable commits or pull requests.
