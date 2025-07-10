class CashReconciliation < ApplicationRecord
  # == Associations ==
  belongs_to :user
  belongs_to :branch
  belongs_to :organization

  # == Enums ==
  enum reconciliation_type: { opening: 0, closing: 1 }
  enum status: { verified: 0, discrepancy: 1, unverified: 2 }

  # == Validations ==
  validates :reconciliation_type, :cash_amount, :total_calculated, :status, presence: true
  validates :cash_amount, :total_calculated, numericality: { greater_than_or_equal_to: 0 }

  # == Callbacks ==
  before_validation :set_total_calculated
  before_save :calculate_and_verify_closing_amounts, if: :closing?

  private

  def set_total_calculated
    bank_total = bank_balances.sum { |account| account['balance'].to_f || 0 }
    self.total_calculated = cash_amount + bank_total
  end

  def calculate_and_verify_closing_amounts
    opening_date = self.created_at || Time.current

    last_opening = self.class.find_by(
      branch_id: self.branch_id,
      reconciliation_type: :opening,
      created_at: opening_date.all_day
    )

    unless last_opening
      last_opening = self.class.create!(
        reconciliation_type: :opening,
        cash_amount: 0,
        bank_balances: [],
        notes: "Apertura automática generada por el sistema.",
        user: self.user,
        branch: self.branch,
        organization: self.organization,
        created_at: opening_date.beginning_of_day
      )
    end

    attendances = Attendance.where(
      branch_id: self.branch_id,
      created_at: last_opening.created_at..opening_date
    ).where(status: [:completed, :paid])

    self.expected_cash = last_opening.cash_amount + attendances.where(payment_method: 'cash').sum(:total_amount)
    # Lógica similar para bancos...
    self.difference_cash = self.cash_amount - self.expected_cash

    self.status = (difference_cash.abs < 0.01) ? :verified : :discrepancy
  end
end
