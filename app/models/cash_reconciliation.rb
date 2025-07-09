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
    service_data = CashReconciliationService.new(self.branch, self.created_at || Time.current).perform_preview

    return if service_data[:error] # No se puede verificar si no hay una apertura previa

    self.expected_cash = service_data[:expected_total_cash_on_hand]
    self.expected_bank_transfer = service_data[:expected_bank_from_sales] # Asumiendo que transfer y card van a cuentas
    self.expected_credit_card = 0 # O ajustar según la lógica de negocio

    self.difference_cash = self.cash_amount - self.expected_cash

    self.status = (difference_cash.abs < 0.01) ? :verified : :discrepancy
  end
end
