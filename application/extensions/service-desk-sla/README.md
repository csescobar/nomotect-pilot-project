# Service Desk SLA

Deterministic first-response SLA target by request priority.

## Capability

- `service-desk.sla-target` version 1

## Behaviour

| Priority | Target |
| -------- | ------ |
| low      | 96 hours |
| medium   | 48 hours |
| high     | 24 hours |
| critical | 4 hours |

The provider is deterministic and does not depend on wall-clock time. Unknown
priorities fall back to the high-priority target.

## Usage

```ruby
registry = Extensions::Runtime.result.registry
entry = registry.fetch("nomotect.service-desk-sla")
provider = entry.capabilities.fetch("service-desk.sla-target").fetch(:provider)
provider.call(priority: "high")
# => { priority: "high", target_seconds: 86400, deterministic: true, version: 1 }
```
