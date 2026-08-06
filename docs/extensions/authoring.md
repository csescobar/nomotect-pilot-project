# Extension Authoring

Product-owned extensions live in `application/extensions/<package>` and are
declared in `application/config/extensions.yml`. External extension gems remain
supported through Bundler. Both package types use the same manifest,
compatibility and registration contracts.

An extension entrypoint registers only through the public SDK. It must not
reopen platform classes, prepend modules into internal constants or mutate a
global registry directly.

```ruby
Extensions.register("acme.audit") do |extension|
  extension.capability(
    "audit.events",
    version: 1,
    provider: ->(event) { Acme::Audit.record(event) }
  )

  extension.configuration ->(settings) { Acme::Audit.configure(settings) }
  extension.routes ->(router) { Acme::Audit.draw_routes(router) }
end
```

The id and capability versions must match `platform-extension.yml`. A
capability provider and every component hook must respond to `call`.

Supported component hooks are:

- `configuration`;
- `migrations`;
- `routes`;
- `assets`;
- `documentation`.

A hook is accepted only when its component is declared by the manifest.
Configuration and documentation require a non-null path. Migrations require at
least one declared migration path. Registration must include every capability
listed in `capabilities.provides`.

Declared filesystem resources must exist in the installed package and resolve
inside its real package root. A symbolic link cannot be used to expose an
external configuration, migration or documentation path. Route, asset and
migration namespaces must be unique to the extension's public identity.

## Loading contract

The platform loads entrypoints only from a ready preflight report and follows
its dependency-first order. Each entrypoint receives an isolated registration
context. Registration is committed atomically after its block succeeds; an
undeclared capability, duplicate hook, identity mismatch or missing declared
capability leaves that extension unregistered.

After all entrypoints register, the registry is sealed. Reusing the same loader
returns its existing result and does not execute entrypoints again. Loading a
fresh registry after Ruby has already required the entrypoint is unsupported;
restart the process before retrying a failed or changed extension set.

Entrypoints resolve to a real file below the package's `lib` directory. Missing
files and symbolic-link escapes fail before registration.

Loading failures use `extension_load_failed` and identify the extension and
exception class. Original exception messages are not included because they may
contain configuration or provider details.

The SDK does not grant isolation. Registered providers execute as trusted
in-process application code.

Any entrypoint failure requires a process restart. The platform does not retry,
reload or unload extension code inside the same Ruby process.
