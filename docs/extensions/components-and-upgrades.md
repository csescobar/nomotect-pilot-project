# Component Isolation and Upgrade State

Extension component declarations do not grant access to arbitrary filesystem
locations. After discovery and compatibility preflight, the platform resolves
configuration, migration and documentation resources relative to the installed
package root. Resolution follows symbolic links and rejects any resulting path
outside that root.

The component contract applies these boundaries:

- configuration and documentation declarations resolve to existing files;
- every migration declaration resolves to an existing directory;
- migration, route and asset namespaces are preserved separately for each
  extension;
- resolved absolute paths are internal runtime values and are not persisted in
  installed-state evidence;
- component resolution never invokes an extension entrypoint or component
  hook.

Extensions remain trusted in-process Ruby code after loading. Filesystem
resolution prevents accidental path escape; it is not a sandbox for malicious
code.

## Upgrade observations

Installed platform state schema version 2 records every enabled extension with
its package, semantic version, required flag, extension contract version,
provided capabilities, component summary and stable finding codes. It also
queries each declared migration namespace and records pending extension
migrations without running them.

Upgrade preflight blocks with:

- `extension_state_incompatible` when an enabled extension is missing,
  incompatible, has invalid component resources or cannot be inspected;
- `pending_extension_migrations` when an enabled extension has migrations that
  are not applied.

The observations are credential-free. Configuration values, extension secrets,
absolute package paths and exception messages are excluded. Inspection is
read-only and does not load extensions, register Rails routes, append asset
paths or execute migrations.

Operators must install or repair required packages, resolve compatibility
findings and apply migrations through the later controlled upgrade lifecycle.
Installing, replacing or removing an extension requires a process restart.
