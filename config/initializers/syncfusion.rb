# Syncfusion EJ2 license key configuration.
#
# The license key is required by the EJ2 component library before any component
# is instantiated. It is injected into the page layout as a JS window global and
# registered via syncfusion_license.js in the asset pipeline.
#
# Set the SYNCFUSION_LICENSE_KEY environment variable in production secrets,
# .env (local, git-ignored) or your secrets manager. Never commit the key.
#
# During the 7-day trial period the key identifies the trial build.
# Replace it with the commercial key before going to production.
Rails.application.config.syncfusion_license_key = ENV.fetch("SYNCFUSION_LICENSE_KEY", "")
