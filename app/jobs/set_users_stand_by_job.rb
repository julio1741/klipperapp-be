require 'sidekiq-scheduler'

class SetUsersStandByJob
  include Sidekiq::Job

  def perform
    User.set_users_stand_by
    Rails.cache.clear
  end
end
