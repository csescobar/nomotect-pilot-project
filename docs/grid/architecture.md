# Grid Architecture

## Goal

Provide a reusable, secure and open-source advanced grid for large business datasets without coupling query semantics to a particular JavaScript component.

## Architecture

```text
Grid DSL
  ↓
Column schema
  ↓
Type and operator registries
  ↓
Validated query AST
  ↓
Active Record/Arel adapter
  ↓
Serialized result
  ↓
Tabulator or HTML adapter
```

## Column definition

Columns declare business meaning and presentation metadata. Operators, parsers and filter editors come from the registered type.

```ruby
class CustomersGrid < ApplicationGrid
  model Customer

  column :name
  column :email, type: :string
  column :status, type: :string
  column :credit_limit, type: :decimal
  column :active, type: :boolean
  column :created_at, type: :datetime
end
```

## Type registry

Currently registered types:

- string
- integer
- decimal
- boolean
- date
- datetime

`email`, `money`, `percentage`, `enum`, `uuid`, `relation` and `actions` are not registered types. Applications must use an existing type or add a reviewed registry extension before declaring one of those names.

Each type defines default operators, parser, formatter, sorting behavior and filter editor.

## Query protocol

The protocol supports nested AND/OR groups, independent column filters, multiple sorting and server-side pagination.

```json
{
  "filter": {
    "logic": "and",
    "conditions": [
      { "field": "status", "operator": "eq", "value": "active" },
      {
        "logic": "or",
        "conditions": [
          { "field": "name", "operator": "contains", "value": "Acme" },
          { "field": "email", "operator": "ends_with", "value": "@acme.com" }
        ]
      }
    ]
  },
  "sort": [{ "field": "created_at", "direction": "desc" }],
  "page": { "number": 1, "size": 25 }
}
```

## Security rules

- Client-supplied SQL is never accepted.
- Public field keys map to server-owned Arel attributes.
- Operators are whitelisted by type.
- Tenant and authorization scopes are applied before user filters.
- Query complexity and page size are limited.
- Export uses the same validated query pipeline.

## Open-source UI adapter

Tabulator is the first adapter. The platform must also retain an HTML/Turbo fallback for accessibility, printing, testing and graceful degradation.
