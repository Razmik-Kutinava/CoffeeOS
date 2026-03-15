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
    
    # Сохранить старые значения
    old_tenant = begin
      result = conn.execute("SHOW app.current_tenant_id")
      result.first&.dig('app.current_tenant_id')
    rescue PG::InFailedSqlTransaction
      return yield
    rescue
      nil
    end
    
    old_user = begin
      result = conn.execute("SHOW app.current_user_id")
      result.first&.dig('app.current_user_id')
    rescue PG::InFailedSqlTransaction
      return yield
    rescue
      nil
    end
    
    begin
      # Установить новые значения
      if Current.tenant_id
        conn.execute("SET LOCAL app.current_tenant_id = '#{Current.tenant_id}'")
      end
      if Current.user_id
        conn.execute("SET LOCAL app.current_user_id = '#{Current.user_id}'")
      end
      
      yield
    rescue PG::InFailedSqlTransaction, ActiveRecord::StatementInvalid => e
      # Если транзакция провалилась, пробрасываем ошибку дальше
      raise e
    ensure
      # Восстановить только если транзакция еще активна и не провалилась
      begin
        return unless conn.transaction_open?
        
        # Проверяем состояние транзакции перед восстановлением
        conn.execute("SELECT 1")
        
        if old_tenant.present?
          conn.execute("SET LOCAL app.current_tenant_id = '#{old_tenant}'")
        else
          conn.execute("RESET app.current_tenant_id")
        end
        
        if old_user.present?
          conn.execute("SET LOCAL app.current_user_id = '#{old_user}'")
        else
          conn.execute("RESET app.current_user_id")
        end
      rescue PG::InFailedSqlTransaction, ActiveRecord::StatementInvalid
        # Игнорируем ошибки при восстановлении в провалившейся транзакции
      rescue
        # Игнорируем другие ошибки при восстановлении
      end
    end
  end
end
