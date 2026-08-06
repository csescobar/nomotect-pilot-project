# Notification Integration

Applications create notifications through `NotificationDispatcher.call` with
an organization, a recipient who is already a member of that organization, a
stable `kind` and a minimal JSON-compatible payload.

```ruby
NotificationDispatcher.call(
  organization: organization,
  recipient: assignee,
  kind: "ticket.assigned",
  payload: { "ticket_id" => ticket.id }
)
```

When a request supplies an identifier, pass `recipient_id:` instead of resolving
the user globally. The dispatcher calls `TenantBoundary.resolve_member!` through
the organization's memberships before it creates any notification:

```ruby
NotificationDispatcher.call(
  organization: organization,
  recipient_id: params.require(:assignee_id),
  kind: "ticket.assigned",
  payload: { "ticket_id" => ticket.id }
)
```

The dispatcher verifies membership before persistence. The job receives only
organization and notification identifiers, resolves the notification through
`organization.notifications`, verifies membership again and records delivery
state. Callers must not enqueue `NotificationDeliveryJob` directly.

Payloads must contain identifiers and presentation-neutral facts, not rendered
HTML, credentials, secrets or unnecessary personal data. Authorization remains
the responsibility of the policy and tenant-scoped query used when a user opens
the referenced resource. A view must not treat possession of a notification as
authorization.

A rejected recipient creates no notification and enqueues no delivery job. Use
the same `TenantBoundary.resolve_member!` contract before persisting an assignee
on an application-owned record.

UI integrations should map the stable `kind` to localized text and retrieve the
referenced record through the normal controller, policy and tenant boundary.
