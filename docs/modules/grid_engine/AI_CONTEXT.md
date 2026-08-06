# Grid Engine AI Context

## Purpose

The Grid Engine provides a framework-neutral, server-authoritative contract for defining columns, parsing untrusted query input, applying safe Active Record/Arel queries, and presenting equivalent Tabulator and HTML/Turbo experiences.

## Owned paths

- `app/lib/grid_engine/**`
- `app/models/grid_saved_view.rb`
- `app/controllers/grids_controller.rb`
- `app/controllers/grid_saved_views_controller.rb`
- `app/views/grids/**`
- grid migrations, routes, locale files, and tests

## Invariants

1. Only columns declared in a `GridEngine::Definition` may be filtered, sorted, formatted, personalized, or exported.
2. Operators, types, parsers, and formatters are registry entries with explicit keys.
3. Untrusted parameters are parsed into an immutable query AST before reaching Active Record or Arel.
4. Sort directions and pagination are allowlisted and bounded.
5. SQL fragments never come directly from request parameters.
6. Tabulator is an adapter, not the source of business rules.
7. HTML and Turbo fallbacks expose the same data and authorization boundary.
8. Saved views belong to a user and grid key and are always loaded through `Current.user`.
9. Exports reuse the validated definition, AST, tenant-aware scope, and an explicit row limit.
10. Column personalization only accepts keys declared by the grid definition.
11. Visible behavior is localized and covered by model, adapter, request, security, and accessibility tests.

## Public contracts

- `GridEngine::Definition` is the DSL boundary.
- `GridEngine::Query::Parser` converts request data into an immutable AST.
- `GridEngine::ActiveRecordAdapter` applies an AST to an already-authorized relation.
- `GridEngine::TabulatorAdapter` exposes framework-specific columns and response payloads.
- `GridEngine::HtmlRenderer` provides the accessible no-JavaScript and Turbo fallback.
- `GridEngine::CsvExporter` produces bounded exports from validated, authorized relations.
- `GridSavedView` persists user-owned query and presentation preferences.
- `GridEngine::Catalog.register` binds a definition to its authorized base-scope callable during application initialization.

## Extension guidance

Application grids must be registered in `application/config/grids.rb`, declare every public column, and provide an explicitly authorized base relation through the registration `scope`. The catalog is sealed after initialization. Never infer a scope from the model class or accept model/attribute names from request parameters.
