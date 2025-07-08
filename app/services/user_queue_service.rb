class UserQueueService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
    @role = Role.find_by(name: @role_name)
    @today = Time.current.in_time_zone('America/Santiago').to_date
    @cache_key = "barber_queue:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
    @order_cache_key = "order_barber_queue:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
  end

  def add_user_to_queue(user)
    user_ids = Rails.cache.read(@cache_key) || []
    return if user_ids.include?(user.id)
    user_ids << user.id
    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
  end

  def add_user_to_order_queue(user)
    user_ids = Rails.cache.read(@order_cache_key) || []
    return if user_ids.include?(user.id)
    user_ids << user.id
    Rails.cache.write(@order_cache_key, user_ids, expires_in: 12.hours)
  end

    # Devuelve la cola completa en orden actual
  def queue
    user_ids = Rails.cache.read(@cache_key)
    order_user_ids = Rails.cache.read(@order_cache_key)
    user_ids = build_queue if user_ids.nil? || user_ids.empty? || order_user_ids.nil? || order_user_ids.empty?
    load_users(user_ids)
  end

  def load_users(user_ids)
    users = User.where(id: user_ids).index_by(&:id)
    user_ids.map { |id| users[id] }.compact
  end

    # Devuelve el próximo barbero disponible (menos carga, más arriba en la cola)
  def next_available
    user_ids = Rails.cache.read(@order_cache_key)

    return nil if user_ids.empty?

    pending_counts = load_pending_counts(user_ids)
    users = load_users(user_ids)
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

  # sacar user de la cola
  def remove(user)
    user_ids = Rails.cache.read(@cache_key) || []
    return unless user_ids.include?(user.id)
    user_ids.delete(user.id)
    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
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
    puts "Building initial queue for #{@organization_id} - #{@branch_id} on #{@today}: #{user_ids.inspect}"
    puts "Cache key: #{@cache_key}"
    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
    Rails.cache.write(@order_cache_key, user_ids, expires_in: 12.hours)
    user_ids
  end

  # Guarda la última posición del usuario en la cola antes de removerlo
  def save_last_queue_position(user)
    user_ids = Rails.cache.read(@cache_key) || []
    pos = user_ids.index(user.id)
    if pos
      Rails.cache.write(last_position_key(user), pos, expires_in: 12.hours)
    end
  end

  # Restaura al usuario en su posición original o al principio si ya pasó su turno
  def restore_queue_position(user)
    user_ids = Rails.cache.read(@cache_key) || []
    pos = Rails.cache.read(last_position_key(user))
    if pos && pos <= user_ids.length
      user_ids.insert(pos, user.id)
    else
      user_ids.unshift(user.id)
    end
    user_ids.uniq!
    Rails.cache.write(@cache_key, user_ids, expires_in: 12.hours)
    Rails.cache.delete(last_position_key(user))
  end

  def last_position_key(user)
    "last_queue_position:user:#{user.id}:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
  end
end
