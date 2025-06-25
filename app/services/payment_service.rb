class PaymentService
  def initialize(start_date:, end_date:, branch_id: nil, organization_id: nil, user_id: nil)
    @start_date = start_date.to_date
    @end_date = end_date.to_date
    @user_id = user_id
    @branch_id = branch_id
    @organization_id = organization_id
  end

  def perform
    users = fetch_users

    users.map do |user|
      finished_attendances = fetch_attendances(user.id, 'finished')
      other_attendances = fetch_attendances(user.id, ['pending', 'processing', 'postponed'])
      expenses = fetch_expenses(user.id)

      total_earnings = finished_attendances.sum(:user_amount)
      total_expenses = expenses.sum(:amount)
      amount_to_pay = total_earnings - total_expenses

      {
        user: user.as_json(only: [:id, :name, :email]),
        finished_attendances: finished_attendances.as_json(only: [:id, :status, :user_amount, :start_attendance_at, :end_attendance_at]),
        other_attendances: other_attendances.as_json(only: [:id, :status, :user_amount, :start_attendance_at, :end_attendance_at]),
        earnings: total_earnings,
        expenses: total_expenses,
        amount_to_pay: amount_to_pay
      }
    end
  end

  private

  def fetch_users
    scope = User.all
    scope = scope.where(id: @user_id) if @user_id.present?
    scope = scope.where(branch_id: @branch_id) if @branch_id.present?
    scope = scope.where(organization_id: @organization_id) if @organization_id.present?
    scope
  end

  def fetch_attendances(user_id, statuses)
    Attendance.where(
      attended_by: user_id,
      status: statuses
    ).where(
      created_at: @start_date.beginning_of_day..@end_date.end_of_day
    )
  end

  def fetch_expenses(user_id)
    scope = Expense.where(user_id: user_id)
    scope = scope.where(branch_id: @branch_id) if @branch_id.present?
    scope = scope.where(organization_id: @organization_id) if @organization_id.present?
    scope.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
  end
end
