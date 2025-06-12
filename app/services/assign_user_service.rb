class AssignUserService
  def initialize(organization_id:, branch_id:, role_id:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_id = role_id
  end

  def call
    now = Time.current.in_time_zone('America/Santiago')

    # Traemos a los barberos que están trabajando hoy
    users = User.where(
      organization_id: @organization_id,
      branch_id: @branch_id,
      role_id: @role_id,
      work_state: :available
    ).where('DATE(start_working_at) = ?', now.to_date)
     .order(:start_working_at)

    return nil if users.empty?

    # Para cada barbero calculamos su próxima disponibilidad
    barber_availabilities = users.map do |user|
      [user, next_available_at(user, now)]
    end

    # Seleccionamos al barbero que estará disponible más pronto
    next_barber, _time = barber_availabilities.min_by { |_b, time| time }

    next_barber
  end

  private

  # Obtiene la hora a la que un barbero estará disponible
  def next_available_at(user, now)
    last_attendance = Attendance.where(attended_by: user.id)
                                .where('created_at >= ?', now.beginning_of_day)
                                .order(end_time_sql)
                                .last

    if last_attendance
      end_time = last_attendance.created_at + last_attendance.service.duration.minutes
      [end_time, now].max
    else
      now
    end
  end

  # Helper para ordenar por término de atención
  def end_time_sql
    Arel.sql("created_at + (SELECT duration FROM services WHERE services.id = attendances.service_id) * interval '1 minute'")
  end
end
