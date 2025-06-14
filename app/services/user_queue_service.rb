class UserQueueService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
    @role = Role.find_by(name: @role_name)
    @today = Time.current.in_time_zone('America/Santiago').to_date
    @cache_key = "barber_queue:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
  end

    # Devuelve la cola completa en orden actual
  def queue
    user_ids = Rails.cache.read(@cache_key)
    user_ids = build_queue if user_ids.nil? || user_ids.empty?
    load_users(user_ids)
  end

  def load_users(user_ids)
    users = User.where(id: user_ids).index_by(&:id)
    user_ids.map { |id| users[id] }.compact
  end

    # Devuelve el próximo barbero disponible (menos carga, más arriba en la cola)
  def next_available
    users = queue

    return nil if users.empty?

    pending_counts = load_pending_counts(users.map(&:id))

    # Elegimos el primero con menos pending
    users.min_by { |u| [pending_counts[u.id] || 0, queue_position(u.id)] }
  end

  def load_pending_counts(user_ids)
    Attendance
      .where(attended_by: user_ids, status: [:pending, :processing])
      .group(:attended_by)
      .count
  end

  def queue_position(user_id)
    Rails.cache.read(@cache_key)&.index(user_id) || 9999
  end

    # Mueve al user que acaba de atender al final de la cola
  def rotate(user)
    user_ids = Rails.cache.read(@cache_key) || []
    user_ids.delete(user.id)
    user_ids << user.id
    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
  end

   # Crea la cola inicial ordenada por llegada
  def build_queue
    user_ids = User
      .where(organization_id: @organization_id, branch_id: @branch_id, role_id: @role.id, work_state: :available)
      .where('DATE(start_working_at) >= ?', @today)
      .order(:start_working_at)
      .pluck(:id)

    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
    user_ids
  end

end
