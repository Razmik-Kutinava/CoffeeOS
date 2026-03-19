class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Автоматически устанавливаем tenant_id для новых записей
  before_create :set_tenant_id, if: :tenant_id_column?
  before_create :ensure_tenant_id, if: :tenant_id_column?
  
  # Автоматически устанавливаем Postgres context для RLS
  around_save :with_postgres_context, if: :tenant_id_column?

  private

  def tenant_id_column?
    respond_to?(:tenant_id)
  end

  def set_tenant_id
    self.tenant_id = Current.tenant_id if Current.tenant_id && !tenant_id.present?
  end
  
  def ensure_tenant_id
    if tenant_id.blank?
      # В development/test режиме не выбрасываем исключение, только логируем
      if Rails.env.development? || Rails.env.test?
        Rails.logger.warn "Current.tenant_id not set for #{self.class.name}, but tenant_id is blank"
      else
        raise "Current.tenant_id not set for #{self.class.name}"
      end
    end
  end
  
  def with_postgres_context
    conn = ActiveRecord::Base.connection
    
    # Пропускаем если нет активной транзакции
    return yield unless conn.transaction_open?
    
    # Проверяем, не провалилась ли транзакция
    begin
      # Пробуем выполнить простую команду для проверки состояния транзакции
      conn.execute("SELECT 1")
    rescue PG::InFailedSqlTransaction
      # Транзакция провалилась, пропускаем установку контекста
      return yield
    end
    
    begin
      # Установить новые значения
      if Current.tenant_id
        begin
          conn.execute("SET LOCAL app.current_tenant_id = '#{Current.tenant_id}'")
        rescue ActiveRecord::StatementInvalid => e
          # Dev/test may run without custom GUCs/RLS bootstrap. Don't break writes.
          raise e unless e.message.include?("unrecognized configuration parameter")
        end
      end
      if Current.user_id
        begin
          conn.execute("SET LOCAL app.current_user_id = '#{Current.user_id}'")
        rescue ActiveRecord::StatementInvalid => e
          raise e unless e.message.include?("unrecognized configuration parameter")
        end
      end
      
      yield
    rescue PG::InFailedSqlTransaction, ActiveRecord::StatementInvalid => e
      # If transaction failed or context isn't supported, let the error propagate
      # unless it's the optional custom GUC missing.
      if e.is_a?(ActiveRecord::StatementInvalid) && e.message.include?("unrecognized configuration parameter")
        yield
      else
        raise e
      end
    ensure
      # No-op: SET LOCAL is scoped to the current transaction and will be reset automatically.
    end
  end
end
