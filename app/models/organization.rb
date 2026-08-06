class Organization < ApplicationRecord
  THEMES = %w[light dark system].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :organization_invitations, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :domain_events, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :stored_files, dependent: :destroy
  has_many :import_runs, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :feature_flags, dependent: :destroy

  before_validation :assign_slug, on: :create
  before_validation :apply_tenant_defaults

  validates :name, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true
  validates :locale, inclusion: { in: ->(_) { Localization::SupportedLocales.codes } }
  validates :theme, inclusion: { in: THEMES }
  validate :time_zone_must_be_supported

  def membership_for(user)
    return if user.blank?

    memberships.find_by(user: user)
  end

  private

  def assign_slug
    base = name.to_s.parameterize.presence || "organization"
    candidate = base
    suffix = 2

    while self.class.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end

  def apply_tenant_defaults
    self.locale = Localization::SupportedLocales.default.code if locale.blank?
    self.time_zone = Localization::SupportedLocales.fetch(locale).time_zone if time_zone.blank?
    self.theme = "system" if theme.blank?
  end

  def time_zone_must_be_supported
    errors.add(:time_zone, :invalid) unless Time.find_zone(time_zone)
  end
end
