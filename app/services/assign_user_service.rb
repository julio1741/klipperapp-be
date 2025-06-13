class AssignUserService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
  end

  def call
    today = Time.current.in_time_zone('America/Santiago').to_date

    role = Role.find_by(name: @role_name)
    # Traemos a los usuarios activos hoy, ordenados por orden de llegada
    users = User.where(
      organization_id: @organization_id,
      branch_id: @branch_id,
      role_id: role.id,
      work_state: :available
    ).where('DATE(start_working_at) = ?', today)
     .order(:start_working_at)

    return nil if users.empty?

    # Para cada usuario contamos cuántos attendances pending tiene
    user_with_pending_count = users.map do |user|
      pending_count = Attendance.where(attended_by: user.id, status: :pending).count
      [user, pending_count]
    end

    # Buscamos al usuario con menor cantidad de pendientes, respetando el orden de llegada
    user_with_pending_count.min_by { |user, count| [count, user.start_working_at] }&.first
  end
end
