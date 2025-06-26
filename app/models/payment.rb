class Payment < ApplicationRecord
  include Filterable
  include AASM

  belongs_to :organization
  belongs_to :branch
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :no_overlapping_payments

  aasm column: 'aasm_state' do
    state :pending, initial: true
    state :approved, :rejected, :canceled, :success

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end

    event :resend do
      transitions from: :rejected, to: :pending
    end

    event :cancel do
      transitions from: [:pending], to: :canceled
    end

    event :mark_success do
      transitions from: :approved, to: :success
    end
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?

    if ends_at <= starts_at
      errors.add(:ends_at, "must be after the start date")
    end
  end

  def no_overlapping_payments
    overlapping_payments = Payment.where(user_id: user_id)
                                   .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    overlapping_payments = overlapping_payments.where.not(id: id) if id.present?

    if overlapping_payments.exists?
      errors.add(:base, "Payment dates cannot overlap with existing payments for the same user")
    end
  end
end
