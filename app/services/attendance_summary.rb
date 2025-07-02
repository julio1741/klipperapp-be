class AttendanceSummary
  def initialize(start_day:, end_day:, organization_id: nil, branch_id: nil, user_id: nil, status: nil)
    @start_day = start_day
    @end_day = end_day
    @organization_id = organization_id
    @branch_id = branch_id
    @user_id = user_id
    @status = status
  end

  def perform
    results = []
    days = (@start_day.to_date..@end_day.to_date).to_a
    days.each do |day|
      attendances = filter_attendances_for_day(day)
      results << {
        date: day,
        total_attendances: attendances.count,
        user_amount: attendances.sum(:user_amount),
        extra_discount: attendances.sum(:extra_discount),
        organization_amount: attendances.sum(:organization_amount),
        discount: attendances.sum(:discount),
        total_amount: attendances.sum(:total_amount),
        payment_method: payment_method_counts(attendances)
      }
    end
    results
  end

  private

  def filter_attendances_for_day(day)
    scope = Attendance.all
    scope = scope.where(organization_id: @organization_id) if @organization_id
    scope = scope.where(branch_id: @branch_id) if @branch_id
    scope = scope.where(attended_by: @user_id) if @user_id
    scope = scope.where(status: @status) if @status
    scope = scope.where("DATE(attendances.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Santiago') = ?", day)
    scope
  end

  def payment_method_counts(attendances)
    attendances.group(:payment_method).count
  end
end
