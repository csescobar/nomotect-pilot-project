# Free Render visual-validation environment

The visual-validation profile provides a zero-cost, disposable environment for
human review of NomoTect components and the Grid Engine. It is not a production
deployment profile and must not be represented as one.

## Architecture

`render.validation.yaml` defines:

- one free Docker web service;
- one free Render PostgreSQL database;
- no persistent disk;
- the shared `/health` endpoint;
- an idempotent startup adapter that prepares the database and representative
  records before Puma starts.

The production contract remains in `render.yaml`. The validation Blueprint does
not modify or weaken it.

## Cost and lifecycle boundary

Render free services use an ephemeral filesystem and may spin down when idle.
The validation boot adapter therefore reconstructs installation state on every
start. User, organization and representative customer records remain in Render
PostgreSQL for the database lifetime.

Free Render PostgreSQL databases expire after 30 days. Delete the Blueprint when
the review cycle is complete. Do not use this profile for production data,
uploads, availability testing, backup evidence or persistence certification.

## Create the Blueprint

1. Connect the GitHub repository to Render.
2. Create a Blueprint and select `render.validation.yaml` instead of the root
   production Blueprint.
3. Review both resources and confirm that their plans are `free` and that no
   disk is attached.
4. Supply the following secret values:
   - `SECRET_KEY_BASE`: at least 64 random characters;
   - `INSTALLATION_BOOTSTRAP_TOKEN`: a high-entropy temporary value;
   - `VISUAL_VALIDATION_EMAIL`: the reviewer sign-in address;
   - `VISUAL_VALIDATION_PASSWORD`: a unique password of at least 12 characters.
5. Apply the Blueprint and wait for `/health` to return HTTP 200.

Never commit those values. Generate new random secrets for every validation
environment and delete them with the Blueprint.

## Startup behavior

`bin/render-start` first prepares the writable ephemeral paths. It then invokes
`bin/render-validation-boot`, which:

1. fails unless `VISUAL_VALIDATION_ENABLED=true`;
2. requires operator-supplied reviewer credentials;
3. runs `rails db:prepare`;
4. reuses the Active Record connection established from `DATABASE_URL` and
   reconciles the reviewer, organization and deterministic customer records;
5. recreates completed installation state and validation appearance metadata;
6. starts Puma.

The preparation is idempotent. A restart updates the same representative
records instead of creating duplicates.

## Visual review entry points

After sign-in, review:

- `/component_showcase` for isolated shared components;
- `/preferences` for account-level theme and language controls;
- `/organizations/:organization_id/customers` for CRUD composition;
- `/grids/customers` for the default Grid Engine composition;
- `/marketing` for public-page token coverage;
- the compact account menu and responsive navigation drawer around those
  surfaces;
- stacked customer records, tokenized form controls, detail property lists,
  empty states and destructive-action danger zones at mobile widths;
- compact localized grid dates on screen and stable ISO 8601 values in CSV;
- Light and Dark rendering at desktop and mobile viewport widths.

The exact organization identifier is visible in the post-login navigation.

## Validation

Run the deterministic repository checks with:

```bash
ruby bin/render-validation-validate
bash -n bin/render-validation-boot
```

The validator fails if either resource is not free, a persistent disk or paid
pre-deploy command or custom shutdown delay is added, secrets are committed, or
the dedicated startup adapter is bypassed.

## Known limitations

- cold starts are expected;
- local files and completed installation state are disposable;
- the database expires according to Render's free-database policy;
- this profile uses one reviewer account and representative non-production data;
- screenshots and manual findings remain review evidence, not production
  certification.
