class PaymentService
  def initialize(start_date:, end_date:, user_id:, branch_id: nil, organization_id: nil)
    @start_date = start_date.to_date
    @end_date = end_date.to_date
    @user_id = user_id
    @branch_id = branch_id
    @organization_id = organization_id
  end

  def perform
    attendances = fetch_attendances
    expenses = fetch_expenses

    total_earnings = attendances.sum(:user_amount)
    total_expenses = expenses.sum(:amount)
    amount_to_pay = total_earnings - total_expenses

    {
      attendances: attendances.as_json(only: [:id, :status, :user_amount, :start_attendance_at, :end_attendance_at]),
      expenses: expenses.as_json(only: [:id, :description, :amount, :created_at]),
      earnings: total_earnings,
      expenses: total_expenses,
      amount_to_pay: amount_to_pay
    }
  end

  private

  def fetch_attendances
    scope = Attendance.where(status: 'finished')
    scope = scope.where(attended_by: @user_id) if @user_id.present?
    scope = scope.where(branch_id: @branch_id) if @branch_id.present?
    scope = scope.where(organization_id: @organization_id) if @organization_id.present?
    scope.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end

  def fetch_expenses
    scope = Expense
    scope = scope.where(user_id: @user_id) if @user_id.present?
    scope = scope.where(branch_id: @branch_id) if @branch_id.present?
    scope = scope.where(organization_id: @organization_id) if @organization_id.present?
    scope.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end
end
