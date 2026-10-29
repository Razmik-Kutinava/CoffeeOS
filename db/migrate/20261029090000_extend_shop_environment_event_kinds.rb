# frozen_string_literal: true

# TASK_110: события воронки согласия на push пишутся в shop_environment_events (TASK_112)
# со своим event_kind — расширяем белый список CHECK. Колонки и view не меняются.
# Откат: ограничение снова только session_open, без проверки старых строк (validate: false) —
# записанные события воронки не удаляются.
class ExtendShopEnvironmentEventKinds < ActiveRecord::Migration[8.0]
  NAME = "chk_shop_environment_events_event_kind"
  KINDS = %w[
    session_open
    push_preprompt_shown push_preprompt_accept push_preprompt_later
    push_permission_granted push_permission_denied push_permission_default
  ].freeze

  def up
    remove_check_constraint :shop_environment_events, name: NAME
    add_check_constraint :shop_environment_events, expression(KINDS), name: NAME
  end

  def down
    remove_check_constraint :shop_environment_events, name: NAME
    add_check_constraint :shop_environment_events, expression(%w[session_open]), name: NAME, validate: false
  end

  private

  def expression(kinds)
    "event_kind::text = ANY (ARRAY[#{kinds.map { |k| "'#{k}'::text" }.join(', ')}])"
  end
end
