class CashReconciliationService
  attr_reader :branch, :date

  def initialize(branch, date_string)
    @branch = branch
    @date = date_string.present? ? Date.parse(date_string) : Date.current
  end

  def perform_preview
    opening = find_or_create_daily_opening
    return { error: 'Could not find or create an opening reconciliation for the branch.' } unless opening

    # Determinar hasta qué punto en el tiempo calcular, si es hoy o un día pasado.
    end_time = date.today? ? Time.current : date.end_of_day

    attendances = find_attendances_since(opening.created_at, end_time)

    expected_cash_from_sales = attendances.where(payment_method: 'cash').sum(:total_amount)
    expected_pos_from_sales = attendances.where(payment_method: 'card').sum(:total_amount)
    expected_transfer_from_sales = attendances.where(payment_method: 'transfer').sum(:total_amount)

    total_cash = opening.cash_amount + expected_cash_from_sales

    {
      opening_reconciliation_id: opening.id,
      last_opening_time: opening.created_at,
      preview_time: end_time,
      initial_cash: opening.cash_amount,
      initial_bank_total: opening.bank_balances.sum { |acc| acc['balance'].to_f },
      expected_cash_from_sales: expected_cash_from_sales,
      expected_pos_from_sales: expected_pos_from_sales,
      expected_transfer_from_sales: expected_transfer_from_sales,
      expected_total_cash_on_hand: total_cash,
      expected_total_pos_balance: expected_pos_from_sales, # Asumiendo que el POS inicial es 0
      expected_total_transfer_balance: expected_transfer_from_sales # Asumiendo que el transfer inicial es 0
    }
  end

  private

  def find_or_create_daily_opening
    # Usar un lock para prevenir race conditions
    ActiveRecord::Base.transaction do
      opening = CashReconciliation.find_by(
        branch_id: branch.id,
        reconciliation_type: :opening,
        created_at: date.all_day
      )
      return opening if opening

      user = User.find_by(branch_id: branch.id)
      return nil unless user

      CashReconciliation.create!(
        reconciliation_type: :opening,
        cash_amount: 0,
        bank_balances: [],
        notes: "Apertura automática generada por el sistema.",
        user: user,
        branch: branch,
        organization: branch.organization,
        created_at: date.beginning_of_day
      )
    end
  rescue ActiveRecord::RecordNotUnique
    # En caso de que una apertura se cree en una transacción paralela, reintentar la búsqueda.
    CashReconciliation.find_by(
      branch_id: branch.id,
      reconciliation_type: :opening,
      created_at: date.all_day
    )
  end

  def find_attendances_since(start_time, end_time)
    Attendance.where(
      branch_id: branch.id,
      created_at: start_time..end_time
    ).where(status: :finished)
  end
end
