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
      # If the queue is empty, build the initial queue
      user_ids = User.build_initial_queue(role)
      Rails.cache.write(redis_key, user_ids, expires_in: 12.hours)
    end
    User.where(id: user_ids).order(:start_working_at)
  end
end
