class UserQueueService
  def initialize(organization_id:, branch_id:, role_name:)
    @organization_id = organization_id
    @branch_id = branch_id
    @role_name = role_name
    @role = Role.find_by(name: @role_name)
    @today = Time.current.in_time_zone('America/Santiago').to_date
    @cache_key = "barber_queue:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
    @order_cache_key = "order_barber_queue:org:#{@organization_id}:branch:#{@branch_id}:#{@today}"
    @redis = $redis
  end

  # ATOMIC: Adds a user to the end of the queue if they are not already present.
  def add_user_to_queue(user)
    Rails.logger.info "Adding add_user_to_queue user #{user.name}-#{user.id} to queue #{@cache_key}"
    @redis.rpush(@cache_key, user.id) unless user_in_queue?(user.id)
    set_expiry
  end

  # ATOMIC: Adds a user to the end of the order queue if they are not already present.
  def add_user_to_order_queue(user)
    Rails.logger.info "Adding add_user_to_order_queue user #{user.name}-#{user.id} to order queue #{@order_cache_key}"
    @redis.rpush(@order_cache_key, user.id) unless user_in_order_queue?(user.id)
    set_expiry
  end

  # ATOMIC: Returns the complete queue in its current order.
  def queue
    user_ids = @redis.lrange(@cache_key, 0, -1).map(&:to_i)
    order_user_ids = @redis.lrange(@order_cache_key, 0, -1).map(&:to_i)
    load_users(user_ids)
  end

  def order_queue
    order_user_ids = @redis.lrange(@order_cache_key, 0, -1).map(&:to_i)
    load_users(order_user_ids)
  end

  def load_users(user_ids)
    return [] if user_ids.empty?
    users = User.where(id: user_ids).index_by(&:id)
    user_ids.map { |id| users[id] }.compact
  end

  # Returns the next available barber (least busy, highest in queue).
  def next_available
    user_ids = @redis.lrange(@order_cache_key, 0, -1).map(&:to_i)
    return nil if user_ids.blank?

    pending_counts = load_pending_counts(user_ids)
    users = load_users(user_ids)

    users.min_by { |u| [pending_counts[u.id] || 0, queue_position(u.id)] }
  end

  def load_pending_counts(user_ids)
    Attendance
      .where(attended_by: user_ids, status: [:pending, :processing])
      .group(:attended_by)
      .count
  end

  def queue_position(user_id)
    @redis.lrange(@cache_key, 0, -1).map(&:to_i).index(user_id) || 9999
  end

  # ATOMIC: Removes a user from both queues.
  def remove(user)
    Rails.logger.info "Removing user #{user.name}-#{user.id} from queue #{@cache_key}"
    @redis.lrem(@cache_key, 0, user.id)
  end

  # ATOMIC: Creates the initial queue ordered by arrival time.
  def build_queue
    user_ids = User
      .where(organization_id: @organization_id, branch_id: @branch_id, role_id: @role.id, work_state: :available)
      .where('DATE(start_working_at) >= ?', @today)
      .order(:start_working_at)
      .pluck(:id)

    puts "Building initial queue for #{@organization_id} - #{@branch_id} on #{@today}: #{user_ids.inspect}"
    puts "Cache key: #{@cache_key}"

    # Use a transaction to ensure both queues are built atomically
    @redis.multi do |multi|
      multi.del(@cache_key)
      multi.del(@order_cache_key)
      multi.rpush(@cache_key, user_ids) if user_ids.present?
      multi.rpush(@order_cache_key, user_ids) if user_ids.present?
    end

    set_expiry
    user_ids
  end

  private

  def user_in_queue?(user_id)
    @redis.lrange(@cache_key, 0, -1).include?(user_id.to_s)
  end

  def user_in_order_queue?(user_id)
    @redis.lrange(@order_cache_key, 0, -1).include?(user_id.to_s)
  end

  # Sets a 12-hour expiry on the Redis keys to prevent them from living forever.
  def set_expiry
    @redis.expire(@cache_key, 12.hours.to_i)
    @redis.expire(@order_cache_key, 12.hours.to_i)
  end
end
