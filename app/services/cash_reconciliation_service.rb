class CashReconciliationService
  def initialize(branch, end_time = Time.current)
    @branch = branch
    @end_time = end_time
  end

  def perform_preview
    last_opening = find_last_opening
    return { error: 'No opening reconciliation found for this branch today.' } unless last_opening

    attendances = find_attendances_since(last_opening.created_at)

    expected_cash = attendances.where(payment_method: 'cash').sum(:total_amount) + last_opening.cash_amount
    expected_bank_transfer = attendances.where(payment_method: 'transfer').sum(:total_amount)
    expected_credit_card = attendances.where(payment_method: 'card').sum(:total_amount)

    # Sumar los saldos bancarios iniciales
    initial_bank_total = last_opening.bank_balances.sum { |acc| acc['balance'].to_f }
    current_bank_total = expected_bank_transfer + expected_credit_card + initial_bank_total

    {
      last_opening_time: last_opening.created_at,
      preview_time: @end_time,
      initial_cash: last_opening.cash_amount,
      initial_bank_total: initial_bank_total,
      expected_cash_from_sales: attendances.where(payment_method: 'cash').sum(:total_amount),
      expected_bank_from_sales: expected_bank_transfer + expected_credit_card,
      expected_total_cash_on_hand: expected_cash,
      expected_total_bank_balance: current_bank_total
    }
  end

  private

  def find_last_opening
    CashReconciliation.where(
      branch_id: @branch.id,
      reconciliation_type: :opening
    ).where('created_at <= ?', @end_time)
     .order(created_at: :desc)
     .first
  end

  def find_attendances_since(start_time)
    Attendance.where(
      branch_id: @branch.id,
      created_at: start_time..@end_time
    ).where(status: [:completed, :paid]) # Asumiendo estos estados
  end
end
