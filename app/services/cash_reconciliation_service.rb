class CashReconciliationService
  attr_reader :branch, :date

  def initialize(branch, date_string)
    @branch = branch
    @date = date_string.present? ? Date.parse(date_string) : Date.current
  end

  def get_or_create_daily_report
    # Usar un lock para prevenir race conditions si se llama al mismo tiempo
    ActiveRecord::Base.transaction do
      closing_reconciliation = find_daily_closing
      return closing_reconciliation if closing_reconciliation

      opening_reconciliation = find_or_create_daily_opening
      create_and_return_daily_closing(opening_reconciliation)
    end
  end

  private

  def find_daily_closing
    CashReconciliation.find_by(
      branch_id: branch.id,
      reconciliation_type: :closing,
      created_at: date.all_day
    )
  end

  def find_or_create_daily_opening
    opening = CashReconciliation.find_by(
      branch_id: branch.id,
      reconciliation_type: :opening,
      created_at: date.all_day
    )

    return opening if opening

    # No se encontró apertura, se crea una implícita en cero.
    # Se asume que el primer usuario del branch es quien la crea.
    # Esto podría ajustarse si se necesita una lógica de usuario más específica.
    user = User.find_by(branch_id: branch.id)
    return nil unless user # No se puede crear si no hay usuarios en la sucursal

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

  def create_and_return_daily_closing(opening)
    return nil unless opening

    attendances = Attendance.where(
      branch_id: branch.id,
      created_at: opening.created_at..date.end_of_day
    ).where(status: [:completed, :paid])

    expected_cash_from_sales = attendances.where(payment_method: 'cash').sum(:total_amount)
    expected_bank_from_sales = attendances.where(payment_method: ['transfer', 'card']).sum(:total_amount)

    final_cash = opening.cash_amount + expected_cash_from_sales
    final_bank_balances = calculate_final_bank_balances(opening.bank_balances, expected_bank_from_sales)

    CashReconciliation.create!(
      reconciliation_type: :closing,
      cash_amount: final_cash,
      bank_balances: final_bank_balances,
      notes: "Cierre automático generado por el sistema.",
      user: opening.user, # Usar el mismo usuario de la apertura
      branch: branch,
      organization: branch.organization,
      created_at: date.end_of_day
    )
  end

  def calculate_final_bank_balances(initial_balances, sales_total)
    # Esta es una simplificación. Asume que todas las ventas van a una cuenta genérica.
    # Se podría mejorar si se tuviera un mapeo de payment_method a una cuenta específica.
    final_balances = initial_balances.dup
    if final_balances.empty?
      final_balances << { 'account_name' => 'Cuentas Bancarias', 'balance' => sales_total }
    else
      # Asumimos que todo se suma a la primera cuenta por simplicidad
      final_balances[0]['balance'] = final_balances[0]['balance'].to_f + sales_total
    end
    final_balances
  end
end