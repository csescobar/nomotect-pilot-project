require "test_helper"

class EnterpriseServicesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    suffix = SecureRandom.hex(4)
    @organization = Organization.create!(name: "Enterprise #{suffix}")
    @user = User.create!(email_address: "enterprise-#{suffix}@example.com", password: "correct horse battery staple")
    Membership.create!(organization: @organization, user: @user, role: "owner")

    @other_organization = Organization.create!(name: "Other #{suffix}")
    @other_user = User.create!(email_address: "other-#{suffix}@example.com", password: "correct horse battery staple")
    Membership.create!(organization: @other_organization, user: @other_user, role: "owner")
  end

  test "idempotent execution returns the persisted result" do
    calls = 0
    first = IdempotentExecution.call(key: "invoice-1", scope: @organization.id.to_s) do
      calls += 1
      { "identifier" => 42 }
    end
    second = IdempotentExecution.call(key: "invoice-1", scope: @organization.id.to_s) do
      calls += 1
      { "identifier" => 99 }
    end

    assert_equal({ "identifier" => 42 }, first)
    assert_equal first, second
    assert_equal 1, calls
  end

  test "notification dispatcher persists and enqueues delivery" do
    assert_enqueued_with(job: NotificationDeliveryJob) do
      notification = NotificationDispatcher.call(
        organization: @organization,
        recipient: @user,
        kind: "customer.updated",
        payload: { customer_id: 1 }
      )

      assert_equal "pending", notification.status
    end
  end

  test "notification dispatcher rejects a recipient from another tenant" do
    initial_count = Notification.count

    assert_raises TenantBoundary::Violation do
      NotificationDispatcher.call(
        organization: @organization,
        recipient: @other_user,
        kind: "customer.updated"
      )
    end

    assert_equal initial_count, Notification.count
    assert_no_enqueued_jobs only: NotificationDeliveryJob
  end

  test "notification dispatcher resolves recipient identifiers tenant first" do
    notification = NotificationDispatcher.call(
      organization: @organization,
      recipient_id: @user.id,
      kind: "customer.updated"
    )

    assert_equal @user, notification.recipient

    assert_raises TenantBoundary::Violation do
      NotificationDispatcher.call(
        organization: @organization,
        recipient_id: @other_user.id,
        kind: "customer.updated"
      )
    end
  end

  test "stored file registry calculates immutable metadata" do
    stored_file = StoredFileRegistry.call(
      organization: @organization,
      uploaded_by: @user,
      name: "customers.csv",
      content_type: "text/csv",
      bytes: "name\nAda\n"
    )

    assert_equal @organization, stored_file.organization
    assert_equal 9, stored_file.byte_size
    assert_equal Digest::SHA256.hexdigest("name\nAda\n"), stored_file.checksum
  end

  test "stored file registry rejects an uploader from another tenant" do
    assert_no_difference "StoredFile.count" do
      assert_raises TenantBoundary::Violation do
        StoredFileRegistry.call(
          organization: @organization,
          uploaded_by: @other_user,
          name: "customers.csv",
          content_type: "text/csv",
          bytes: "name\nAda\n"
        )
      end
    end
  end

  test "stored file download operation rejects a foreign association before storage access" do
    stored_file = StoredFileRegistry.call(
      organization: @other_organization,
      uploaded_by: @other_user,
      name: "private.txt",
      content_type: "text/plain",
      bytes: "private"
    )

    EnterpriseStorage.stub(:read, ->(*) { flunk "unauthorized storage read" }) do
      assert_raises TenantBoundary::Violation do
        StoredFiles::Download.new(actor: @user).call(
          organization: @organization,
          stored_file: stored_file
        )
      end
    end
  ensure
    EnterpriseStorage.delete(stored_file.storage_key) if stored_file
  end

  test "customer jobs reject foreign requester identifiers before idempotency or domain state" do
    assert_no_difference [ "IdempotencyRecord.count", "StoredFile.count", "ImportRun.count", "DomainEvent.count" ] do
      assert_raises TenantBoundary::Violation do
        CustomerExportJob.perform_now(
          organization_id: @organization.id,
          requested_by_id: @other_user.id,
          idempotency_key: "foreign-export"
        )
      end

      assert_raises TenantBoundary::Violation do
        CustomerImportJob.perform_now(
          organization_id: @organization.id,
          requested_by_id: @other_user.id,
          csv: "name,email_address,status\nAda,ada@example.com,active\n",
          idempotency_key: "foreign-import"
        )
      end
    end
  end

  test "notification job rejects a cross-tenant identifier without mutating delivery state" do
    notification = @other_organization.notifications.create!(
      recipient: @other_user,
      kind: "customer.updated",
      status: "pending",
      payload: {}
    )

    assert_no_difference [ "IdempotencyRecord.count", "DomainEvent.count" ] do
      assert_raises ActiveRecord::RecordNotFound do
        NotificationDeliveryJob.perform_now(@organization.id, notification.id)
      end
    end

    assert_equal "pending", notification.reload.status
    assert_nil notification.delivered_at
  end

  test "customer import tracks row failures and export remains tenant scoped" do
    csv = <<~CSV
      name,email_address,status,notes
      Ada,ada@example.com,active,Imported
      ,invalid@example.com,active,Invalid
    CSV

    run = Customers::CsvImporter.call(organization: @organization, requested_by: @user, csv: csv)
    exported = Customers::CsvExporter.call(user: @user, organization: @organization)

    assert_equal 1, run.processed_rows
    assert_equal 1, run.failed_rows
    assert_equal "failed", run.status
    assert_includes exported, "Ada"
    assert_not_includes exported, "invalid@example.com"
  end

  test "customer imports and exports reject users from another tenant" do
    assert_no_difference [ "ImportRun.count", "DomainEvent.count" ] do
      assert_raises TenantBoundary::Violation do
        Customers::CsvImporter.call(
          organization: @organization,
          requested_by: @other_user,
          csv: "name,email_address,status\nAda,ada@example.com,active\n"
        )
      end

      assert_raises TenantBoundary::Violation do
        Customers::CsvExporter.call(user: @other_user, organization: @organization)
      end
    end
  end

  test "workflow transition validates the transition map and emits an event" do
    customer = @organization.customers.create!(name: "Ada", status: "active")

    WorkflowTransition.call(
      record: customer,
      attribute: :status,
      to: "inactive",
      allowed: { "active" => [ "inactive" ], "inactive" => [ "active" ] },
      actor: @user
    )

    assert_equal "inactive", customer.reload.status
    assert DomainEvent.exists?(aggregate_type: "Customer", aggregate_id: customer.id, event_type: "customer.transitioned")
  end

  test "feature flags prefer tenant overrides" do
    FeatureFlag.create!(key: "exports", enabled: true)
    FeatureFlag.create!(organization: @organization, key: "exports", enabled: false)

    assert_not FeatureFlag.active_for?("exports", organization: @organization)
  end

  test "webhook secrets are encrypted at rest" do
    endpoint = WebhookEndpoint.create!(
      organization: @organization,
      url: "https://example.com/hooks",
      secret: "top-secret",
      events: [ "customer.updated" ]
    )

    assert_equal "top-secret", endpoint.secret
    assert_not_equal "top-secret", endpoint[:secret]
    assert endpoint.subscribes_to?("customer.updated")
  end
end
