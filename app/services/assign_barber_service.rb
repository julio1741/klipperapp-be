# app/services/assign_barber_service.rb
class AssignBarberService
  def initialize(organization_id:, branch_id:)
    @organization_id = organization_id
    @branch_id = branch_id
  end

  def call
    today = Time.now.in_time_zone('Santiago')

    # Buscamos barberos disponibles que empezaron a trabajar hoy
    barbers = User.joins(:role)
                  .joins(:branch_users) # Asumiendo la tabla intermedia
                  .where(organization_id: @organization_id)
                  .where(branch_users: { branch_id: @branch_id })
                  .where(roles: { name: "Barbero" })
                  .where(work_state: :available)
                  .where('DATE(start_working_at) = ?', today)
                  .order(:start_working_at)
                  .distinct

    return nil if barbers.empty?

    # Usamos una clave cacheada por branch y día para llevar la rotación
    cache_key = "barber_rotation:#{@organization_id}:#{@branch_id}:#{today}"
    last_id = Rails.cache.read(cache_key)

    next_barber = if last_id
      current_index = barbers.index { |b| b.id == last_id }
      next_index = (current_index.to_i + 1) % barbers.size
      barbers[next_index]
    else
      barbers.first
    end

    Rails.cache.write(cache_key, next_barber.id, expires_in: 12.hours)

    next_barber
  end
end
