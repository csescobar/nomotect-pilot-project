module Organizations
  class OwnershipTransfer
    class NotAuthorized < StandardError; end
    class InvalidTarget < StandardError; end

    def self.call(organization:, actor:, target_user:)
      new(organization: organization, actor: actor, target_user: target_user).call
    end

    def initialize(organization:, actor:, target_user:)
      @organization = organization
      @actor = actor
      @target_user = target_user
    end

    def call
      organization.with_lock do
        actor_membership = organization.memberships.lock.find_by(user: actor)
        target_membership = organization.memberships.lock.find_by(user: target_user)

        raise NotAuthorized, "only an owner can transfer ownership" unless actor_membership&.owner?
        raise InvalidTarget, "target must be a current tenant member" unless target_membership
        raise InvalidTarget, "ownership is already assigned to target" if target_membership.owner?

        target_membership.update!(role: "owner")
        actor_membership.update!(role: "admin")

        DomainEvent.create!(
          organization: organization,
          actor: actor,
          aggregate_type: "Organization",
          aggregate_id: organization.id,
          event_type: "organization.ownership_transferred",
          payload: {
            previous_owner_id: actor.id,
            new_owner_id: target_user.id
          },
          request_id: Current.request_id,
          occurred_at: Time.current
        )

        target_membership
      end
    end

    private

    attr_reader :organization, :actor, :target_user
  end
end
