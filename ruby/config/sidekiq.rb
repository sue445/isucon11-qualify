require "sidekiq"
# require_relative "../workers/payment_cancel_worker"

sidekiq_redis_url = "redis://#{ENV["REDIS_HOST"]}:6379/0"

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_redis_url }
end
