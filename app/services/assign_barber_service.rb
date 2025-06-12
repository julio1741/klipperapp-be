class AssignBarberService
  def initialize(organization_id:, branch_id:, role_id:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_id = role_id
  end

  def call
    today = Time.now.in_time_zone('America/Santiago')

    # Buscamos barberos disponibles que empezaron a trabajar hoy
    users = User.where(organization_id: @organization_id)
                .where(branch_id: @branch_id)
                .where(role_id: @role_id )
                .where(work_state: :available)
                .where('DATE(start_working_at) = ?', today)
                .order(:start_working_at)
                .distinct

    return nil if users.empty?

    # Usamos una clave cacheada por branch y día para llevar la rotación
    cache_key = "barber_rotation:#{@organization_id}:#{@branch_id}:#{today}"
    last_id = Rails.cache.read(cache_key)

    next_user = if last_id
      current_index = users.index { |b| b.id == last_id }
      next_index = (current_index.to_i + 1) % users.size
      users[next_index]
    else
      users.first
    end

    Rails.cache.write(cache_key, next_user.id, expires_in: 12.hours)

    next_user
  end
end
