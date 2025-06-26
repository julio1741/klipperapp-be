class Statistics
  def initialize(year: nil, month: nil, day: nil, organization_id: nil, branch_id: nil, user_id: nil)
    @year = year
    @month = month
    @day = day
    @organization_id = organization_id
    @branch_id = branch_id
    @user_id = user_id
  end

  def perform
    attendances = filter_attendances

    {
      total_profiles: total_profiles(attendances),
      total_new_profiles: total_new_profiles(attendances),
      total_concurrent_profiles: total_concurrent_profiles(attendances),
      most_services: most_services(attendances),
      total_attendances: attendances.count,
    }
  end

  private

  def filter_attendances
    scope = Attendance.all
    scope = scope.where(organization_id: @organization_id) if @organization_id
    scope = scope.where(branch_id: @branch_id) if @branch_id
    scope = scope.where(attended_by: @user_id) if @user_id

    if @year
      scope = scope.where("EXTRACT(YEAR FROM (attendances.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Santiago')) = ?", @year.to_i)
    end

    if @month
      scope = scope.where("EXTRACT(MONTH FROM (attendances.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Santiago')) = ?", @month.to_i)
    end

    if @day
      scope = scope.where("EXTRACT(DAY FROM (attendances.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Santiago')) = ?", @day.to_i)
    end

    scope
  end

  def total_profiles(attendances)
    attendances.select(:profile_id).distinct.count
  end

  def total_new_profiles(attendances)
    profile_ids = attendances.select(:profile_id).distinct.pluck(:profile_id)
    Profile.where(id: profile_ids).where("created_at >= ?", attendances.minimum(:created_at)).count
  end

  def total_concurrent_profiles(attendances)
    attendances.group(:profile_id).having("COUNT(*) > 1").count.keys.size
  end

  def most_services(attendances)
    service_counts = attendances.joins(:services).group("services.name").count
    service_counts.max_by { |_service, count| count }&.first
  end
end
