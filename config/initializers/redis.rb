# config/initializers/redis.rb

# Establish a global connection to Redis.
# This is used by various parts of the application that need direct Redis access,
# such as the UserQueueService.

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
$redis = Redis.new(url: redis_url)
