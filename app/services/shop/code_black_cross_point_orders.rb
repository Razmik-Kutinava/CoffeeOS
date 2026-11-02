# frozen_string_literal: true

module Shop
  # TASK_116: история и чек заказов клиента по точкам сети CODE:BLACK.
  # Граница доступа — фильтры customer_id + tenant_ids в запросе (без city-lookup GUC).
  # Prod: роль приложения BYPASSRLS (TASK_119 этап 1). Под тестовой ролью с FORCE RLS
  # узкий SET LOCAL row_security = off только внутри транзакции чтения с уже
  # зафиксированным списком id точек (coffeeos-core: обход с явным комментарием).
  # Relation наружу не отдаём — выборка материализуется до конца транзакции.
  class CodeBlackCrossPointOrders
    def initialize(current_tenant:, customer_id:)
      @current_tenant = current_tenant
      @customer_id = customer_id.to_s.presence
    end

    def history_orders(source: :mobile, page: 1, per_page: 20, since: nil)
      return [] if @customer_id.blank?

      page = [ page.to_i, 1 ].max
      per_page = [ [ per_page.to_i, 1 ].max, 50 ].min

      with_code_black_read do
        scope = base_scope(source: source).order(created_at: :desc)
        scope = scope.where("orders.created_at >= ?", since) if since
        scope
          .includes(:order_items, :tenant)
          .limit(per_page)
          .offset((page - 1) * per_page)
          .to_a
      end
    end

    # Для unit-тестов: материализованный список без пагинации (новые сверху).
    def history_scope(source: :mobile)
      return [] if @customer_id.blank?

      with_code_black_read do
        base_scope(source: source).order(created_at: :desc).includes(:tenant).to_a
      end
    end

    def find_order!(order_id, source: :mobile)
      raise ActiveRecord::RecordNotFound if @customer_id.blank?

      with_code_black_read do
        base_scope(source: source)
          .includes(:order_items, :fiscal_receipts, :payments, :tenant)
          .find(order_id)
      end
    end

    def tenant_json(tenant)
      {
        id: tenant.id,
        name: tenant.name,
        display_address: TenantAddress.display(city: tenant.city, address: tenant.address),
        closed: tenant.status.to_s != "active"
      }
    end

    private

    def base_scope(source:)
      Order.where(
        tenant_id: tenant_ids_for_history,
        customer_id: @customer_id,
        source: source
      )
    end

    def tenant_ids_for_history
      if network_member_current?
        Tenant.code_black_network.pluck(:id)
      else
        [ @current_tenant.id ]
      end
    end

    def network_member_current?
      @current_tenant.code_black_member == true && @current_tenant.type.to_s == "sales_point"
    end

    # RLS bypass only for this filtered read path — see class comment.
    def with_code_black_read
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL row_security = off")
        yield
      end
    end
  end
end
