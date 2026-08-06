# ADR 0004 — Use an Independent Grid Core with Adapters

## Status

Accepted

## Decision

Implement a framework-owned query language, type registry, operator registry and adapters. Use Tabulator as the first open-source visual adapter.

## Consequences

- Filtering semantics remain independent of the JavaScript library.
- A server-rendered HTML adapter remains possible.
- Tabulator can later be replaced without redesigning query behavior.
