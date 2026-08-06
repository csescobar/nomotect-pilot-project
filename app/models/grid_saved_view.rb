class GridSavedView < ApplicationRecord
  belongs_to :user

  normalizes :name, with: ->(name) { name.strip }

  validates :grid_key, presence: true
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: %i[user_id grid_key] }
  validate :query_must_be_an_object
  validate :preferences_must_be_an_object

  before_save :clear_other_defaults, if: :default?

  scope :for_grid, ->(grid_key) { where(grid_key: grid_key.to_s).order(default: :desc, name: :asc) }

  private

  def query_must_be_an_object
    errors.add(:query, :invalid) unless query.is_a?(Hash)
  end

  def preferences_must_be_an_object
    errors.add(:preferences, :invalid) unless preferences.is_a?(Hash)
  end

  def clear_other_defaults
    self.class.where(user_id: user_id, grid_key: grid_key, default: true).where.not(id: id).update_all(default: false)
  end
end
