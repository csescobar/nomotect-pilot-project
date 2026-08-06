# Enterprise Services AI Context

## Purpose

Enterprise Services provide reusable infrastructure for audited business applications without coupling domain modules to delivery mechanisms. The module owns idempotent background execution, notifications, tenant-scoped files, imports and exports, workflow transitions, signed webhooks, feature flags, and structured instrumentation.

## Owned paths

- `app/models/idempotency_record.rb`
- `app/models/notification.rb`
- `app/models/stored_file.rb`
- `app/controllers/stored_files_controller.rb`
- `app/policies/stored_file_policy.rb`
- `app/operations/stored_files/download.rb`
- `app/models/import_run.rb`
- `app/models/webhook_endpoint.rb`
- `app/models/feature_flag.rb`
- `app/jobs/*_job.rb` enterprise delivery jobs
- `app/services/idempotent_execution.rb`
- `app/services/notification_dispatcher.rb`
- `app/services/enterprise_storage.rb`
- `app/services/stored_file_registry.rb`
- `app/services/workflow_transition.rb`
- `app/services/webhook_publisher.rb`
- `app/services/customers/csv_importer.rb`
- `app/services/customers/csv_exporter.rb`
- `docs/modules/enterprise_services/tenant-scoped-files.md`
- `docs/modules/enterprise_services/tenant-safety-certification.md`
- enterprise-service migrations, configuration, locales, and tests

## Public contracts

1. Retriable jobs that can cause side effects require an idempotency key and tenant-aware scope.
2. Notification creation and delivery are separate; delivery state is persisted before callers rely on it.
3. Stored files always belong to an organization, use opaque storage keys, and expose checksums and byte sizes. Downloads resolve through the owning organization and require membership authorization before storage reads.
4. Import runs persist progress and structured row errors; domain writes still pass through domain operations.
5. Exports use authorization-scoped queries and never accept an unrestricted relation from callers.
6. Workflow transitions require an explicit transition map and publish an immutable domain event in the same transaction.
7. Webhooks require HTTPS, are signed with HMAC-SHA256, reject private destinations at delivery time, and run asynchronously.
8. Webhook secrets are encrypted at rest and are never included in instrumentation payloads.
9. Tenant feature flags override global defaults, including explicit tenant-level disablement.
10. Enterprise instrumentation records event names, duration, request context, tenant context when available, and payload keys—not sensitive payload values.

## Security and reliability boundaries

- Never pass untrusted filesystem paths to storage APIs.
- Never resolve tenant file requests with an unscoped `StoredFile.find`; resolve through `organization.stored_files` and authorize before reading bytes.
- Never deliver webhooks to loopback, link-local, or private IP addresses.
- Never log notification payload values, webhook secrets, uploaded bytes, or import row contents.
- Keep jobs safe to retry and ensure side effects are guarded by idempotency where duplication is harmful.
- Resolve tenant-owned requester and recipient identifiers before opening idempotent execution or creating delivery state.
- Preserve tenant identifiers through jobs, files, imports, exports, notifications, and webhooks.

## Accessibility and localization

This baseline is service-oriented and introduces no new interactive UI. Future administrative screens must use existing design-system components, localize visible copy in English and Brazilian Portuguese, expose status text without color-only meaning, and remain keyboard and screen-reader operable.

## Extension guidance

Prefer small adapters around these contracts rather than domain-specific infrastructure forks. New delivery channels, storage providers, import formats, and webhook transports must preserve tenant isolation, idempotency, structured audit evidence, and safe observability.
