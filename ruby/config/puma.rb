# ref. https://github.com/puma/puma/blob/master/lib/puma/dsl.rb

environment "production"

port '3000', '0.0.0.0'

if `hostname`.strip == "isucon11-qualify-01"
  threads 0, 32
  workers 32
else
  threads 0, 32
  workers 48
end

preload_app!

log_requests false

before_fork do
  require "puma_worker_killer"

  PumaWorkerKiller.config do |config|
    config.ram           = 4096 # mb
    config.frequency     = 5    # seconds
    config.percent_usage = 0.80
    config.rolling_restart_frequency = 12 * 3600 # 12 hours in seconds, or 12.hours if using Rails
    config.reaper_status_logs = false # setting this to false will not log lines like:
    # PumaWorkerKiller: Consuming 54.34765625 mb with master and 2 workers.

    # config.pre_term = -> (worker) { puts "Worker #{worker.inspect} being killed" }
    # config.rolling_pre_term = -> (worker) { puts "Worker #{worker.inspect} being killed by rolling restart" }
  end
  PumaWorkerKiller.start
end

# for puma 5+
# Recommended 0.001~0.010(default 0.005)
wait_for_less_busy_worker 0.005

nakayoshi_fork true
