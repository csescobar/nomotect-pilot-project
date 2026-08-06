module ServiceRequests
  class VisibleTo
    def initialize(user:, organization:)
      @user = user
      @organization = organization
    end

    def call
      return ServiceRequest.none unless membership

      scope = ServiceRequest.where(organization_id: @organization.id)
      return scope if membership.permitted?("service_requests.read")

      scope.where(requester_id: @user.id)
    end

    private

    def membership
      @membership ||= @organization.membership_for(@user)
    end
  end
end
