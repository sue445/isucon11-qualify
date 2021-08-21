# ref. https://github.com/puma/puma/blob/master/lib/puma/dsl.rb

environment "development"

port '8000', '0.0.0.0'

preload_app!

log_requests true

# for puma 5+
# Recommended 0.001~0.010(default 0.005)
wait_for_less_busy_worker 0.005

nakayoshi_fork true
