# frozen_string_literal: true

# Обеспечивает наличие триггеров auto_deduct и auto_stop_list в тестовой БД.
# Делегирует в DatabaseTriggers.ensure_all! (TASK_93-G R3-B).
module TestDbTriggers
  class << self
    def ensure!
      DatabaseTriggers.ensure_all!
    end
  end
end
