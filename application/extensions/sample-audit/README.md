# Sample Audit Extension

This application-owned sample demonstrates the complete supported extension path without editing a platform registry. It is disabled by default.

When enabled in `application/config/extensions.yml`, NomoTect discovers its bounded local package, validates compatibility before executing code and registers the `sample.audit-events` capability. Consumers must preserve their community behavior when the capability is absent; enabling the extension may add behavior but must not disable an essential community path.

The sample stores no data and performs no network calls. Replace it with product-owned behavior and tests rather than treating it as a production audit implementation.
