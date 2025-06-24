class Statistics
  def initialize(year: nil, month: nil, day: nil, organization: nil, branch: nil, user: nil)
    @year = year
    @month = month
    @day = day
    @organization = organization
    @branch = branch
    @user = user
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
    scope = scope.where(organization_id: @organization.id) if @organization
    scope = scope.where(branch_id: @branch.id) if @branch
    scope = scope.where(attended_by: @user.id) if @user

    if @year
      scope = scope.where("EXTRACT(YEAR FROM attendances.created_at) = ?", @year)
    end

    if @month
      scope = scope.where("EXTRACT(MONTH FROM attendances.created_at) = ?", @month)
    end

    if @day
      scope = scope.where("EXTRACT(DAY FROM attendances.created_at) = ?", @day)
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
