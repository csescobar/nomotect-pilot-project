# Tenant-safety certification

This matrix defines the executable adversarial evidence for Phase 2 tenant-safe application contracts. A rejected request must fail before tenant data is read or side-effect state is created.

| Manipulation | Resolution boundary | Expected failure | Prohibited partial state | Evidence |
| --- | --- | --- | --- | --- |
| Route organization paired with a foreign stored-file ID | `organization.stored_files` | `404 Not Found` | Storage read | `StoredFilesControllerTest` |
| Non-member requests a correctly associated stored file | `StoredFilePolicy` and `StoredFiles::Download` | `403 Forbidden` | Storage read | `StoredFilesControllerTest` |
| Foreign recipient ID is supplied to notification creation | `organization.memberships` | `TenantBoundary::Violation` | Notification and delivery job | `EnterpriseServicesTest` |
| Foreign notification ID is supplied to a delivery job | `organization.notifications` | `ActiveRecord::RecordNotFound` | Delivery status and audit state | `EnterpriseServicesTest` |
| Foreign requester ID is supplied to an import or export job | `organization.memberships` before `IdempotentExecution` | `TenantBoundary::Violation` | Idempotency, import, file and audit records | `EnterpriseServicesTest` |
| Foreign user invokes import or export service | Membership assertion before query or run creation | `TenantBoundary::Violation` | Import and audit records | `EnterpriseServicesTest` |

## Ordering contract

Jobs must resolve the organization and tenant member before opening an idempotent execution. Creating a failed idempotency record is appropriate after an authorized operation begins, but it is prohibited for a request rejected at the tenant boundary.

Controllers authorize the associated record and call an application operation. Infrastructure reads remain behind that operation so the same tenant checks apply outside HTTP delivery.

## Certification rule

Phase 2 passes only when every matrix row has an executable negative-path assertion and the relevant record counts or immutable states remain unchanged. Adding a new identifier-bearing job, download or export requires extending this matrix and its tests.
