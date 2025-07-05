class Organization < ApplicationRecord
  include Filterable

  after_create :set_slug_from_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: { case_sensitive: false }, allow_nil: true

  private

  def set_slug_from_name
    update_column(:slug, name.to_s.parameterize)
  end
end
