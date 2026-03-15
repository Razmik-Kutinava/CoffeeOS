# Конфигурация Solid Queue
# Solid Queue настраивается через config/queue.yml
# Retry стратегия настраивается в каждом job через retry_on/discard_on
# Пример:
# class MyJob < ApplicationJob
#   retry_on StandardError, wait: :exponentially_longer, attempts: 5
#   discard_on ActiveRecord::RecordNotFound
# end
