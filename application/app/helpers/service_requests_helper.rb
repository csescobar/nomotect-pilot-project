module ServiceRequestsHelper
  STATUS_CLASSES = {
    "open" => "ui-badge--primary",
    "triaged" => "ui-badge--primary",
    "in_progress" => "ui-badge--warning",
    "resolved" => "ui-badge--success",
    "closed" => "ui-badge--neutral"
  }.freeze

  PRIORITY_CLASSES = {
    "low" => "ui-badge--neutral",
    "medium" => "ui-badge--primary",
    "high" => "ui-badge--warning",
    "critical" => "ui-badge--danger"
  }.freeze

  def status_class(status)
    STATUS_CLASSES.fetch(status, "ui-badge--neutral")
  end

  def priority_class(priority)
    PRIORITY_CLASSES.fetch(priority, "ui-badge--neutral")
  end

  def agent_options(organization)
    organization.memberships.includes(:user).filter_map do |membership|
      next unless membership.permitted?("service_requests.assign")

      [ membership.user.email_address, membership.user_id ]
    end
  end
end
