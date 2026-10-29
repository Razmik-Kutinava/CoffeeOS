# frozen_string_literal: true

# TASK_111: события воронки установки на главный экран пишутся в shop_environment_events (TASK_112)
# со своим event_kind — расширяем белый список CHECK. Колонки и view не меняются.
# Откат: ограничение снова как после TASK_110 (7 видов), без проверки старых строк (validate: false) —
# записанные события установки не удаляются.
class ExtendShopEnvironmentEventKindsInstall < ActiveRecord::Migration[8.0]
  NAME = "chk_shop_environment_events_event_kind"
  PREVIOUS_KINDS = %w[
    session_open
    push_preprompt_shown push_preprompt_accept push_preprompt_later
    push_permission_granted push_permission_denied push_permission_default
  ].freeze
  KINDS = (PREVIOUS_KINDS + %w[
    install_banner_shown install_banner_tap install_banner_dismiss pwa_first_launch
  ]).freeze

  def up
    remove_check_constraint :shop_environment_events, name: NAME
    add_check_constraint :shop_environment_events, expression(KINDS), name: NAME
  end

  def down
    remove_check_constraint :shop_environment_events, name: NAME
    add_check_constraint :shop_environment_events, expression(PREVIOUS_KINDS), name: NAME, validate: false
  end

  private

  def expression(kinds)
    "event_kind::text = ANY (ARRAY[#{kinds.map { |k| "'#{k}'::text" }.join(', ')}])"
  end
end
