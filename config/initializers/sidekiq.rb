Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  config.on(:startup) do
    full_config = YAML.load_file(File.expand_path('../sidekiq.yml', __dir__))
    Sidekiq.schedule = full_config[:schedule] || full_config['schedule']
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
