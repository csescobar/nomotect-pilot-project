# Phase 8 — Second Independent Adoption Pilot Plan & Protocol

This document defines the execution plan, isolation rules, and operator protocol for **Phase 8: Second Independent Adoption Pilot** as specified in [`docs/roadmap/adoption-validation-improvements.md`](../roadmap/adoption-validation-improvements.md).

## Objectives

Phase 8 validates that an unfamiliar developer or AI assistant, starting in a fresh session with zero institutional knowledge or previous handoff context, can adopt NomoTect to build a fully functional, tenant-safe application under `/application`.

---

## Isolation & Protocol Rules

1. **Clean Session & Workspace:**
   - The pilot must be executed in a **new assistant conversation**.
   - No prior conversation history, prompt snippets, or handoffs are provided.

2. **Two-Session MCP Protocol:**
   - **Session A (Bootstrap):** The assistant inspects only MCP configuration rules, runs `bin/mcp-setup-certify`, requests operator restart, and pauses.
   - **Operator Gate:** The human operator reloads/restarts the assistant client.
   - **Session B (Discovery & Development):** The restarted assistant lists MCP tools (`nomotect-repository-intelligence`, `gitnexus`, `codebase-memory-mcp`, `context7`), runs repository intelligence queries, and confirms tool access *before* reading arbitrary codebase files.

3. **Application Domain Boundary:**
   - All domain logic, models, controllers, and components belong strictly under `/application`.
   - Protected platform internals (`app/`, `lib/`, `config/`, `docs/ai/`) must not be edited unless an architectural review boundary is explicitly triggered.

4. **Required Capability Verification:**
   - Domain operations & tenant isolation policies.
   - Component-based CRUD pages using NomoTect Design Tokens.
   - Data Grid Engine integration.
   - Async background jobs with tenant-safe membership checks.
   - File attachment handling & downloads.
   - One custom extension using `/application` registration surfaces.
   - Real-browser automated system test suite (`bin/rails test:system`).
   - Machine-readable readiness and evidence reports (`bin/release-contract-certify`).

---

## Operator Guide for Starting Phase 8

To launch Phase 8 in a new clean session:

1. **Open a new conversation window** in your AI assistant (AGY / Antigravity CLI / IDE).
2. **Provide the initial prompt for Session A:**
   ```text
   Iniciando a Fase 8 — Segundo Piloto Independente de Adoção do NomoTect.
   Por favor, siga estritamente o protocolo MCP de duas sessões da Fase 0.
   Configure e certifique as ferramentas MCP usando bin/mcp-setup-certify e solicite a reinicialização antes de prosseguir.
   ```
3. **Perform the Operator Restart:**
   - When the assistant requests a restart after Session A, reload/restart the assistant session.
4. **Provide the prompt for Session B:**
   ```text
   Sessão reiniciada. Verifique as ferramentas MCP disponíveis (repository intelligence, gitnexus, codebase memory) e execute a descoberta inicial antes de iniciar a implementação da aplicação em /application.
   ```
