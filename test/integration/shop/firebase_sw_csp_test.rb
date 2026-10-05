# frozen_string_literal: true

require "test_helper"

# TASK_37 Патч 1: SW `/firebase-messaging-sw.js` делает importScripts с www.gstatic.com —
# CSP этого ответа должна его разрешать, глобальная CSP не расширяется.
class Shop::FirebaseSwCspTest < ActionDispatch::IntegrationTest
  GSTATIC = "https://www.gstatic.com"

  def csp_directive(header, name)
    rule = header.to_s.split(";").map(&:strip).find { |d| d.start_with?("#{name} ") }
    rule.to_s.split(" ").drop(1)
  end

  test "SW response CSP allows www.gstatic.com in script-src" do
    get "/firebase-messaging-sw.js"

    assert_response :success
    script_src = csp_directive(response.headers["Content-Security-Policy"], "script-src")
    assert_includes script_src, GSTATIC
    assert_includes script_src, "'self'"
  end

  test "SW response CSP keeps global script-src sources and does not widen connect-src" do
    get "/firebase-messaging-sw.js"

    header = response.headers["Content-Security-Policy"]
    global = Rails.application.config.content_security_policy.directives

    assert_equal global["script-src"] + [ GSTATIC ], csp_directive(header, "script-src")
    assert_equal global["connect-src"], csp_directive(header, "connect-src")
  end

  test "global CSP is not widened for Firebase" do
    script_src = Rails.application.config.content_security_policy.directives["script-src"]

    refute_includes script_src, GSTATIC
    refute(script_src.any? { |s| s.include?("gstatic") || s.include?("google") || s == "*" })
  end
end
