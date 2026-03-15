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
      raise "Current.tenant_id not set for #{self.class.name}"
    end
  end
  
  def with_postgres_context
    conn = ActiveRecord::Base.connection
    
    # Сохранить старые значения
    old_tenant = conn.execute("SHOW app.current_tenant_id").first['app.current_tenant_id'] rescue nil
    old_user = conn.execute("SHOW app.current_user_id").first['app.current_user_id'] rescue nil
    
    begin
      # Установить новые
      if Current.tenant_id
        conn.execute("SET LOCAL app.current_tenant_id = '#{Current.tenant_id}'")
      end
      if Current.user_id
        conn.execute("SET LOCAL app.current_user_id = '#{Current.user_id}'")
      end
      
      yield
    ensure
      # Восстановить
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
    end
  end
end
