# Tenant-scoped files

Stored files are organization-owned records backed by opaque storage keys. The owning organization is the association boundary for registration, route lookup, authorization and download.

## Registration

Register bytes through `StoredFileRegistry`; do not write a `StoredFile` and its storage object independently. The registry verifies that `uploaded_by` belongs to the owning organization before it writes bytes, and removes a newly written object if metadata persistence fails.

```ruby
file = StoredFileRegistry.call(
  organization: organization,
  uploaded_by: Current.user,
  name: "report.csv",
  content_type: "text/csv",
  bytes: csv
)
```

A rejected foreign uploader leaves neither metadata nor a storage object behind.

## Resolution and authorization

Resolve identifiers through the organization association before policy authorization:

```ruby
organization = Organization.find(params[:organization_id])
file = organization.stored_files.find(params[:id])
authorize!(file, :show?)
```

Never resolve a request with `StoredFile.find(params[:id])`. Parent-scoped lookup makes a mismatched organization/file pair fail before storage access. `StoredFilePolicy` then requires the current user to have a membership in the file's owning organization.

## Download

The canonical download endpoint is `GET /organizations/:organization_id/stored_files/:id`. The controller performs association lookup and policy authorization, then delegates byte retrieval to `StoredFiles::Download`. The operation repeats the tenant assertions before calling `EnterpriseStorage.read` and returns the registered name and content type with the bytes.

Application modules should link to this endpoint instead of exposing storage keys or reading storage directly. Non-HTTP consumers must use the application operation rather than calling `EnterpriseStorage` themselves. Cross-tenant route manipulation returns `404`; a non-member request for a correctly associated file returns `403`. Neither path reads file bytes.
