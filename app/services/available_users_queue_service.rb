class AvailableUsersQueueService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
  end

  def call
    today = Time.current.in_time_zone('America/Santiago').to_date
    role = Role.find_by(name: @role_name)

    User
      .select('users.*, COUNT(attendances.id) AS pending_count')
      .joins("LEFT JOIN attendances ON attendances.attended_by = users.id AND attendances.status = 'pending'")
      .where(organization_id: @organization_id)
      .where(branch_id: @branch_id)
      .where(role_id: role.id)
      .where(work_state: :available)
      .where('DATE(start_working_at) = ?', today)
      .group('users.id')
      .order('pending_count ASC', 'start_working_at ASC')
  end
end
