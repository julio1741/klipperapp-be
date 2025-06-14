class AvailableUsersQueueService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
  end

  def call
    today = Time.current.in_time_zone('America/Santiago').to_date
    role = Role.find_by(name: @role_name)
    redis_key = "user_rotation_list:org:#{@organization_id}:branch:#{@branch_id}:#{today}"
    user_ids = Rails.cache.read(redis_key)
    if user_ids.blank?
      # Build the initial queue if it doesn't exist
      User.build_initial_queue(@organization_id, @branch_id)
      user_ids = Rails.cache.read(redis_key)
    end
    User.where(id: user_ids).order(:start_working_at)
  end
end
